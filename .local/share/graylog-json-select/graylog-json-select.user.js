// ==UserScript==
// @name        Graylog JSON select
// @namespace   ersanisik.dotfiles
// @version     1.0.0
// @description Finds the JSON blocks in Graylog messages; ctrl+j selects one whole in turn, cmd+c copies all of it.
// @match       https://graylog.example.com/*
// @include     http://graylog.example.com:9000/*
// @run-at      document-idle
// @grant       none
// ==/UserScript==

// This repo is public: the real Graylog hosts are never written here, they live only
// in the Violentmonkey copy. The two hosts above deliberately match nothing.
//
// A port cannot be expressed in @match syntax (the host part accepts no port), so a
// host with a port goes in via @include -- the @include glob applies to the whole URL.

(() => {
  'use strict';

  const isHotkey = e => e.ctrlKey && !e.metaKey && !e.altKey && !e.shiftKey && e.code === 'KeyJ';

  const DEBOUNCE_MS = 300;
  // Graylog re-renders several times a second on a live tail; a plain debounce would never fire.
  const MAX_WAIT_MS = 1500;
  const MAX_CANDIDATE_LEN = 512 * 1024;
  // In plain text full of braces, hunting a closer for every opener goes O(n^2).
  const MAX_OPENERS_PER_UNIT = 200;
  const MIN_CANDIDATE_LEN = 6;

  const SKIP_TAGS = new Set(['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA', 'INPUT', 'SELECT', 'OPTION', 'SVG', 'CANVAS', 'IFRAME', 'OBJECT']);
  const INLINE_TAGS = new Set(['SPAN', 'MARK', 'EM', 'STRONG', 'B', 'I', 'U', 'S', 'A', 'CODE', 'TT', 'SMALL', 'BIG', 'FONT', 'ABBR', 'BDI', 'BDO', 'SUB', 'SUP', 'WBR', 'LABEL', 'TIME', 'VAR', 'SAMP', 'KBD']);

  let ranges = [];
  let cursor = -1;

  const highlight = typeof Highlight === 'function' && CSS.highlights ? new Highlight() : null;
  if (highlight) {
    CSS.highlights.set('graylog-json', highlight);
    const style = document.createElement('style');
    style.textContent = '::highlight(graylog-json) { background: rgba(255, 190, 60, .20); }';
    document.head.append(style);
  }

  // The buttons live in a shadow root: Graylog renders with React and reclaims any
  // element injected into its tree on the next render. A MutationObserver also cannot
  // see into a shadow tree, which is what keeps my own buttons from triggering the
  // rescan that draws them.
  const layer = document.createElement('div');
  layer.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483000';
  const shadow = layer.attachShadow({ mode: 'closed' });
  const layerStyle = document.createElement('style');
  layerStyle.textContent = `
    button {
      position: absolute; display: none; pointer-events: auto;
      width: 18px; height: 18px; padding: 0; border: 0; border-radius: 4px;
      background: rgba(255, 190, 60, .85); color: #1f1f28;
      font: 10px/18px ui-monospace, monospace; cursor: pointer;
    }
    button:hover { background: #ffbe3c; }
  `;
  shadow.append(layerStyle);
  document.body.append(layer);

  const buttons = [];
  function buttonAt(index) {
    let button = buttons[index];
    if (button) return button;
    button = document.createElement('button');
    button.type = 'button';
    button.textContent = '{}';
    button.title = 'select JSON';
    // Do not let mousedown collapse the selection or steal the focus.
    button.addEventListener('mousedown', e => e.preventDefault());
    button.addEventListener('click', e => {
      e.preventDefault();
      const range = button.range;
      if (!range) return;
      cursor = ranges.indexOf(range);
      select(range, false);
    });
    shadow.append(button);
    buttons[index] = button;
    return button;
  }

  let frame = 0;
  function reposition() {
    frame = 0;
    const height = innerHeight;
    // All rects are read first, then written: a write in between makes every read trigger a reflow.
    const rects = ranges.map(range => range.getBoundingClientRect());
    for (let i = 0; i < ranges.length; i++) {
      const rect = rects[i];
      const button = buttonAt(i);
      button.range = ranges[i];
      if (rect.bottom < 0 || rect.top > height || (!rect.width && !rect.height)) {
        button.style.display = 'none';
        continue;
      }
      button.style.display = 'block';
      button.style.left = `${Math.max(2, rect.left - 20)}px`;
      button.style.top = `${Math.max(0, Math.min(rect.top, height - 18))}px`;
    }
    for (let i = ranges.length; i < buttons.length; i++) {
      buttons[i].style.display = 'none';
      buttons[i].range = null;
    }
  }

  const schedulePosition = () => {
    if (!frame) frame = requestAnimationFrame(reposition);
  };

  function matchStrict(text, from) {
    let depth = 0;
    let inString = false;
    const limit = Math.min(text.length, from + MAX_CANDIDATE_LEN);
    for (let i = from; i < limit; i++) {
      const c = text[i];
      if (inString) {
        if (c === '\\') i++;
        else if (c === '"') inString = false;
        continue;
      }
      if (c === '"') inString = true;
      else if (c === '{' || c === '[') depth++;
      else if (c === '}' || c === ']') {
        if (--depth === 0) return i + 1;
      }
    }
    return -1;
  }

  // An escaped payload (`{\"a\":1}`) hides its quotes, and string tracking locks up there.
  function matchLoose(text, from) {
    let depth = 0;
    const limit = Math.min(text.length, from + MAX_CANDIDATE_LEN);
    for (let i = from; i < limit; i++) {
      const c = text[i];
      if (c === '{' || c === '[') depth++;
      else if (c === '}' || c === ']') {
        if (--depth === 0) return i + 1;
      }
    }
    return -1;
  }

  function parseCandidate(slice) {
    try {
      return JSON.parse(slice);
    } catch {}
    try {
      return JSON.parse(slice.replace(/\\"/g, '"').replace(/\\\\/g, '\\'));
    } catch {}
    return undefined;
  }

  function isPayload(value) {
    if (value === null || typeof value !== 'object') return false;
    return Array.isArray(value) ? value.length > 0 : Object.keys(value).length > 0;
  }

  function acceptFrom(text, from) {
    for (const match of [matchStrict, matchLoose]) {
      const end = match(text, from);
      if (end < 0) continue;
      if (end - from < MIN_CANDIDATE_LEN) continue;
      if (isPayload(parseCandidate(text.slice(from, end)))) return end;
    }
    return -1;
  }

  function scanUnit(text) {
    const hits = [];
    let openers = 0;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (c !== '{' && c !== '[') continue;
      if (++openers > MAX_OPENERS_PER_UNIT) break;
      const end = acceptFrom(text, i);
      if (end > 0) {
        hits.push([i, end]);
        i = end - 1;
      }
    }
    return hits;
  }

  // Graylog wraps search terms in <mark>, so one JSON can be split across several text
  // nodes. We join up to the block boundary and keep an offset map.
  function collectUnits(root) {
    const units = [];
    let text = '';
    let parts = [];

    const flush = () => {
      if (parts.length && (text.includes('{') || text.includes('['))) units.push({ text, parts });
      if (parts.length) {
        text = '';
        parts = [];
      }
    };

    const walk = el => {
      for (let node = el.firstChild; node; node = node.nextSibling) {
        if (node.nodeType === Node.TEXT_NODE) {
          if (!node.data) continue;
          parts.push({ node, start: text.length, len: node.data.length });
          text += node.data;
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          if (SKIP_TAGS.has(node.tagName) || node.isContentEditable) continue;
          if (INLINE_TAGS.has(node.tagName)) {
            walk(node);
          } else {
            flush();
            walk(node);
            flush();
          }
        }
      }
    };

    walk(root);
    flush();
    return units;
  }

  function toRange(unit, start, end) {
    const range = document.createRange();
    let started = false;
    for (const part of unit.parts) {
      const partEnd = part.start + part.len;
      if (!started) {
        if (start >= partEnd) continue;
        range.setStart(part.node, start - part.start);
        started = true;
      }
      if (end <= partEnd) {
        range.setEnd(part.node, end - part.start);
        return range;
      }
    }
    return null;
  }

  function rescan() {
    const previous = ranges.length;
    const found = [];
    for (const unit of collectUnits(document.body)) {
      for (const [start, end] of scanUnit(unit.text)) {
        const range = toRange(unit, start, end);
        if (range) found.push(range);
      }
    }
    ranges = found;
    // Ticking relative timestamps make rescans frequent; keep the position when the count is unchanged.
    cursor = found.length === previous ? Math.min(cursor, found.length - 1) : -1;

    if (highlight) {
      highlight.clear();
      for (const range of found) highlight.add(range);
    }
    schedulePosition();
  }

  function select(range, scroll) {
    const selection = getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    if (scroll) range.startContainer.parentElement?.scrollIntoView({ block: 'nearest' });
  }

  function selectNext() {
    if (!ranges.length) return;
    cursor = (cursor + 1) % ranges.length;
    select(ranges[cursor], true);
  }

  let timer = 0;
  let pendingSince = 0;
  const schedule = () => {
    if (document.hidden) return;
    const now = Date.now();
    if (!pendingSince) pendingSince = now;
    clearTimeout(timer);
    timer = setTimeout(() => {
      pendingSince = 0;
      rescan();
    }, Math.min(DEBOUNCE_MS, Math.max(0, pendingSince + MAX_WAIT_MS - now)));
  };

  addEventListener('keydown', e => {
    if (!isHotkey(e)) return;
    const el = e.target;
    if (el instanceof HTMLElement && (el.isContentEditable || SKIP_TAGS.has(el.tagName))) return;
    e.preventDefault();
    selectNext();
  }, true);

  document.addEventListener('visibilitychange', schedule);
  // capture: Graylog scrolls the table in its own inner scroll container, a window scroll is not enough.
  addEventListener('scroll', schedulePosition, { passive: true, capture: true });
  addEventListener('resize', schedulePosition, { passive: true });
  new MutationObserver(schedule).observe(document.body, { childList: true, subtree: true, characterData: true });
  rescan();
})();
