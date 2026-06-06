'use strict';

const state = {
    visible:   false,
    slots:     [],
    granted:   false,   // initiator was granted permission for locked slots
    hasLocked: false,
    reqData:   null,    // active permission request (target side)
    rightDown: false,
    orbitDX:   0,
    orbitDY:   0,
};

function getResourceName() {
    return typeof window.GetParentResourceName === 'function'
        ? window.GetParentResourceName()
        : 'noted_removeclothes';
}

function fetchNui(event, data) {
    return fetch(`https://${getResourceName()}/${event}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data ?? {}),
    });
}

function canRemove(slot) {
    return slot.has && (slot.free || state.granted);
}

// ── Incoming messages ─────────────────────────────────────────────────────────

window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'open':            openMenu(d);                  break;
        case 'close':           closeMenu();                  break;
        case 'updatePositions': updatePositions(d.positions); break;
        case 'slotRemoved':     markSlotRemoved(d.id);        break;
        case 'grantAll':        grantAll();                   break;
        case 'showRequest':     showRequest(d);               break;
        case 'hideRequest':     hideRequest();                break;
    }
});

// ── Menu ──────────────────────────────────────────────────────────────────────

function openMenu(data) {
    state.visible   = true;
    state.slots     = data.slots ?? [];
    state.granted   = false;
    state.hasLocked = !!data.hasLocked;

    document.getElementById('app').classList.remove('hidden');
    buildSlotList();
    buildWorldLabels();
    updateRequestButton();
}

function closeMenu() {
    state.visible = false;
    document.getElementById('app').classList.add('hidden');
    document.getElementById('lines-svg').innerHTML = '';
    document.getElementById('world-labels').innerHTML = '';
    fetchNui('close');
}

function updateRequestButton() {
    const btn = document.getElementById('request-btn');
    if (!state.granted && state.hasLocked) btn.classList.remove('hidden');
    else btn.classList.add('hidden');
}

function requestPermission() {
    const btn = document.getElementById('request-btn');
    btn.textContent = 'Waiting…';
    btn.classList.add('pending');
    fetchNui('requestPermission');
}

function grantAll() {
    state.granted = true;
    for (const slot of state.slots) refreshSlot(slot.id);
    // newly-removable items now get an on-body label
    buildWorldLabels();
    const btn = document.getElementById('request-btn');
    btn.classList.add('hidden');
    btn.classList.remove('pending');
    btn.textContent = 'Request permission';
}

// ── Slot list ─────────────────────────────────────────────────────────────────

function buildSlotList() {
    const list = document.getElementById('slot-list');
    list.innerHTML = '';
    for (const slot of state.slots) list.appendChild(makeSlotItem(slot));
}

function makeSlotItem(slot) {
    const el      = document.createElement('div');
    el.id         = `si-${slot.id}`;
    el.dataset.id = slot.id;

    const dot   = document.createElement('div');
    const label = document.createElement('span');
    label.className   = 'slot-label';
    label.textContent = slot.label;

    el.appendChild(dot);
    el.appendChild(label);
    applySlotAppearance(el, dot, slot);
    return el;
}

function applySlotAppearance(el, dot, slot) {
    el.className  = 'slot-item';
    dot.className = 'slot-dot';
    el.onclick    = null;

    if (!slot.has) {
        dot.classList.add('dot-none');
        return;
    }
    if (slot.removed) {
        el.classList.add('removed');
        dot.classList.add('dot-removed');
        return;
    }
    if (canRemove(slot)) {
        el.classList.add('removable');
        dot.classList.add('dot-free');
        el.onclick = () => fetchNui('removeSlot', { id: slot.id });
    } else {
        el.classList.add('locked');
        dot.classList.add('dot-locked');
    }
}

function refreshSlot(id) {
    const slot = state.slots.find(s => s.id === id);
    if (!slot) return;
    const el  = document.getElementById(`si-${id}`);
    const dot = el?.querySelector('.slot-dot');
    if (el && dot) applySlotAppearance(el, dot, slot);
}

function markSlotRemoved(id) {
    const slot = state.slots.find(s => s.id === id);
    if (slot) slot.removed = true;
    refreshSlot(id);
    // delete the on-body label outright so nothing hangs as a ghost
    const lbl = document.querySelector(`.world-label[data-slot="${id}"]`);
    if (lbl) lbl.remove();
}

// ── World labels + SVG lines ──────────────────────────────────────────────────

function buildWorldLabels() {
    const container = document.getElementById('world-labels');
    container.innerHTML = '';
    for (const slot of state.slots) {
        // only show on-body labels for items we can actually remove
        if (!slot.has || slot.removed || !canRemove(slot)) continue;
        const lbl = document.createElement('div');
        lbl.className    = 'world-label removable hidden';
        lbl.dataset.slot = slot.id;
        lbl.textContent  = slot.label;
        lbl.onclick      = () => fetchNui('removeSlot', { id: slot.id });
        container.appendChild(lbl);
    }
}

const LABEL_OFFSETS = {
    hat:        { dx: -0.08, dy: -0.10 },
    glasses:    { dx:  0.10, dy: -0.07 },
    earpiece:   { dx:  0.10, dy: -0.04 },
    watch:      { dx:  0.12, dy:  0.02 },
    bracelet:   { dx: -0.12, dy:  0.02 },
    mask:       { dx: -0.10, dy: -0.06 },
    hair:       { dx:  0.09, dy: -0.11 },
    top:        { dx: -0.13, dy: -0.02 },
    undershirt: { dx:  0.13, dy:  0.01 },
    armor:      { dx: -0.13, dy:  0.04 },
    neck:       { dx:  0.11, dy: -0.03 },
    bag:        { dx:  0.13, dy:  0.03 },
    gloves:     { dx: -0.12, dy:  0.06 },
    decals:     { dx:  0.12, dy:  0.07 },
    pants:      { dx: -0.10, dy:  0.09 },
    shoes:      { dx:  0.10, dy:  0.13 },
};

function updatePositions(positions) {
    if (!state.visible || !positions) return;
    const svg = document.getElementById('lines-svg');
    svg.innerHTML = '';

    const W = window.innerWidth;
    const H = window.innerHeight;

    for (const slot of state.slots) {
        if (!slot.has || slot.removed) continue;
        const pos = positions[slot.id];
        if (!pos || !pos.visible) continue;

        const lbl = document.querySelector(`.world-label[data-slot="${slot.id}"]`);
        if (!lbl) continue;

        const bx  = pos.x * W;
        const by  = pos.y * H;
        const off = LABEL_OFFSETS[slot.id] ?? { dx: 0.1, dy: 0 };
        const lx  = bx + off.dx * W;
        const ly  = by + off.dy * H;

        lbl.style.left = lx + 'px';
        lbl.style.top  = ly + 'px';
        lbl.classList.remove('hidden');

        const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', bx); line.setAttribute('y1', by);
        line.setAttribute('x2', lx); line.setAttribute('y2', ly);
        line.setAttribute('stroke', 'rgba(91,140,255,0.45)');
        line.setAttribute('stroke-width', '1');
        line.setAttribute('stroke-dasharray', '4 4');
        svg.appendChild(line);

        const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        dot.setAttribute('cx', bx); dot.setAttribute('cy', by);
        dot.setAttribute('r', '3');
        dot.setAttribute('fill', 'rgba(91,140,255,0.7)');
        svg.appendChild(dot);
    }
}

// ── Mouse orbit + zoom ────────────────────────────────────────────────────────

document.addEventListener('contextmenu', (e) => e.preventDefault());

document.addEventListener('mousedown', (e) => {
    if (e.button === 2 && state.visible) state.rightDown = true;
});
document.addEventListener('mouseup', (e) => {
    if (e.button === 2) state.rightDown = false;
});
document.addEventListener('mousemove', (e) => {
    if (state.rightDown && state.visible) {
        state.orbitDX += e.movementX;
        state.orbitDY += e.movementY;
    }
});
document.addEventListener('wheel', (e) => {
    if (state.visible) fetchNui('zoomCamera', { delta: e.deltaY });
}, { passive: true });

function orbitLoop() {
    if (state.visible && (state.orbitDX !== 0 || state.orbitDY !== 0)) {
        fetchNui('orbitCamera', { dx: state.orbitDX, dy: state.orbitDY });
        state.orbitDX = 0;
        state.orbitDY = 0;
    }
    requestAnimationFrame(orbitLoop);
}
requestAnimationFrame(orbitLoop);

// ── Keyboard ──────────────────────────────────────────────────────────────────

document.addEventListener('keydown', (e) => {
    if (state.reqData) {
        if (e.key === 'y' || e.key === 'Y') respondPermission(true);
        if (e.key === 'n' || e.key === 'N' || e.key === 'Escape') respondPermission(false);
        return;
    }
    if (e.key === 'Escape' && state.visible) closeMenu();
});

// ── Permission request (target side) ──────────────────────────────────────────

function showRequest(data) {
    state.reqData = data;
    document.getElementById('req-text').textContent =
        `${data.initiator} wants to remove your clothing.`;
    document.getElementById('request-box').classList.remove('hidden');
}

function hideRequest() {
    state.reqData = null;
    document.getElementById('request-box').classList.add('hidden');
}

function respondPermission(accepted) {
    if (!state.reqData) return;
    hideRequest();
    // initiator id is tracked server-side on the Lua client, not passed here
    fetchNui('respondPermission', { accepted });
}
