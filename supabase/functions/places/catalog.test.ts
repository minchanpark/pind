import test from 'node:test';
import assert from 'node:assert/strict';
import { catalogRequest } from './catalog.ts';
import { explicitGoogleAction, dailyLimit } from '../google-places/policy.ts';
test('catalog empty and errors never turn into paid lookup',async()=>{
  let calls=0;
  const query=async()=>{calls++;return {places:[],catalogReady:false};};
  const result=await catalogRequest({action:'search',query:'서울'},query,p=>p,true);
  assert.equal(calls,1);assert.deepEqual(result.places,[]);assert.equal(result.googleSearchEnabled,true);
  await assert.rejects(()=>catalogRequest({action:'search',query:'서울'},async()=>{throw Error('offline');},p=>p,true));
});
test('catalog Pind photo wins and source preserved',async()=>{
  const result=await catalogRequest({action:'catalog_detail',internalPlaceId:1},async()=>({places:[{
    provider:'sbiz',internalId:1,heroImageUrl:'https://pind/photo',pindPhotoPath:'other.png',pindPostCount:2,
  }]}),p=>'https://storage/'+p,true);
  const p=result.place as Record<string,unknown>;
  assert.equal(p.heroImageUrl,'https://pind/photo');assert.equal(p.provider,'sbiz');assert.equal(p.internalId,1);
  assert.equal(p.pindPhotoPath,undefined);
});
test('invalid viewport/action rejected before DB',async()=>{
  for(const body of [{action:'nearby',latitude:NaN,longitude:127,radiusMeters:5000},{action:'google_search',query:'서울'}]) {
    await assert.rejects(()=>catalogRequest(body,async()=>{throw Error('should not query');},p=>p,true),/기본|대한민국/);
  }
});
test('legacy/batch/default Google requests denied; explicit user actions only',()=>{
  for(const action of ['nearby','search','supplemental','details']) assert.equal(explicitGoogleAction({action,userInitiated:true}),false);
  for(const action of ['google_search','resolve','detail']) {
    assert.equal(explicitGoogleAction({action}),false);
    assert.equal(explicitGoogleAction({action,userInitiated:true}),true);
  }
  assert.equal(dailyLimit(undefined,20),20);
  for(const bad of ['','NaN','Infinity','-1','1.5']) assert.equal(dailyLimit(bad,20),0);
});
