/* In-memory layout/language QA. Test data, no tenant, original firmware or server. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require(process.env.ERP_PLAYWRIGHT||'playwright');
const source=path.resolve(__dirname,'..'),output=process.argv[2];
if(!output)throw new Error('Provide a new QA output directory');fs.mkdirSync(output,{recursive:false});
const css=fs.readFileSync(path.join(source,'controladdin/tama.css'),'utf8');
const scripts=['shells.js','tama.js'].map(n=>fs.readFileSync(path.join(source,'controladdin',n),'utf8')).join('\n');
const al=fs.readFileSync(path.join(source,'src/TamaUI.Codeunit.al'),'utf8');
const guide=fs.readFileSync(path.join(source,'src/TamaGuidance.Codeunit.al'),'utf8');
const da=JSON.parse(fs.readFileSync(path.join(source,'Translations/da-DK.json'),'utf8'));
const labels=new Map([...al.matchAll(/(\w+): Label '((?:[^']|'')*)'/g)].map(m=>[m[1],m[2].replaceAll("''","'")]));
const guideLabels=new Map([...guide.matchAll(/(\w+): Label '((?:[^']|'')*)'/g)].map(m=>[m[1],m[2].replaceAll("''","'")]));
function ui(language){return Object.fromEntries([...al.matchAll(/Texts.Add\('([^']+)', (\w+)\)/g)].map(m=>[m[1],language==='da'?da[labels.get(m[2])]:labels.get(m[2])]));}
function phrase(key,language,...params){let value=guideLabels.get(key);if(language==='da')value=da[value];params.forEach((p,i)=>value=value.replaceAll('%'+(i+1),p));return value;}
function fixture(language,id=0){return {pixels:Array(512).fill(false),icons:[true,false,false,true,true,false,true,true],generation:1,revision:1,
 company:'Demo Company',sound:true,shellDesign:id,lagSeconds:0,hunger:0,happy:1,poop:4,weight:30,frequency:0,lastCare:'',language:language==='da'?1030:1033,ui:ui(language),
 advice:[{text:phrase('FoodEmptyLbl',language,phrase('PaymentLbl',language)),level:3},{text:phrase('HappyLowLbl',language,phrase('CreditLbl',language)),level:3},
 {text:phrase('CleanEmptyLbl',language,phrase('ApplyLbl',language)),level:3},{text:phrase('MedicineUrgentLbl',language,phrase('SalesReleaseLbl',language),2),level:3},
 {text:phrase('DisciplineLbl',language,phrase('PurchReleaseLbl',language)),level:2},{text:phrase('NoJobLbl',language),level:1}],
 receipt:phrase('ReceiptLbl',language,12,8,4,0)+' '+phrase('LastLbl',language,'Sales invoice posted','Meal',language==='da'?'Madmåleren er allerede fuld.':'Food is already full.')};}
(async()=>{const browser=await chromium.launch({headless:true});const errors=[],checks=[];
try{const page=await browser.newPage({locale:'da-DK'});page.on('pageerror',e=>errors.push(String(e)));await page.route('**/*',r=>{errors.push(r.request().url());return r.abort()});
 for(const width of [260,360])for(const language of ['en','da']){
  await page.setViewportSize({width,height:680});await page.setContent('<!doctype html><meta charset="utf-8"><style>'+css+'</style><div id="controlAddIn"></div><script>window.Microsoft={Dynamics:{NAV:{InvokeExtensibilityMethod(){}}}};</script><script>'+scripts+'</script><script>TamaUI.mount();</script>');
  for(let id=0;id<8;id++){
   await page.evaluate(f=>SetFrame(JSON.stringify(f)),fixture(language,id));
   const box=await page.evaluate(()=>({width:document.documentElement.scrollWidth,height:document.querySelector('.tama').getBoundingClientRect().height,advice:document.querySelectorAll('.tama-advice p').length,receipt:document.querySelector('.tama-receipt').textContent}));
   assert.ok(box.width<=width,JSON.stringify(box));assert.ok(box.height<=680,JSON.stringify(box));assert.equal(box.advice,6);checks.push({width,language,id,...box});
  }
  await page.screenshot({path:path.join(output,language+'-'+width+'.png')});
 }
 assert.deepEqual(errors,[]);fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify({checks,errors,tenant_tested:false,frame:'generated adversarial layout fixture; AL label texts'},null,2)+'\n');console.log(JSON.stringify({checks:checks.length,errors}));
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
