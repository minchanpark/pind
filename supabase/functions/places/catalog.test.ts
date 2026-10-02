import test from 'node:test';
import assert from 'node:assert/strict';
import { catalogRequest } from './catalog.ts';
import { explicitGoogleAction, dailyLimit } from '../google-places/policy.ts';

test('nearby requires posts while restaurant search keeps unposted choices',async()=>{
  const query=async()=>({places:[{internalId:1,pindPostCount:0},{internalId:2,pindPostCount:1},{internalId:3}]});
  const map=await catalogRequest({action:'nearby',latitude:37.57,longitude:126.98,radiusMeters:1000},query,async ps=>ps,true);
  assert.deepEqual((map.places as Record<string,unknown>[]).map(p=>p.internalId),[2]);
  const all=await catalogRequest({action:'posted'},async args=>{assert.deepEqual(args,{});return query();},async ps=>ps,true);
  assert.deepEqual((all.places as Record<string,unknown>[]).map(p=>p.internalId),[2]);
  const search=await catalogRequest({action:'search',query:'카페'},query,async ps=>ps,true);
  assert.equal((search.places as unknown[]).length,3);
});
test('private media resolves a signed URL and strips internal storage fields',async()=>{
  const calls:unknown[]=[];
  const result=await catalogRequest({action:'catalog_detail',internalPlaceId:1},async()=>({places:[{
    internalId:1,pindPostCount:1,pindPhotoPath:'owner/photo.png',pindPhotoBucket:'post-media-v2',pindPhotoAuthor:'Pind',
  }]}),async(paths,bucket)=>{calls.push([paths[0],bucket]);return ['https://storage/signed/photo'];},true);
  assert.deepEqual(calls,[['owner/photo.png','post-media-v2']]);
  const place=result.place as Record<string,unknown>;
  assert.equal(place.heroImageUrl,'https://storage/signed/photo');
  assert.equal(place.pindPhotoBucket,undefined);assert.equal(place.pindPhotoPath,undefined);
});
test('catalog empty and errors never turn into paid lookup',async()=>{
  let calls=0;
  const query=async()=>{calls++;return {places:[],catalogReady:false};};
  const result=await catalogRequest({action:'search',query:'서울'},query,async ps=>ps,true);
  assert.equal(calls,1);assert.deepEqual(result.places,[]);assert.equal(result.googleSearchEnabled,true);
  await assert.rejects(()=>catalogRequest({action:'search',query:'서울'},async()=>{throw Error('offline');},async ps=>ps,true));
});
test('catalog Pind photo wins and source preserved',async()=>{
  const result=await catalogRequest({action:'catalog_detail',internalPlaceId:1},async()=>({places:[{
    provider:'sbiz',internalId:1,heroImageUrl:'https://pind/photo',pindPhotoPath:'other.png',pindPostCount:2,
  }]}),async ps=>ps.map(p=>'https://storage/'+p),true);
  const p=result.place as Record<string,unknown>;
  assert.equal(p.heroImageUrl,'https://pind/photo');assert.equal(p.provider,'sbiz');assert.equal(p.internalId,1);
  assert.equal(p.pindPhotoPath,undefined);
});
test('invalid viewport/action rejected before DB',async()=>{
  for(const body of [{action:'nearby',latitude:NaN,longitude:127,radiusMeters:5000},{action:'google_search',query:'서울'}]) {
    await assert.rejects(()=>catalogRequest(body,async()=>{throw Error('should not query');},async ps=>ps,true),/기본|대한민국/);
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

test('detail posts sign every photo, gallery takes five, stale insight refreshes once',async()=>{
  const refreshed:number[]=[];
  const detail=(insight:unknown)=>catalogRequest({action:'catalog_detail',internalPlaceId:7},async()=>({places:[{
    internalId:7,pindPostCount:2,insight,pindPosts:[
      {id:2,author:'민찬',handle:'minchan',avatar:null,body:'맛있어요',ratings:{taste:5},bucket:'post-media-v2',photos:['a','b','gone','d','e'],likeCount:3,liked:true,mine:true},
      {id:1,author:'하람',avatar:'https://a/p.png',body:'',ratings:{},bucket:'post-media',photos:['f','g','h']},
    ],
  }]}),async paths=>paths.map(path=>path==='gone'?null:`https://signed/${path}`),true,id=>refreshed.push(id));
  const place=(await detail({summary:'',criteria:{},postCount:0})).place as Record<string,unknown>;
  const posts=place.posts as Record<string,unknown>[];
  assert.deepEqual(posts[0],{id:2,author:'민찬',handle:'minchan',avatar:null,body:'맛있어요',ratings:{taste:5},
    photos:['https://signed/a','https://signed/b','https://signed/d','https://signed/e'],likeCount:3,liked:true,mine:true});
  assert.deepEqual([posts[1].likeCount,posts[1].liked,posts[1].mine],[0,false,false]);
  assert.deepEqual((place.gallery as {uri:string}[]).map(g=>g.uri),
    ['https://signed/a','https://signed/b','https://signed/d','https://signed/e','https://signed/f']);
  assert.equal(place.pindPosts,undefined);assert.equal(place.insight,undefined);
  assert.deepEqual(refreshed,[7]);
  const fresh=(await detail({summary:'소개',criteria:{taste:'맛있어요'},postCount:2})).place as Record<string,unknown>;
  assert.deepEqual(fresh.insight,{summary:'소개',criteria:{taste:'맛있어요'}});
  assert.deepEqual(refreshed,[7]);
});

test('the whole response signs once per bucket',async()=>{
  const calls:[string,string[]][]=[];
  await catalogRequest({action:'catalog_detail',internalPlaceId:7},async()=>({places:[{
    internalId:7,pindPostCount:3,pindPhotoPath:'a',pindPhotoBucket:'post-media-v2',pindPosts:[
      {id:3,bucket:'post-media-v2',photos:['a','b']},
      {id:2,bucket:'post-media-v2',photos:['c']},
      {id:1,bucket:'post-media',photos:['old']},
    ],
  }]}),async(paths,bucket)=>{calls.push([bucket,paths]);return paths.map(p=>`https://s/${p}`);},true);
  assert.deepEqual(calls.sort(),[['post-media',['old']],['post-media-v2',['a','b','c']]]);
});

test('agent search runs its own RPC with the plan and explains it',async()=>{
  const calls:[unknown,unknown][]=[];
  const result=await catalogRequest({action:'agent_search',terms:['혼술','포차'],area:'성수동',label:'혼술 · 포차',latitude:37.54,longitude:127.05},
    async(args,fn)=>{calls.push([fn,args]);return {places:[{internalId:1,pindPostCount:0},{internalId:2,pindPostCount:3}]};},async ps=>ps,true);
  assert.deepEqual(calls,[['agent_search_places',{p_terms:['혼술','포차'],p_lat:37.54,p_lng:127.05}]]);
  // A geocoded area arrives as a center and radius.
  calls.length=0;
  await catalogRequest({action:'agent_search',terms:['카페'],label:'성수동 · 카페',latitude:37.5407,longitude:127.0566,radiusMeters:1600},
    async(args,fn)=>{calls.push([fn,args]);return {places:[]};},async ps=>ps,true);
  assert.deepEqual(calls,[['agent_search_places',{p_terms:['카페'],p_lat:37.5407,p_lng:127.0566,p_radius:1600}]]);
  // The kind of place travels apart from the ranking words.
  calls.length=0;
  await catalogRequest({action:'agent_search',kinds:['치킨','통닭'],terms:['사진'],label:'치킨'},
    async(args,fn)=>{calls.push([fn,args]);return {places:[]};},async ps=>ps,true);
  assert.deepEqual(calls,[['agent_search_places',{p_terms:['사진'],p_lat:null,p_lng:null,p_kinds:['치킨','통닭']}]]);
  // Kinds alone are enough.
  await catalogRequest({action:'agent_search',kinds:['카페'],terms:[],label:'카페'},async()=>({places:[]}),async ps=>ps,true);
  assert.deepEqual((result.places as Record<string,unknown>[]).map(p=>p.internalId),[1,2]); // unposted kept
  assert.equal(result.notice,'혼술 · 포차 기준으로 찾았어요.');
  await assert.rejects(()=>catalogRequest({action:'agent_search',terms:[]},async()=>({}),async ps=>ps,true),/이해하지/);
  const far=await catalogRequest({action:'agent_search',terms:['바'],label:'바',latitude:10,longitude:10},
    async(args)=>{assert.deepEqual([args.p_lat,args.p_lng],[null,null]);return {places:[]};},async ps=>ps,true);
  assert.deepEqual(far.places,[]);
});
