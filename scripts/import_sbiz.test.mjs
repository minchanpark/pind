import test from 'node:test';
import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { csvRows, normalizeSbiz, batchSql } from './import_sbiz.mjs';

test('CSV BOM, quoted commas/newlines/quotes survive one-byte chunks',async()=>{
  const text='\uFEFF"이름","주소"\r\n"카페, A","첫줄\n둘째 ""줄"""\r\n';
  const bytes=Buffer.from(text);
  const result=[];
  for await(const row of csvRows(Readable.from([...bytes].map(b=>Buffer.from([b]))))) result.push(row);
  assert.deepEqual(result,[['이름','주소'],['카페, A','첫줄\n둘째 "줄"']]);
});
test('malformed quote and invalid UTF8 rejected',async()=>{
  for(const raw of [Buffer.from('a\n"not closed'),Buffer.from([0xff])]) {
    await assert.rejects(async()=>{for await(const _ of csvRows(Readable.from([raw]))) { /* exhaust */ }});
  }
});
test('food only, region filtering, branch name and location validation',()=>{
  const row={'상가업소번호':'A1','상호명':'카페','지점명':'서울점','상권업종대분류코드':'I2',
    '상권업종소분류명':'카페','도로명주소':'서울 종로구','시도명':'서울특별시','시군구명':'종로구','위도':'37.57','경도':'126.98'};
  assert.equal(normalizeSbiz(row,'서울특별시').name,'카페 서울점');
  assert.equal(normalizeSbiz({...row,'상권업종대분류코드':'G2'}),null);
  assert.equal(normalizeSbiz(row,'부산광역시'),null);
  const pohang={...row,'시도명':'경상북도','시군구명':'포항시 남구'};
  assert.equal(normalizeSbiz(pohang,'경상북도','포항시')?.name,'카페 서울점');
  assert.equal(normalizeSbiz({...pohang,'시군구명':'포항시 북구'},'경상북도','포항시')?.name,'카페 서울점');
  assert.equal(normalizeSbiz({...pohang,'시군구명':'경주시'},'경상북도','포항시'),null);
  assert.equal(normalizeSbiz(pohang,'서울특별시','포항시'),null);
  assert.throws(()=>normalizeSbiz({...row,'위도':''}));
});
test('SQL input quotes escaped, never interpolated unescaped',()=>{
  assert.ok(batchSql([{name:"O'Brien"}],'2026-06-30').includes("O''Brien"));
  assert.throws(()=>batchSql([],"2026-06-30');drop table places;--"));
});
