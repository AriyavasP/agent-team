'use strict';
const store = require('./store');
const { codeError, toSatang } = require('./money');

// lines: [{ sku: string, qty: positive integer, unitPrice: "19.90" }]
function createInvoice(customerId, lines) {
  if (!Array.isArray(lines) || lines.length === 0) throw codeError('EMPTY_INVOICE');
  let totalSatang = 0;
  for (const line of lines) {
    if (!Number.isInteger(line.qty) || line.qty < 1) throw codeError('BAD_QTY');
    totalSatang += toSatang(line.unitPrice) * line.qty;
  }
  return store.save({
    id: store.nextId('INV'),
    customerId,
    lines,
    totalSatang,
    paidSatang: 0,
    payments: [],
    status: 'OPEN',
  });
}

function getInvoice(id) {
  const inv = store.get(id);
  if (!inv) throw codeError('NOT_FOUND');
  return inv;
}

function listInvoices(customerId) {
  return store.list().filter((r) => r.customerId === customerId);
}

function recordPayment(invoiceId, amount) {
  const inv = getInvoice(invoiceId);
  const satang = toSatang(amount);
  if (satang === 0) throw codeError('BAD_AMOUNT');
  if (inv.paidSatang + satang > inv.totalSatang) throw codeError('OVERPAYMENT');
  inv.payments = [...inv.payments, satang];
  inv.paidSatang += satang;
  inv.status = inv.paidSatang === inv.totalSatang ? 'PAID' : 'PARTIAL';
  return store.save(inv, inv.version);
}

module.exports = { createInvoice, getInvoice, listInvoices, recordPayment };
