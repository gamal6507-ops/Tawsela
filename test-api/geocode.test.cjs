const {test,beforeEach} = require('node:test');
const assert = require('node:assert/strict');
let handler;
beforeEach(() => { delete require.cache[require.resolve('../api/geocode.js')]; handler=require('../api/geocode.js'); });
function response() { return {code:0,headers:{},body:null,status(n){this.code=n;return this;},setHeader(k,v){this.headers[k]=v;},json(v){this.body=v;return this;}}; }
test('rejects POST and invalid addresses without contacting a provider',async()=>{
  let calls=0; const original=global.fetch; global.fetch=async()=>{calls++;throw Error('unexpected');};
  try { const res=response();await handler({method:'POST',query:{q:'Cairo'}},res);assert.equal(res.code,405);
    const bad=response();await handler({method:'GET',query:{q:'a'}},bad);assert.equal(bad.code,400);assert.equal(calls,0);
  }finally{global.fetch=original;}
});
test('encodes query, constrains region, caches results and limits requests',async()=>{
  const original=global.fetch;let calls=0;let seen;
  global.fetch=async(url)=>{calls++;seen=url;return {ok:true,json:async()=>({features:[{geometry:{coordinates:[31,30]}}]})};};
  try{const req={method:'GET',query:{q:'Cairo & Nile'}};const a=response();await handler(req,a);assert.equal(a.code,200);
    assert.equal(seen.searchParams.get('q'),'Cairo & Nile');assert.equal(seen.searchParams.get('bbox'),'25,22,36.9,31.7');
    const b=response();await handler(req,b);assert.equal(b.code,200);assert.equal(calls,1);
    const c=response();await handler({method:'GET',query:{q:'Alexandria'}},c);assert.equal(c.code,429);
  }finally{global.fetch=original;}
});
test('provider failures return an explicit map fallback',async()=>{
  const original=global.fetch;global.fetch=async()=>{throw Error('offline');};
  try{const res=response();await handler({method:'GET',query:{q:'Cairo'}},res);assert.equal(res.code,503);assert.match(res.body.error,/map/);}
  finally{global.fetch=original;}
});
