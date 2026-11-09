'use strict';
const test = require('node:test');
const assert = require('node:assert');
const store = require('../src/store');
const { createInvoice, getInvoice, listInvoices } = require('../src/invoices');

test.beforeEach(() => store.reset());

test('createInvoice totals the lines in satang', () => {
  const inv = createInvoice('c1', [
    { sku: 'A', qty: 2, unitPrice: '19.90' },
    { sku: 'B', qty: 1, unitPrice: '0.10' },
  ]);
  assert.strictEqual(inv.totalSatang, 3980 + 10);
  assert.strictEqual(inv.status, 'OPEN');
  assert.strictEqual(inv.paidSatang, 0);
});

test('createInvoice rejects an empty or bad invoice', () => {
  assert.throws(() => createInvoice('c1', []), { code: 'EMPTY_INVOICE' });
  assert.throws(() => createInvoice('c1', [{ sku: 'A', qty: 0, unitPrice: '1.00' }]), { code: 'BAD_QTY' });
});

test('getInvoice and listInvoices', () => {
  const a = createInvoice('c1', [{ sku: 'A', qty: 1, unitPrice: '1.00' }]);
  createInvoice('c2', [{ sku: 'A', qty: 1, unitPrice: '1.00' }]);
  assert.strictEqual(getInvoice(a.id).id, a.id);
  assert.throws(() => getInvoice('INV-999'), { code: 'NOT_FOUND' });
  assert.strictEqual(listInvoices('c1').length, 1);
});
