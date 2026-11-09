'use strict';
// In-memory record store with optimistic versions. get() and save() hand out copies.
const { codeError } = require('./money');

const records = new Map();
let seq = 0;

function copy(r) {
  return JSON.parse(JSON.stringify(r));
}

function nextId(prefix) {
  seq += 1;
  return `${prefix}-${seq}`;
}

function save(record, expectedVersion) {
  const current = records.get(record.id);
  if (current && expectedVersion !== current.version) throw codeError('STALE_VERSION');
  const stored = copy(record);
  stored.version = current ? current.version + 1 : 1;
  records.set(stored.id, stored);
  return copy(stored);
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
