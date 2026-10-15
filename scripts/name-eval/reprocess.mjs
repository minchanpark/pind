#!/usr/bin/env node
// Correct deterministic processing bugs without regenerating model outputs.
import {readFileSync,writeFileSync,mkdirSync,copyFileSync} from 'node:fs';
import path from 'node:path';
import {buildHybridName,HYBRID_POLICY} from './hybrid.mjs';
import {aggregate,checkedItems,matchesReference} from './benchmark.mjs';

const previous=process.argv[2];
if(!previous||process.argv.length!==3) throw new Error('Usage: node scripts/name-eval/reprocess.mjs <completed run directory>');
const fixture=JSON.parse(readFileSync(path.join(previous,'fixture.json'),'utf8'));
const cases=fixture.cases;
const out=path.join(previous,'corrected-processing-v1.1');
mkdirSync(out,{recursive:true});
copyFileSync(path.join(previous,'fixture.json'),path.join(out,'fixture.json'));
const reports=[];
for(const method of ['baseline','hybrid']) for(const trial of [1,2,3]) for(const batch of [1,2,3,4]){
  const name=`${method}-trial-${trial}-batch-${batch}.json`;
  const report=JSON.parse(readFileSync(path.join(previous,name),'utf8'));
  if(method==='hybrid'){
    const chunk=cases.slice((batch-1)*25,batch*25);
    const data=JSON.parse(readFileSync(path.join(previous,name.replace('.json','.response.json')),'utf8'));
    const items=checkedItems(data,chunk.map(c=>c.ko));
    report.results=chunk.map((c,i)=>{
      let answer,error;
      try{answer=buildHybridName(items[i],c.ko);}catch(e){error=e.message;}
      return {id:c.id,ko:c.ko,group:c.group,ambiguous_source:c.ambiguous_source,en:answer?.en??null,
        parts:answer?.parts,accepted:c.en,error,ok:matchesReference(c,answer?.en)};
    });
    report.passed=report.results.filter(r=>r.ok).length;
    report.policy=HYBRID_POLICY;
  }
  reports.push(report);
  writeFileSync(path.join(out,name),JSON.stringify(report,null,2)+'\n');
}
const original=JSON.parse(readFileSync(path.join(previous,'summary.json'),'utf8'));
const summary={...original,methods:aggregate(cases,reports),reprocessed_at:new Date().toISOString(),
  original_run:path.resolve(previous),additional_model_calls:0,
  corrections:['Allow literal whitespace parts','Apply pre-existing loanword mappings to misclassified romanize chunks'],
  post_generation_processing_corrected:true};
writeFileSync(path.join(out,'summary.json'),JSON.stringify(summary,null,2)+'\n');
for(const [method,m] of Object.entries(summary.methods)) console.log(`${method}: trials ${m.trial_passed.join(',')}; best of 3 ${m.best_of_three}/100; majority ${m.majority_correct}/100; invalid ${m.invalid_responses}`);
console.log(`Saved ${out}`);
