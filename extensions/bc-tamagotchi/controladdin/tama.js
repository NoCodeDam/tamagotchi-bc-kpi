/* SPDX-License-Identifier: GPL-2.0-or-later
 * Display and audio only. CPU, time, evolution and care all live in AL.
 * No raw buttons, artificial feeding, BC posting, network calls or local saves.
 */
(function () {
    'use strict';
    // English is the safe startup fallback. AL supplies translated labels from
    // the user's BC session; browser language and company setup never choose it.
    const defaults = Object.freeze({
        dead: 'The pet has died. Start a new egg in Setup when you are ready.',
        sleeping: 'The pet is sleeping.', sick: 'The pet is sick and needs medicine.',
        setup: 'Setup', enableSound: 'Enable sound', soundOn: 'Sound on',
        updateFailed: 'Tamagotchi could not be updated.', setupFailed: 'Setup could not be opened.',
        opening: "Opening the company's Tamagotchi …", active: 'active',
        shellLabel: 'Cabinet:', shellDecorative: 'The three buttons are decorative.',
        lcd: 'P1 pet LCD', egg: 'egg', meal: 'Food', happy: 'Happiness', weight: 'Weight', cleanliness: 'Cleanliness',
        catchingUp: 'Catching up on time while the Role Center was closed …',
        busy: 'The pet is being cared for …', careHint: 'Care for the pet by working in BC.',
        icon0: 'Food', icon1: 'Light', icon2: 'Play', icon3: 'Medicine', icon4: 'Cleaning',
        icon5: 'Status', icon6: 'Discipline', icon7: 'Attention',
        shell0: 'Purple / pink', shell1: 'Blue / yellow', shell2: 'Pink / yellow', shell3: 'White / black',
        shell4: 'Blue / silver', shell5: 'Rainbow', shell6: 'Red glitter', shell7: 'Mermaid'
    });
    let texts = {...defaults};
    let root, canvas, message, advice, receipt, summary, company, soundButton, cabinet, cabinetArt, timer;
    let shellDesign = -1;
    let mounted = false, waiting = false, soundAllowed = false, frame = null;
    let context = null, oscillator = null, gain = null, generation = -1, revision = -1;

    function invoke(name) {
        const nav = window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV;
        if (nav) nav.InvokeExtensibilityMethod(name, [], false, undefined, function () {
            waiting = false;
            silence();
            if (message) { message.hidden = false; message.textContent = name === 'OpenSetup' ? texts.setupFailed : texts.updateFailed; }
            queueNext(5000);
        });
    }

    function silence() {
        if (gain && context) {
            gain.gain.cancelScheduledValues(context.currentTime);
            gain.gain.setValueAtTime(0, context.currentTime);
        }
    }

    function audio(value) {
        if (!context || !soundAllowed || !frame || !frame.sound || frame.lagSeconds > 1) { silence(); return; }
        const hz = Number(value);
        if (!Number.isFinite(hz) || hz < 0 || hz > 5000) { silence(); return; }
        oscillator.frequency.cancelScheduledValues(context.currentTime);
        gain.gain.cancelScheduledValues(context.currentTime);
        const sounds = Array.isArray(frame.sounds) ? frame.sounds : [];
        const start = Number(frame.soundStartTick), now = context.currentTime;
        const windowTicks = Number(frame.ticks) - start;
        let tail = now;
        sounds.forEach(sound => {
            if (windowTicks > 65536) return; // do not replay old calls during a long catch-up
            const tick = Number(sound.tick), frequency = Number(sound.frequency);
            const offset = (tick - start) / 32768;
            if (!Number.isFinite(offset) || offset < 0 || offset > 2 || !Number.isFinite(frequency) || frequency < 0 || frequency > 5000) return;
            const at = now + offset;
            oscillator.frequency.setValueAtTime(Math.max(1, frequency), at);
            gain.gain.setValueAtTime(frequency > 0 ? 0.035 : 0, at);
            tail = Math.max(tail, at);
        });
        oscillator.frequency.setValueAtTime(Math.max(1, hz), tail);
        gain.gain.setValueAtTime(hz > 0 ? 0.035 : 0, tail);
    }

    function armSound(event) {
        if (!event.isTrusted) return;
        const Audio = window.AudioContext || window.webkitAudioContext;
        if (!Audio) return;
        if (!context) {
            context = new Audio();
            oscillator = context.createOscillator();
            gain = context.createGain();
            oscillator.type = 'square'; gain.gain.value = 0;
            oscillator.connect(gain); gain.connect(context.destination); oscillator.start();
        }
        context.resume(); soundAllowed = !soundAllowed;
        soundButton.textContent = soundAllowed ? texts.soundOn : texts.enableSound;
        audio(frame && frame.frequency);
    }

    function queueNext(delay) {
        clearTimeout(timer);
        if (!mounted || document.hidden) return;
        timer = setTimeout(function () {
            if (!mounted || waiting || document.hidden) return;
            waiting = true; invoke('Tick');
        }, delay);
    }

    function draw(value) {
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#bac39b'; ctx.fillRect(0, 0, 32, 16);
        if (Array.isArray(value.pixels) && value.pixels.length === 512) {
            ctx.fillStyle = '#283027';
            value.pixels.forEach((lit, index) => { if (lit === true) ctx.fillRect(index % 32, Math.floor(index / 32), 1, 1); });
        }
        root.querySelectorAll('[data-icon]').forEach((element, index) => {
            const active = Array.isArray(value.icons) && value.icons[index] === true;
            element.classList.toggle('active', active);
            element.title = texts['icon' + index];
            element.setAttribute('aria-label', texts['icon' + index] + (active ? ' ' + texts.active : ''));
        });
    }

    function level(value) { return Math.max(0, Math.min(4, Number(value) || 0)) + '/4'; }

    function setTexts(value) {
        texts = {...defaults};
        if (value.ui && typeof value.ui === 'object') {
            Object.keys(defaults).forEach(key => {
                if (typeof value.ui[key] === 'string' && value.ui[key].length <= 1500) texts[key] = value.ui[key];
            });
        }
        root.setAttribute('lang', value.language === 1030 ? 'da' : 'en');
        root.querySelector('.setup').textContent = texts.setup;
        soundButton.textContent = soundAllowed ? texts.soundOn : texts.enableSound;
        canvas.setAttribute('aria-label', texts.lcd);
    }

    function setCabinet(id) {
        const design = window.TamaShells.resolve(id);
        cabinet.setAttribute('aria-label', texts.shellLabel + ' ' + texts['shell' + design.id] + '. ' + texts.shellDecorative);
        if (shellDesign === design.id) return;
        shellDesign = design.id;
        // Only the fixed local artwork is inserted, never the payload itself.
        cabinetArt.innerHTML = window.TamaShells.artwork(design.id);
        cabinet.dataset.shell = String(design.id);
    }

    function setFrame(payload) {
        waiting = false;
        let value;
        try { value = JSON.parse(payload); }
        catch (_) { silence(); message.hidden = false; message.textContent = texts.updateFailed; queueNext(5000); return; }
        if (!value || typeof value !== 'object') { queueNext(5000); return; }
        setTexts(value);
        if (value.message) {
            setCabinet(value.shellDesign);
            frame = null; draw({}); silence(); company.textContent = ''; summary.textContent = '';
            advice.replaceChildren(); receipt.textContent = ''; message.hidden = false;
            message.textContent = String(value.message); queueNext(3000); return;
        }
        if (!Array.isArray(value.pixels) || value.pixels.length !== 512 || !Array.isArray(value.icons) || value.icons.length !== 8) {
            silence(); message.hidden = false; message.textContent = texts.updateFailed; queueNext(5000); return;
        }
        const nextGeneration = Number(value.generation), nextRevision = Number(value.revision);
        if (nextGeneration < generation || (nextGeneration === generation && nextRevision < revision)) { queueNext(1000); return; }
        generation = nextGeneration; revision = nextRevision; frame = value;
        setCabinet(value.shellDesign);
        draw(value);
        company.textContent = String(value.company || '') + ' · ' + texts.egg + ' ' + generation;
        summary.textContent = texts.meal + ' ' + level(value.hunger) + '   ' + texts.happy + ' ' + level(value.happy) +
            '   ' + texts.cleanliness + ' ' + level(4 - (Number(value.poop) || 0)) + '   ' + texts.weight + ' ' + (Number(value.weight) || 0) + ' oz';
        message.textContent = value.dead ? texts.dead : value.asleep ? texts.sleeping : value.sick ? texts.sick : value.lagSeconds > 1 ? texts.catchingUp :
            value.busy ? texts.busy : String(value.lastCare || texts.careHint);
        advice.replaceChildren();
        if (Array.isArray(value.advice)) value.advice.slice(0, 8).forEach(item => {
            if (!item || typeof item.text !== 'string') return;
            const line = document.createElement('p');
            line.textContent = item.text.slice(0, 1500);
            line.dataset.level = String(Math.max(0, Math.min(3, Number(item.level) || 0)));
            advice.append(line);
        });
        message.hidden = advice.children.length > 0 && !value.busy && !(value.lagSeconds > 1);
        receipt.textContent = typeof value.receipt === 'string' ? value.receipt.slice(0, 3000) : '';
        soundButton.hidden = !value.sound;
        audio(value.frequency);
        queueNext(value.lagSeconds > 1 ? 250 : 1000);
    }

    function mount() {
        clearTimeout(timer); silence(); waiting = false; generation = -1; revision = -1; texts = {...defaults};
        const host = document.getElementById('controlAddIn');
        if (!host) return;
        host.replaceChildren();
        root = document.createElement('section'); root.className = 'tama';
        root.innerHTML = '<div class="tama-company"></div><div class="tama-cabinet" role="group"><div class="tama-cabinet-image" aria-hidden="true"></div>' +
            '<div class="tama-lcd"><div class="tama-icons top"></div>' +
            '<canvas width="32" height="16" role="img" aria-label="P1 pet LCD"></canvas>' +
            '<div class="tama-icons bottom"></div></div></div><div class="tama-summary"></div><div class="tama-message" role="status"></div><div class="tama-advice"></div><div class="tama-receipt"></div>' +
            '<div class="tama-options"><button type="button" class="sound"></button><button type="button" class="setup"></button></div>';
        host.append(root);
        canvas = root.querySelector('canvas'); company = root.querySelector('.tama-company');
        summary = root.querySelector('.tama-summary'); message = root.querySelector('.tama-message');
        advice = root.querySelector('.tama-advice'); receipt = root.querySelector('.tama-receipt');
        soundButton = root.querySelector('.sound');
        cabinet = root.querySelector('.tama-cabinet'); cabinetArt = root.querySelector('.tama-cabinet-image');
        shellDesign = -1; setCabinet(0);
        setTexts({});
        [0,1,2,3,4,5,6,7].forEach(index => {
            const name = texts['icon' + index];
            const label = document.createElement('span'); label.dataset.icon = String(index);
            label.innerHTML = window.TamaShells.icon(index); label.title = name;
            label.setAttribute('role', 'img'); label.setAttribute('aria-label', name);
            root.querySelector(index < 4 ? '.top' : '.bottom').append(label);
        });
        soundButton.addEventListener('click', armSound);
        root.querySelector('.setup').addEventListener('click', () => invoke('OpenSetup'));
        mounted = true; message.textContent = texts.opening;
        draw({}); waiting = true; invoke('Ready');
    }

    document.addEventListener('visibilitychange', () => {
        if (document.hidden) { clearTimeout(timer); silence(); }
        else { waiting = false; queueNext(100); }
    });
    window.addEventListener('pagehide', () => { mounted = false; clearTimeout(timer); silence(); });
    window.SetFrame = setFrame;
    window.TamaUI = { mount };
}());
