'use strict';
const test = require('node:test');
const assert = require('node:assert');
const store = require('../src/store');

test.beforeEach(() => store.reset());

test('save and get hand out copies', () => {
  const saved = store.save({ id: 'X-1', n: 1 });
  saved.n = 99;
  assert.strictEqual(store.get('X-1').n, 1);
  assert.strictEqual(store.get('nope'), null);
});
