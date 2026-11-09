'use strict';
const test = require('node:test');
const assert = require('node:assert');
const store = require('../src/store');
const { createInvoice, recordPayment } = require('../src/invoices');

test.beforeEach(() => store.reset());

test('recordPayment turns OPEN into PARTIAL and PAID', () => {
  const inv = createInvoice('c1', [{ sku: 'A', qty: 1, unitPrice: '0.30' }]);
  assert.strictEqual(recordPayment(inv.id, '0.10').status, 'PARTIAL');
  assert.strictEqual(recordPayment(inv.id, '0.20').status, 'PAID');
});

test('recordPayment rejects an overpayment', () => {
  const inv = createInvoice('c1', [{ sku: 'A', qty: 1, unitPrice: '1.00' }]);
  assert.throws(() => recordPayment(inv.id, '1.01'), { code: 'OVERPAYMENT' });
});

test('a stale save is STALE_VERSION', () => {
  const a = store.save({ id: 'X-1' });
  store.save(a, 1);
  assert.throws(() => store.save(a, 1), { code: 'STALE_VERSION' });
});
