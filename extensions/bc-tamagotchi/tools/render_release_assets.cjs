/* Project-owned display previews. Generated test data; no BC tenant or web server. */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium} = require(process.env.ERP_PLAYWRIGHT || 'playwright');
const source = path.resolve(__dirname, '..');
const output = process.argv[2];
if (!output) throw new Error('Provide a new output directory');
fs.mkdirSync(output, {recursive:false});
const css = fs.readFileSync(path.join(source,'controladdin/tama.css'),'utf8');
const scripts = ['shells.js','tama.js'].map(n=>fs.readFileSync(path.join(source,'controladdin',n),'utf8')).join('\n');
const al = fs.readFileSync(path.join(source,'src/TamaDisplay.Codeunit.al'),'utf8');
const bitmap = al.match(/5: exit\('([^']+)'\)/)[1];
const pixels = Array(512).fill(false);
bitmap.split('|').forEach((row,y)=>[...row].forEach((p,x)=>{pixels[(y+1)*32+x+8]=p==='#'}));
const uiAL = fs.readFileSync(path.join(source,'src/TamaUI.Codeunit.al'),'utf8');
const labels = new Map([...uiAL.matchAll(/(\w+): Label '((?:[^']|'')*)'/g)].map(m=>[m[1],m[2].replaceAll("''","'")]));
const ui = Object.fromEntries([...uiAL.matchAll(/Texts.Add\('([^']+)', (\w+)\)/g)].map(m=>[m[1],labels.get(m[2])]));
const frame = {pixels,icons:[false,false,false,false,false,false,false,false],generation:1,
    revision:1,company:'Demo Company',sound:false,shellDesign:0,lagSeconds:0,
    hunger:3,happy:4,weight:30,frequency:0,lastCare:'',ui,language:1033};
const mount = '<div id="controlAddIn"></div><script>window.Microsoft={Dynamics:{NAV:{InvokeExtensibilityMethod(){}}}};</script><script>'+scripts+'</script><script>TamaUI.mount();SetFrame('+JSON.stringify(JSON.stringify(frame))+');</script>';
function head(extra) {return '<!doctype html><html lang="en"><meta charset="utf-8"><style>'+css+extra+'</style><body>'}

(async()=>{
    const browser = await chromium.launch({headless:true});
    const errors=[];
    try {
        const page = await browser.newPage({viewport:{width:1200,height:630},deviceScaleFactor:1});
        page.on('pageerror',e=>errors.push(String(e)));
        await page.route('**/*',r=>{errors.push('Unexpected request: '+r.request().url());return r.abort()});
        await page.setContent(head('body{margin:0;background:#101d32;color:#f5f4ee;font-family:Arial,sans-serif}.hero{display:grid;grid-template-columns:1fr 360px;gap:38px;padding:44px 54px;height:630px;box-sizing:border-box}.tag{color:#90efd0;font-size:16px;letter-spacing:2px;margin:0 0 22px}.copy h1{font-size:62px;line-height:1.04;letter-spacing:-2px;margin:0 0 24px}.copy h1 span{color:#90efd0}.lead{font-size:26px;line-height:1.25;margin:0 0 25px;color:#dddfe8}.actions{font-size:19px;line-height:1.9;margin:0;color:#fafafa}.actions strong{color:#90efd0}.note{font-size:12px;color:#a4aec0;margin:24px 0 0}.display{align-self:center;background:#fffdf8;border:1px solid #dedfd8;border-radius:24px;box-shadow:0 24px 70px #0005;color:#273027;overflow:hidden;padding:10px 0 4px}.display h2{font-size:14px;text-align:center;margin:10px 0 0;color:#5b6274}.tama{background:transparent}.tama-options{display:none}.tama-company{font-size:11px}.tama-message{font-size:12px}.tama-summary{font-size:13px}')+
            '<main class="hero"><section class="copy"><p class="tag">GAMIFY YOUR ERP</p><h1>Tamagotchi<br><span>BC KPI</span></h1><p class="lead">Most KPIs turn red.<br>This one dies.</p><p class="actions"><strong>Choose BC events.</strong> Set the triggers.<br><strong>Map them to care.</strong> Food, play &amp; more.<br><strong>Work together.</strong> Keep it alive.</p><p class="note">Configurable business events · Life in AL · Shared company pet<br>Independent prerelease · Display preview with generated test data</p></section><section class="display"><h2>A KPI WITH A PULSE</h2>'+mount+'</section></main></body></html>');
        assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
        assert.equal(await page.evaluate(()=>document.documentElement.scrollHeight>innerHeight),false);
        await page.screenshot({path:path.join(output,'social-preview.png')});
        await page.setViewportSize({width:360,height:680});
        const guidedFrame = {...frame, poop:1, advice:[
            {text:'A little hungry. Post a sales invoice.',level:1},
            {text:'Happiness is full. Keep it that way: Post a customer payment.',level:0},
            {text:'A small mess needs cleaning. Apply customer entries with Apply Entries.',level:1}
        ], receipt:'Care attempts received: 12 · accepted: 8 · refused: 4 · pending: 0'};
        const guidedMount = mount.replace(JSON.stringify(JSON.stringify(frame)), JSON.stringify(JSON.stringify(guidedFrame)));
        await page.setContent(head('body{margin:0;background:#fffdf8}')+guidedMount+'</body></html>');
        await page.screenshot({path:path.join(output,'pet-preview.png')});
        await page.setViewportSize({width:1200,height:900});
        await page.setContent(head('body{margin:0;background:#f6f3ed;color:#26312d;font-family:Arial,sans-serif;padding:26px 36px;box-sizing:border-box}h1{font-size:28px;margin:0 0 8px}.subtitle{font-size:14px;color:#667268;margin:0 0 20px}.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}.card{background:#fffdf8;border:1px solid #e6e0d5;border-radius:16px;overflow:hidden;text-align:center}iframe{width:100%;height:295px;border:0;display:block}h2{font-size:14px;margin:0 0 12px}.foot{font-size:12px;color:#667268;margin-top:20px}')+
            '<h1>Eight cabinets. One company pet.</h1><p class="subtitle">Tamagotchi BC KPI · choose the cabinet in Setup · decorative buttons</p><div class="grid"></div><p class="foot">Own vector cabinets and AL pixel artwork. Display previews use generated test data; no BC tenant or original firmware is shown.</p></body></html>');
        const galleryCSS = css+'.tama-company,.tama-summary,.tama-message,.tama-options{display:none}.tama{padding:0;background:transparent}';
        for (let id=0;id<8;id++) {
            const markup = '<!doctype html><meta charset="utf-8"><style>'+galleryCSS+'</style>'+mount.replace(JSON.stringify(JSON.stringify(frame)),JSON.stringify(JSON.stringify({...frame,shellDesign:id})));
            await page.evaluate(({markup,name})=>{
                const card=document.createElement('section');card.className='card';
                const iframe=document.createElement('iframe');iframe.srcdoc=markup;iframe.title=name;
                const title=document.createElement('h2');title.textContent=name;
                card.append(iframe,title);document.querySelector('.grid').append(card);
            },{markup,name:ui['shell'+id]});
        }
        await page.waitForFunction(()=>[...document.querySelectorAll('iframe')].every(f=>f.contentDocument?.querySelector('.tama-cabinet')));
        assert.equal(await page.evaluate(()=>document.documentElement.scrollHeight>innerHeight),false);
        await page.screenshot({path:path.join(output,'cabinets.png')});
        assert.deepEqual(errors,[]);
        fs.writeFileSync(path.join(output,'asset-provenance.json'),JSON.stringify({
            generator:'extensions/bc-tamagotchi/tools/render_release_assets.cjs',
            data:'generated test frame; project AL character 5 bitmap',
            display:'current project control add-in and SVG cabinet source',
            files:['social-preview.png','pet-preview.png','cabinets.png'],
            bc_tenant_capture:false,original_firmware_or_photograph:false,network_requests:0,errors
        },null,2)+'\n');
        console.log(JSON.stringify({files:3,errors,output}));
    } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
