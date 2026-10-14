/* Synthetic control-addin contract tests; no browser server, firmware or BC tenant. */
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

function harness() {
    const calls = [], timers = [], rectangles = [];
    const nodes = new Map();
    function element() {
        return {
            textContent: '', hidden: false, dataset: {}, children: [], attributes: {}, listeners: {},
            classList: {toggle() {}},
            append(n) { this.children.push(n); },
            replaceChildren() { this.children = []; },
            setAttribute(k,v) { this.attributes[k]=v; },
            addEventListener(k,v) { this.listeners[k]=v; },
            getContext() { return {fillStyle: '', fillRect(...args) { rectangles.push(args); }}; },
            querySelector(selector) { if (!nodes.has(selector)) nodes.set(selector,element()); return nodes.get(selector); },
            querySelectorAll() { return [...this.querySelector('.top').children,...this.querySelector('.bottom').children]; }
        };
    }
    const host = element(), documentListeners = {};
    const document = {
        hidden: false,
        getElementById(id) { return id==='controlAddIn' ? host : null; },
        createElement: element,
        addEventListener(k,v) { documentListeners[k]=v; }
    };
    const window = {
        navigator: {language: 'da-DK'}, // browser preference must not override BC
        Microsoft: {Dynamics: {NAV: {InvokeExtensibilityMethod(...args) {calls.push(args);}}}},
        addEventListener() {}
    };
    const context = vm.createContext({window,document,setTimeout(fn,ms) {timers.push({fn,ms});return timers.length;},clearTimeout() {}, console});
    vm.runInContext(fs.readFileSync(path.join(__dirname,'../controladdin/shells.js'),'utf8'),context);
    vm.runInContext(fs.readFileSync(path.join(__dirname,'../controladdin/tama.js'),'utf8'),context);
    window.TamaUI.mount();
    return {window,document,nodes,calls,timers,rectangles,documentListeners,host};
}

function frame(revision=1, generation=1) {
    return {revision,generation,pixels:Array(512).fill(false),icons:Array(8).fill(false),company:'Testfirma',
        sound:false,lagSeconds:0,hunger:2,happy:3,weight:7,frequency:0,busy:false,lastCare:'Test',shellDesign:0};
}

test('mount requests the AL frame; no care event is sent',()=>{
    const h=harness();assert.equal(h.calls[0][0],'Ready');assert.equal(h.calls[0][1].length,0);
    assert.equal(h.host.children.length,1);
    h.nodes.get('.setup').listeners.click();assert.equal(h.calls[1][0],'OpenSetup');
});
test('renders the native 512 pixels and schedules one update',()=>{
    const h=harness(), f=frame();f.pixels[33]=true;
    h.window.SetFrame(JSON.stringify(f));
    assert.deepEqual(h.rectangles.at(-1),[1,1,1,1]);
    assert.equal(h.timers.at(-1).ms,1000);
    h.timers.at(-1).fn();assert.equal(h.calls.at(-1)[0],'Tick');
});
test('older frames cannot overwrite a newer generation',()=>{
    const h=harness();h.window.SetFrame(JSON.stringify(frame(7,2)));
    h.window.SetFrame(JSON.stringify(frame(100,1)));
    assert.match(h.nodes.get('.tama-company').textContent,/egg 2/);
});
test('company text is plain text, never inserted as HTML',()=>{
    const h=harness(),f=frame();f.company='<img src=x onerror=alert(1)>';
    h.window.SetFrame(JSON.stringify(f));
    assert.equal(h.nodes.get('.tama-company').textContent,'<img src=x onerror=alert(1)> · egg 1');
});
test('malformed payload does not grant care or crash the widget',()=>{
    const h=harness();h.window.SetFrame('broken');
    assert.match(h.nodes.get('.tama-message').textContent,/could not/);
    assert.equal(h.calls.length,1);
    h.window.SetFrame(JSON.stringify({...frame(),pixels:[]}));
    assert.equal(h.calls.length,1);
});
test('failed AL request is retried without simulating a pet locally',()=>{
    const h=harness();h.calls[0][4]();
    assert.equal(h.timers.at(-1).ms,5000);h.timers.at(-1).fn();
    assert.equal(h.calls.at(-1)[0],'Tick');
});
test('hidden rolecenter does not start a background polling job',()=>{
    const h=harness();h.document.hidden=true;h.window.SetFrame(JSON.stringify(frame()));
    assert.equal(h.timers.length,0);
    h.document.hidden=false;h.documentListeners.visibilitychange();
    assert.equal(h.timers.at(-1).ms,100);
});

test('all eight cabinets keep the live LCD and generation when appearance changes',()=>{
    const h=harness(), canvas=h.nodes.get('canvas');
    for (let id=0;id<8;id++) {
        const f=frame(id+1,4);f.shellDesign=id;f.pixels[33]=true;
        h.window.SetFrame(JSON.stringify(f));
        assert.equal(h.nodes.get('canvas'),canvas);
        assert.equal(h.nodes.get('.tama-cabinet').dataset.shell,String(id));
        assert.match(h.nodes.get('.tama-company').textContent,/egg 4/);
        const svg=h.nodes.get('.tama-cabinet-image').innerHTML;
        assert.match(svg,/<svg /);
        assert.equal((svg.match(/class="tama-decorative-button"/g)||[]).length,3);
        assert.doesNotMatch(svg,/<button|onclick|tabindex|<image|<script|<foreignObject|href=/);
        assert.equal(h.calls.length,1);
        assert.deepEqual(h.rectangles.at(-1),[1,1,1,1]);
    }
});

function uiTexts(language) {
    const al=fs.readFileSync(path.join(__dirname,'../src/TamaUI.Codeunit.al'),'utf8');
    const mapping=JSON.parse(fs.readFileSync(path.join(__dirname,'../Translations/da-DK.json'),'utf8'));
    const labels=new Map([...al.matchAll(/(\w+): Label '((?:[^']|'')*)'/g)].map(m=>[m[1],m[2].replaceAll("''", "'")]));
    return Object.fromEntries([...al.matchAll(/Texts.Add\('([^']+)', (\w+)\)/g)].map(m=>{
        const source=labels.get(m[2]);assert.ok(source);
        const text=language==='da-DK'?mapping[source]:source;assert.ok(text);
        return [m[1],text];
    }));
}

test('English BC labels win over a Danish browser preference',()=>{
    const h=harness(),f=frame();f.ui=uiTexts('en-GB');f.language=2057;f.lastCare='';f.sound=true;
    h.window.SetFrame(JSON.stringify(f));
    assert.equal(h.nodes.get('.setup').textContent,'Setup');
    assert.equal(h.nodes.get('.sound').textContent,'Enable sound');
    assert.match(h.nodes.get('.tama-summary').textContent,/Food 2\/4.*Happiness 3\/4.*Weight 7 oz/);
    assert.equal(h.nodes.get('.tama-message').textContent,'Care for the pet by working in BC.');
    assert.match(h.nodes.get('.tama-cabinet').attributes['aria-label'],/^Cabinet: Purple \/ pink\./);
    assert.equal(h.nodes.get('.top').children[0].title,'Food');
});

test('switching the BC session language preserves the canvas, cabinet and egg',()=>{
    const h=harness(),canvas=h.nodes.get('canvas'),f=frame(7,4);
    f.ui=uiTexts('da-DK');f.language=1030;f.shellDesign=7;f.lastCare='';
    h.window.SetFrame(JSON.stringify(f));
    assert.equal(h.nodes.get('.setup').textContent,'Opsætning');
    assert.match(h.nodes.get('.tama-cabinet').attributes['aria-label'],/Havfrue/);
    assert.equal(h.nodes.get('.top').children[0].title,'Mad');
    f.ui=uiTexts('en-US');f.language=1033;f.revision++;
    h.window.SetFrame(JSON.stringify(f));
    assert.equal(h.nodes.get('.setup').textContent,'Setup');
    assert.match(h.nodes.get('.tama-cabinet').attributes['aria-label'],/Mermaid/);
    assert.equal(h.nodes.get('canvas'),canvas);
    assert.match(h.nodes.get('.tama-company').textContent,/egg 4/);
    assert.equal(h.nodes.get('.tama-cabinet').dataset.shell,'7');
});

test('language is applied to pre-ROM messages and request-failure feedback',()=>{
    const h=harness();
    h.window.SetFrame(JSON.stringify({message:'Indlæs originalprogrammet.',language:1030,ui:uiTexts('da-DK'),shellDesign:0}));
    assert.equal(h.nodes.get('.setup').textContent,'Opsætning');
    h.calls[0][4]();assert.equal(h.nodes.get('.tama-message').textContent,'Tamagotchi kunne ikke opdateres.');
    h.window.SetFrame(JSON.stringify({message:'Import the original program.',language:2057,ui:uiTexts('en-GB'),shellDesign:0}));
    h.nodes.get('.setup').listeners.click();h.calls.at(-1)[4]();
    assert.equal(h.nodes.get('.tama-message').textContent,'Setup could not be opened.');
});

test('translated labels remain plain text and incomplete resources fall back to English',()=>{
    const h=harness(),f=frame();f.ui={setup:'<img src=x onerror=alert(1)>',meal:null};f.lastCare='';
    h.window.SetFrame(JSON.stringify(f));
    assert.equal(h.nodes.get('.setup').textContent,'<img src=x onerror=alert(1)>');
    assert.match(h.nodes.get('.tama-summary').textContent,/Food/);
    assert.equal(h.nodes.get('.sound').textContent,'Enable sound');
});

test('cabinet selection works before ROM import, with safe fallback for unsupported values',()=>{
    const h=harness();h.window.SetFrame(JSON.stringify({message:'Indlæs originalprogrammet.',shellDesign:7}));
    assert.equal(h.nodes.get('.tama-cabinet').dataset.shell,'7');
    assert.equal(h.nodes.get('.tama-message').textContent,'Indlæs originalprogrammet.');
    for (const id of [null,999,'<script>alert(1)</script>','7',{}]) {
        h.window.SetFrame(JSON.stringify({message:'Test',shellDesign:id}));
        assert.equal(h.nodes.get('.tama-cabinet').dataset.shell,'0');
        assert.doesNotMatch(h.nodes.get('.tama-cabinet-image').innerHTML,/<script/);
    }
});

test('renders AL care advice and event receipts as plain text, including severity',()=>{
    const h=harness(),f=frame();
    f.advice=[{text:'I AM STARVING! Post a customer payment.',level:3},{text:'<img src=x onerror=alert(1)>',level:2}];
    f.receipt='Care attempts received: 2 · accepted: 1';
    h.window.SetFrame(JSON.stringify(f));
    const advice=h.nodes.get('.tama-advice');
    assert.equal(advice.children.length,2);
    assert.equal(advice.children[0].dataset.level,'3');
    assert.equal(advice.children[1].textContent,'<img src=x onerror=alert(1)>');
    assert.equal(h.nodes.get('.tama-receipt').textContent,f.receipt);
    assert.equal(h.nodes.get('.tama-message').hidden,true);
    assert.equal(h.calls.length,1);
});
