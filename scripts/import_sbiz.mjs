import { createReadStream, readFileSync } from 'node:fs';
import { spawn, spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

// Streaming RFC 4180 parser: UTF-8/BOM, quoted commas, CRLF and multiline fields.
export async function* csvRows(stream) {
  const decoder = new TextDecoder('utf-8', { fatal: true });
  let field = '', row = [], quoted = false, pendingQuote = false, closed = false;
  function* consume(text) {
    for (const c of text) {
      if (quoted && pendingQuote) {
        if (c === '"') { field += c; pendingQuote = false; continue; }
        quoted = false; pendingQuote = false; closed = true;
      }
      if (quoted) { if (c === '"') pendingQuote = true; else field += c; continue; }
      if (c === ',') { row.push(field); field = ''; closed = false; }
      else if (c === '\n') { row.push(field); yield row; row = []; field = ''; closed = false; }
      else if (c === '\r') { /* CRLF */ }
      else if (c === '"' && field === '' && !closed) quoted = true;
      else if (closed || c === '"') throw new Error('Invalid CSV quoting');
      else field += c;
    }
  }
  for await (const chunk of stream) yield* consume(decoder.decode(chunk,{stream:true}));
  yield* consume(decoder.decode());
  if (quoted && !pendingQuote) throw new Error('Unterminated CSV field');
  if (field || row.length || pendingQuote) { row.push(field); yield row; }
}

export function normalizeSbiz(record, region, city) {
  if (region && record['시도명'] !== region) return null;
  const district = record['시군구명'];
  if (city && district !== city && !district?.startsWith(`${city} `)) return null;
  if (record['상권업종대분류코드'] !== 'I2') return null;
  const id = record['상가업소번호']?.trim(), base = record['상호명']?.trim();
  const branch = record['지점명']?.trim();
  const name = base && branch && !base.includes(branch) ? `${base} ${branch}` : base;
  const category = record['상권업종소분류명']?.trim();
  const address = record['도로명주소']?.trim() || record['지번주소']?.trim();
  const latitude = Number(record['위도']), longitude = Number(record['경도']);
  if (!id || id.length > 100 || !name || name.length > 200 || !category || !address ||
      address.length > 500 || !Number.isFinite(latitude) || !Number.isFinite(longitude) ||
      latitude < 33 || latitude > 38.8 || longitude < 124.5 || longitude > 132) {
    throw new Error(`Invalid food place: ${id ?? '(missing ID)'}`);
  }
  return {id,name,category,address,latitude,longitude};
}

function input(options) {
  if (options.zip) {
    if (!options.entry) throw new Error('--zip requires --entry (e.g. 서울)');
    // Python only decodes ZIP filenames and streams the unmodified member; no extraction paths.
    const child = spawn('python3',['-c',
      'import zipfile,sys,shutil; z=zipfile.ZipFile(sys.argv[1]); names=[n for n in z.namelist() if n.endswith(".csv") and ("_"+sys.argv[2]+"_") in n]; assert len(names)==1,"Expected exactly one CSV member"; shutil.copyfileobj(z.open(names[0]),sys.stdout.buffer)',
      options.zip,options.entry],{stdio:['ignore','pipe','inherit']});
    return {stream:child.stdout,done:new Promise((resolve,reject)=>child.on('close',code=>code===0?resolve():reject(new Error('ZIP read failed'))))};
  }
  if (!options.file) throw new Error('--file or --zip is required');
  return {stream:createReadStream(options.file),done:Promise.resolve()};
}

export function batchSql(rows,date) {
  const escaped = JSON.stringify(rows).replaceAll("'","''");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error('Invalid source date');
  return `select public.import_sbiz_places('${escaped}'::jsonb,'${date}'::date) as updated;`;
}

async function scan(options, batch) {
  const source = input(options), ids = new Set();
  let headers, read = 0, selected = 0, rows = [];
  for await (const cells of csvRows(source.stream)) {
    if (!headers) {
      headers = cells.map(c=>c.replace(/^\uFEFF/,'').trim());
      for (const name of ['상가업소번호','상호명','상권업종대분류코드','상권업종소분류명','도로명주소','경도','위도',...(options.city ? ['시도명','시군구명'] : [])]) {
        if (!headers.includes(name)) throw new Error(`Missing CSV column: ${name}`);
      }
      continue;
    }
    if (cells.length === 1 && cells[0] === '') continue;
    if (cells.length !== headers.length) throw new Error(`Column count differs at row ${read+2}`);
    read++;
    const place = normalizeSbiz(Object.fromEntries(headers.map((h,i)=>[h,cells[i]])),options.region,options.city);
    if (!place) continue;
    if (ids.has(place.id)) throw new Error(`Duplicate source ID: ${place.id}`);
    ids.add(place.id); selected++; rows.push(place);
    if (rows.length === 1000) { await batch(rows); rows = []; }
  }
  await source.done;
  if (rows.length) await batch(rows);
  if (!selected) throw new Error('No matching food places; nothing imported');
  return {read,selected};
}

async function main() {
  const options = {};
  for (let i=2;i<process.argv.length;i++) {
    const key=process.argv[i];
    if (key==='--apply') options.apply=true;
    else if (['--file','--zip','--entry','--region','--city','--date','--project-ref','--local-container'].includes(key)) {
      options[key.slice(2)] = process.argv[++i];
    } else throw new Error(`Unknown argument: ${key}`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(options.date ?? '')) throw new Error('--date YYYY-MM-DD is required');
  if (options.city && !options.region) throw new Error('--city requires --region');
  if (options.apply && !options['local-container']) {
    const linked=readFileSync('supabase/.temp/project-ref','utf8').trim();
    if (!options['project-ref'] || options['project-ref'] !== linked) throw new Error('Explicit --project-ref must match linked project');
  }
  // Validate the complete input before any remote writes, including duplicate IDs.
  const totals=await scan(options,async()=>{});
  console.log(JSON.stringify({validated:totals,sourceDate:options.date,apply:!!options.apply}));
  if (!options.apply) return;
  let updated=0;
  await scan(options,async rows=>{
    const sql=batchSql(rows,options.date);
    const local=options['local-container'];
    const command=local?'docker':'npx';
    const args=local?['exec','-i',local,'psql','-U','postgres','-d','pind_public_first_test','-v','ON_ERROR_STOP=1','-At']:
      ['-y','supabase@2.118.0','db','query','--linked','--file','/dev/stdin','--output','json'];
    const result=spawnSync(command,args,{input:sql,encoding:'utf8',maxBuffer:1024*1024});
    if (result.status!==0) throw new Error(result.stderr || 'Import failed; safe to rerun');
    const count=local?Number(result.stdout.trim()):Number(JSON.parse(result.stdout).rows[0].updated);
    if (!Number.isFinite(count)) throw new Error('Unexpected import result');
    updated+=count;
    console.log(JSON.stringify({updated,total:totals.selected}));
  });
}
if (process.argv[1] && import.meta.url===pathToFileURL(process.argv[1]).href) {
  main().catch(error=>{console.error(error.message);process.exitCode=1;});
}
