'use strict';
// In-memory record store. get() and save() hand out copies, never the stored object.

const records = new Map();
let seq = 0;

function copy(r) {
  return JSON.parse(JSON.stringify(r));
}

function nextId(prefix) {
  seq += 1;
  return `${prefix}-${seq}`;
}

function save(record) {
  records.set(record.id, copy(record));
  return copy(record);
}

function get(id) {
  const r = records.get(id);
  return r ? copy(r) : null;
}

function list() {
  return [...records.values()].map(copy);
}

function reset() {
  records.clear();
  seq = 0;
}

module.exports = { nextId, save, get, list, reset };
