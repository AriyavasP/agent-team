'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { toSatang, formatBaht } = require('../src/money');

test('toSatang reads baht strings', () => {
  assert.strictEqual(toSatang('100.50'), 10050);
  assert.strictEqual(toSatang('7'), 700);
  assert.strictEqual(toSatang('0.05'), 5);
});

test('toSatang rejects anything else', () => {
  for (const bad of ['', 'abc', '-1.00', '1.234', 12, null]) {
    assert.throws(() => toSatang(bad), { code: 'BAD_AMOUNT' });
  }
});

test('formatBaht', () => {
  assert.strictEqual(formatBaht(10050), '100.50');
  assert.strictEqual(formatBaht(5), '0.05');
});
