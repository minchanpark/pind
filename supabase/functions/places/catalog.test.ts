import test from 'node:test';
import assert from 'node:assert/strict';
import { catalogRequest } from './catalog.ts';
import { explicitGoogleAction, dailyLimit } from '../google-places/policy.ts';

test('nearby requires posts while restaurant search keeps unposted choices',async()=>{
  const query=async()=>({places:[{internalId:1,pindPostCount:0},{internalId:2,pindPostCount:1},{internalId:3}]});
  const map=await catalogRequest({action:'nearby',latitude:37.57,longitude:126.98,radiusMeters:1000},query,p=>p,true);
  assert.deepEqual((map.places as Record<string,unknown>[]).map(p=>p.internalId),[2]);
  const search=await catalogRequest({action:'search',query:'카페'},query,p=>p,true);
  assert.equal((search.places as unknown[]).length,3);
});
test('private media resolves a signed URL and strips internal storage fields',async()=>{
  const calls:unknown[]=[];
  const result=await catalogRequest({action:'catalog_detail',internalPlaceId:1},async()=>({places:[{
    internalId:1,pindPostCount:1,pindPhotoPath:'owner/photo.png',pindPhotoBucket:'post-media-v2',pindPhotoAuthor:'Pind',
  }]}),async(path,bucket)=>{calls.push([path,bucket]);return 'https://storage/signed/photo';},true);
  assert.deepEqual(calls,[['owner/photo.png','post-media-v2']]);
  const place=result.place as Record<string,unknown>;
  assert.equal(place.heroImageUrl,'https://storage/signed/photo');
  assert.equal(place.pindPhotoBucket,undefined);assert.equal(place.pindPhotoPath,undefined);
});
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
