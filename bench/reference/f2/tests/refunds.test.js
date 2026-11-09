'use strict';
const test = require('node:test');
const assert = require('node:assert');
const store = require('../src/store');
const { createInvoice, recordPayment, recordRefund, netPaidSatang } = require('../src/invoices');

test.beforeEach(() => store.reset());

test('recordRefund refunds in full and part', () => {
  const inv = createInvoice('c1', [{ sku: 'A', qty: 1, unitPrice: '2.30' }]);
  recordPayment(inv.id, '2.30');
  const part = recordRefund(inv.id, '1.15', 'damaged');
  assert.strictEqual(part.status, 'PAID');
  assert.strictEqual(netPaidSatang(part), 115);
  assert.strictEqual(recordRefund(inv.id, '1.15', 'damaged').status, 'REFUNDED');
});

test('recordRefund rejects what is not paid', () => {
  const inv = createInvoice('c1', [{ sku: 'A', qty: 1, unitPrice: '1.00' }]);
  assert.throws(() => recordRefund(inv.id, '0.01', 'x'), { code: 'OVER_REFUND' });
});
