const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const base=fs.existsSync(__dirname+'/dist/data.js')?__dirname+'/dist':__dirname;
const dummy={addEventListener(){}};
const c=vm.createContext({console,Date,Number,String,JSON,Math,Set,Array,Object,RegExp,Error,localStorage:{getItem:()=>null,setItem(){}},document:{querySelector:()=>dummy,querySelectorAll:()=>[],addEventListener(){}},window:{addEventListener(){}},setInterval(){},setTimeout(){},clearTimeout(){}});
vm.runInContext(fs.readFileSync(base+'/data.js','utf8'),c);
let source=fs.readFileSync(base+'/app.js','utf8').replace(/renderAll\(\);selectTab\('plan'\);\s*$/, '');
vm.runInContext(source,c);
const run=s=>vm.runInContext(s,c);
assert.equal(run("Object.keys(EXERCISES).length"),12);
assert.equal(run("DAYS.length"),7);
assert.equal(run("plusDays('2026-10-31',1)"),'2026-11-01');
assert.equal(run("validDate('2026-02-30')"),false);
assert.equal(run("validDate('2026-10-25')"),true);
run("const sample={app:'together-training',version:1,logs:{a:{person:'Tyler',date:'2026-10-25',day:0,updatedAt:'2026-10-25T12:00:00Z',minutes:'30',effort:'4',complete:true,notes:'<script>alert(1)</script>',sets:{}}}};");
assert.equal(run("Object.values(cleanImport(sample))[0].minutes"),'30');
assert.equal(run("Object.values(cleanImport(sample))[0].complete"),true);
assert.throws(()=>run("cleanImport({...sample,version:2})"));
assert.throws(()=>run("cleanImport({...sample,logs:{a:{...sample.logs.a,person:'Someone else'}}})"));
assert.throws(()=>run("cleanImport({...sample,logs:{a:{...sample.logs.a,minutes:'-1'}}})"));
assert.throws(()=>run("cleanImport({...sample,logs:{a:{...sample.logs.a,date:'2026-02-30'}}})"));
assert.equal(run("esc('<script>')"),'&lt;script&gt;');
assert.equal(run("csvCell('=1+1')"),'"\'=1+1"');
assert.equal(run("intervalPhases().reduce((n,p)=>n+p.seconds,0)"),1320);
assert.equal(run("sketch('rdl',.5).includes('NaN')"),false);
for(const id of run('Object.keys(EXERCISES)')){
 assert.equal(run(`sketch('${id}',0).includes('NaN')`),false);
 assert.equal(run(`sketch('${id}',1).includes('NaN')`),false);
}
console.log('Passed: plan, dates, backup validation, escaping, CSV formula protection, interval duration, and all 12 movement sketches.');
