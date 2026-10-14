/* SPDX-License-Identifier: GPL-2.0-or-later
 * Original vector artwork inspired by the user's reference photograph.
 * A cabinet changes presentation only; every cabinet runs the same P1.
 */
(function () {
    'use strict';
    const designs = Object.freeze([
        {id: 0, name: 'Purple / pink', body: '#7942a6', light: '#a46fc4', dark: '#4b2578', bezel: '#ee80ae', button: '#f496bd'},
        {id: 1, name: 'Blue / yellow', body: '#136bbb', light: '#54a8df', dark: '#064279', bezel: '#f5d575', button: '#f6de8a', translucent: true},
        {id: 2, name: 'Pink / yellow', body: '#ed3985', light: '#fa83ba', dark: '#ae1457', bezel: '#f4dc73', button: '#f7df70'},
        {id: 3, name: 'White / black', body: '#efefec', light: '#ffffff', dark: '#bac0c4', bezel: '#373d45', button: '#343843'},
        {id: 4, name: 'Blue / silver', body: '#1661a7', light: '#539be0', dark: '#084076', bezel: '#d7dde2', button: '#e8edf0', stars: true},
        {id: 5, name: 'Rainbow', body: '#ec72ac', light: '#ffe0d9', dark: '#3b75a7', bezel: '#f5cc68', button: '#fff4db', rainbow: true},
        {id: 6, name: 'Red glitter', body: '#b91d3c', light: '#e85f6c', dark: '#701225', bezel: '#e8c792', button: '#ecd4ad', glitter: true},
        {id: 7, name: 'Mermaid', body: '#58b9bf', light: '#b4e6e2', dark: '#5b83b0', bezel: '#b9e7de', button: '#f182bf', mermaid: true}
    ]);
    const body = 'M140 35C91 35 49 76 29 130C11 179 19 250 51 289C73 318 105 328 140 328C175 328 207 318 229 289C261 250 269 179 251 130C231 76 189 35 140 35Z';
    const rim = 'M140 43C96 43 56 83 37 133C21 180 27 246 58 284C79 310 109 320 140 320C171 320 201 310 222 284C253 246 259 180 243 133C224 83 184 43 140 43Z';
    const bezel = 'M60 117L79 121L94 113L111 119L128 112L146 119L164 112L182 119L201 113L220 119L215 137L224 153L217 170L225 187L217 205L223 224L216 245L198 242L181 250L162 243L144 250L124 243L106 250L88 243L69 248L58 238L62 220L55 202L62 184L55 166L63 148L56 131Z';

    function resolve(id) {
        return designs.find(design => design.id === id) || designs[0];
    }

    function artwork(id) {
        const d = resolve(id), p = 'tama-shell-' + d.id + '-';
        let decoration = '';
        if (d.translucent) decoration += '<path d="M60 89Q140 45 220 89L237 246Q140 288 43 246Z" fill="none" stroke="#b8eaff" stroke-width="2" opacity=".2"/><path d="M60 271H220M42 107H238" stroke="#083b69" stroke-width="3" opacity=".13"/>';
        if (d.stars || d.rainbow) {
            [[62,94],[210,86],[40,206],[234,233],[85,304],[196,298]].forEach(([x,y], i) => {
                decoration += '<path d="M' + x + ' ' + (y-6) + 'l2 4 5 2-5 2-2 5-2-5-5-2 5-2Z" fill="' + (d.rainbow ? ['#fff9d5','#ffe89a','#ffffff'][i%3] : '#e6edf2') + '" opacity=".85"/>';
            });
        }
        if (d.glitter) {
            for (let i = 0; i < 180; i++) {
                const x = 23 + (i * 79 % 234), y = 40 + (i * 101 % 280);
                decoration += '<circle cx="' + x + '" cy="' + y + '" r="' + (i%4 ? '.7' : '1.3') + '" fill="' + (i%3 ? '#ffd7b4' : '#ffecdf') + '" opacity="' + (i%2 ? '.5' : '.8') + '"/>';
            }
        }
        if (d.mermaid) decoration += '<path d="' + body + '" fill="url(#' + p + 'scales)" opacity=".5"/>';
        const buttons = [107,140,173].map((x) => '<g class="tama-decorative-button"><ellipse cx="' + x + '" cy="279" rx="10" ry="10" fill="' + d.dark + '" opacity=".75"/><circle cx="' + x + '" cy="276" r="8.8" fill="' + d.button + '" stroke="' + d.dark + '" stroke-width="1.1"/><ellipse cx="' + (x-2) + '" cy="273" rx="3.6" ry="2" fill="#fff" opacity=".46"/></g>').join('');
        return '<svg class="tama-cabinet-art" viewBox="0 0 280 350" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">' +
            '<defs><linearGradient id="' + p + 'plastic" x1="0" y1="0" x2="1" y2="1"><stop stop-color="' + d.light + '"/><stop offset=".4" stop-color="' + d.body + '"/><stop offset="1" stop-color="' + d.dark + '"/></linearGradient>' +
            '<linearGradient id="' + p + 'rainbow" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#64bfec"/><stop offset=".24" stop-color="#7588df"/><stop offset=".46" stop-color="#bb7dd6"/><stop offset=".66" stop-color="#f384bc"/><stop offset=".84" stop-color="#f4b57d"/><stop offset="1" stop-color="#f7dc82"/></linearGradient>' +
            '<linearGradient id="' + p + 'mermaid" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#c6bfed"/><stop offset=".3" stop-color="#9ddeea"/><stop offset=".6" stop-color="#6dccbe"/><stop offset="1" stop-color="#de9cce"/></linearGradient>' +
            '<linearGradient id="' + p + 'metal"><stop stop-color="#7c858e"/><stop offset=".25" stop-color="#f5f6f7"/><stop offset=".5" stop-color="#9ea7ae"/><stop offset=".75" stop-color="#fff"/><stop offset="1" stop-color="#6a737d"/></linearGradient>' +
            '<linearGradient id="' + p + 'shine" x1="0" y1="0" x2=".5" y2="1"><stop stop-color="#fff" stop-opacity=".48"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>' +
            '<pattern id="' + p + 'scales" width="24" height="18" patternUnits="userSpaceOnUse"><path d="M-12 0Q0 18 12 0M12 0Q24 18 36 0M0 9Q12 27 24 9" fill="none" stroke="#fff" stroke-width="1.1"/></pattern>' +
            '<clipPath id="' + p + 'clip"><path d="' + body + '"/></clipPath></defs>' +
            '<g stroke="url(#' + p + 'metal)" fill="none" stroke-width="3.5"><ellipse cx="140" cy="11" rx="13" ry="13"/><ellipse cx="140" cy="29" rx="6" ry="10"/></g>' +
            '<path d="' + body + '" transform="translate(0 3)" fill="#1e2330" opacity=".15"/>' +
            '<path d="' + body + '" fill="url(#' + p + (d.rainbow ? 'rainbow' : d.mermaid ? 'mermaid' : 'plastic') + ')" stroke="' + d.dark + '" stroke-width="2.5"/>' +
            '<g clip-path="url(#' + p + 'clip)">' + decoration + '</g>' +
            '<path d="' + rim + '" fill="none" stroke="#fff" stroke-opacity=".27" stroke-width="1.3"/>' +
            '<path d="M49 129C67 76 101 45 138 44C95 69 77 107 67 160C61 180 47 175 49 129Z" fill="url(#' + p + 'shine)"/>' +
            '<ellipse cx="140" cy="42" rx="7" ry="4" fill="' + d.dark + '"/><ellipse cx="140" cy="40" rx="4" ry="3" fill="url(#' + p + 'metal)"/>' +
            '<text x="140" y="99" text-anchor="middle" fill="' + d.bezel + '" font-family="Segoe Print, Comic Sans MS, cursive" font-size="23" font-style="italic" font-weight="bold" transform="rotate(-5 140 94)">Tamagotchi</text>' +
            '<path d="' + bezel + '" fill="' + d.dark + '" opacity=".5" transform="translate(0 2)"/>' +
            '<path d="' + bezel + '" fill="' + d.bezel + '" stroke="' + d.dark + '" stroke-width="1"/>' +
            '<rect x="66" y="128" width="148" height="114" rx="2" fill="#606b53"/>' +
            '<rect x="69" y="131" width="142" height="108" rx="1" fill="#bac39b"/>' + buttons +
            '<path d="M69 297Q140 334 211 297" fill="none" stroke="' + d.dark + '" stroke-width="1.2" opacity=".35"/></svg>';
    }

    // Miniature LCD-style pictograms; native P1 memory still controls their state.
    const iconPaths = [
        '<path d="M3 12h14l-2 5H5Z"/><path d="M7 10V4h3v6m3 0V3h3v7" fill="none" stroke="currentColor" stroke-width="2"/>',
        '<path d="M6 15V9a4 4 0 1 1 8 0v6Zm1 2h6v2H7Z"/><path d="M10 0v3M1 9h3m12 0h3M3 2l2 3m12-3-2 3" stroke="currentColor"/>',
        '<path d="M4 5h12l3 11h-5l-2-3H8l-2 3H1Z"/><path d="M6 7v5M4 9.5h4" stroke="#bac39b" stroke-width="1.5"/><circle cx="14" cy="9" r="1" fill="#bac39b"/>',
        '<path d="M7 2h6v5h5v6h-5v5H7v-5H2V7h5Z"/>',
        '<path d="M4 3h3v8h11v3H7l-1 4H2l2-6Zm5 0h8v6H9Z"/>',
        '<path d="M3 2h14v16H3Z" fill="none" stroke="currentColor" stroke-width="2"/><path d="M6 6h8M6 10h8M6 14h5" stroke="currentColor" stroke-width="2"/>',
        '<path d="M5 9V3h3v6h1V1h3v8h1V3h3v7l2-2 2 3-5 7H7l-5-6Z"/>',
        '<path d="M5 13V8a5 5 0 0 1 10 0v5l3 2H2Zm3 4h4l-2 3Z"/>'
    ];
    function icon(index) {
        return '<svg viewBox="0 0 20 20" aria-hidden="true" focusable="false">' + iconPaths[index] + '</svg>';
    }
    window.TamaShells = Object.freeze({designs, resolve, artwork, icon});
}());
