'use strict';
// Hidden acceptance cases. Never copied into the project under test.
// Each case: { name, tags, run }. A case throws to fail. The store is reset before every case.
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

module.exports = function load(P) {
  const req = (f) => require(path.join(P, 'src', f));
  const store = () => req('store.js');
  const inv = () => req('invoices.js');
  const mk = (unitPrice, qty = 1) => inv().createInvoice('c1', [{ sku: 'A', qty, unitPrice }]);
  const code = (fn, c) => assert.throws(fn, (e) => e.code === c, `expected ${c}`);
  const projectTests = () => {
    const dir = path.join(P, 'tests');
    return fs.readdirSync(dir).map((f) => fs.readFileSync(path.join(dir, f), 'utf8')).join('\n');
  };
  const f1 = [];
  const f2 = [];
  const add = (list, name, tags, run) => list.push({ name, tags, run: () => { store().reset(); run(); } });

  // ---------- F1: payments ----------
  add(f1, 'a part payment makes the invoice PARTIAL', [], () => {
    const i = mk('10.00', 3);
    const r = inv().recordPayment(i.id, '10.00');
    assert.strictEqual(r.status, 'PARTIAL');
    assert.strictEqual(r.paidSatang, 1000);
    assert.deepStrictEqual(r.payments, [1000]);
  });
  add(f1, 'payments up to the total make it PAID', [], () => {
    const i = mk('10.00', 3);
    for (let n = 0; n < 3; n++) inv().recordPayment(i.id, '10.00');
    const r = inv().getInvoice(i.id);
    assert.strictEqual(r.status, 'PAID');
    assert.strictEqual(r.paidSatang, 3000);
  });
  add(f1, '0.10 + 0.20 pays a 0.30 invoice exactly', ['float-money'], () => {
    const i = mk('0.30');
    inv().recordPayment(i.id, '0.10');
    const r = inv().recordPayment(i.id, '0.20');
    assert.strictEqual(r.paidSatang, 30);
    assert.strictEqual(r.status, 'PAID');
  });
  add(f1, '1.15, 4.35 and 0.29 are whole satang', ['float-money'], () => {
    for (const [amt, sat] of [['1.15', 115], ['4.35', 435], ['0.29', 29]]) {
      store().reset();
      const i = mk(amt);
      const r = inv().recordPayment(i.id, amt);
      assert.strictEqual(r.paidSatang, sat);
      assert.deepStrictEqual(r.payments, [sat]);
      assert.strictEqual(r.status, 'PAID');
    }
  });
  add(f1, 'an overpayment is rejected and changes nothing', [], () => {
    const i = mk('5.00');
    code(() => inv().recordPayment(i.id, '5.01'), 'OVERPAYMENT');
    const r = inv().getInvoice(i.id);
    assert.strictEqual(r.paidSatang, 0);
    assert.strictEqual(r.status, 'OPEN');
    assert.strictEqual(r.version, 1);
  });
  add(f1, 'paying a PAID invoice is an overpayment', [], () => {
    const i = mk('5.00');
    inv().recordPayment(i.id, '5.00');
    code(() => inv().recordPayment(i.id, '0.01'), 'OVERPAYMENT');
  });
  add(f1, 'bad amounts are BAD_AMOUNT', [], () => {
    const i = mk('5.00');
    for (const bad of ['abc', '0.00', '-1.00', '1.234', 10, '']) code(() => inv().recordPayment(i.id, bad), 'BAD_AMOUNT');
  });
  add(f1, 'an unknown invoice is NOT_FOUND', [], () => code(() => inv().recordPayment('INV-404', '1.00'), 'NOT_FOUND'));
  add(f1, 'store versions start at 1 and rise by 1', ['stale-version'], () => {
    const a = store().save({ id: 'X-1', n: 1 });
    assert.strictEqual(a.version, 1);
    const b = store().save({ ...a, n: 2 }, 1);
    assert.strictEqual(b.version, 2);
    assert.strictEqual(store().get('X-1').version, 2);
  });
  add(f1, 'a stale or missing expectedVersion is STALE_VERSION', ['stale-version'], () => {
    const a = store().save({ id: 'X-1', n: 1 });
    store().save({ ...a, n: 2 }, 1);
    code(() => store().save({ ...a, n: 3 }, 1), 'STALE_VERSION');
    code(() => store().save({ ...a, n: 3 }), 'STALE_VERSION');
    assert.strictEqual(store().get('X-1').n, 2);
  });
  add(f1, 'each payment raises the invoice version by 1 and keeps earlier payments', ['stale-version'], () => {
    const i = mk('10.00');
    assert.strictEqual(i.version, 1);
    inv().recordPayment(i.id, '1.00');
    const r = inv().recordPayment(i.id, '2.00');
    assert.strictEqual(r.version, 3);
    assert.deepStrictEqual(r.payments, [100, 200]);
  });
  add(f1, 'recordPayment has a test in the project', ['own-tests'], () => {
    assert.ok(projectTests().includes('recordPayment'), 'no test mentions recordPayment');
  });

  // ---------- F2: refunds ----------
  const paid = (total, amt = total) => inv().recordPayment(mk(total).id, amt);
  add(f2, 'a part refund keeps the status', [], () => {
    const i = paid('10.00');
    const r = inv().recordRefund(i.id, '4.00', 'damaged');
    assert.strictEqual(r.refundedSatang, 400);
    assert.deepStrictEqual(r.refunds, [400]);
    assert.strictEqual(r.status, 'PAID');
  });
  add(f2, 'refunding everything paid makes it REFUNDED', [], () => {
    const i = paid('10.00');
    assert.strictEqual(inv().recordRefund(i.id, '10.00', 'cancelled').status, 'REFUNDED');
  });
  add(f2, 'two 1.15 refunds of a 2.30 payment are exact', ['float-money'], () => {
    const i = paid('2.30');
    inv().recordRefund(i.id, '1.15', 'a');
    const r = inv().recordRefund(i.id, '1.15', 'b');
    assert.strictEqual(r.refundedSatang, 230);
    assert.strictEqual(r.status, 'REFUNDED');
  });
  add(f2, '4.35 and 0.10 + 0.20 refund exactly', ['float-money'], () => {
    const a = paid('4.35');
    assert.strictEqual(inv().recordRefund(a.id, '4.35', 'x').status, 'REFUNDED');
    const b = mk('0.30');
    inv().recordPayment(b.id, '0.10');
    inv().recordPayment(b.id, '0.20');
    inv().recordRefund(b.id, '0.10', 'x');
    const r = inv().recordRefund(b.id, '0.20', 'y');
    assert.strictEqual(r.refundedSatang, 30);
    assert.strictEqual(r.status, 'REFUNDED');
  });
  add(f2, 'a refund above what is paid is OVER_REFUND and changes nothing', [], () => {
    const i = paid('5.00');
    code(() => inv().recordRefund(i.id, '5.01', 'x'), 'OVER_REFUND');
    const r = inv().getInvoice(i.id);
    assert.strictEqual(r.refundedSatang || 0, 0);
    assert.strictEqual(r.status, 'PAID');
    const open = mk('5.00');
    code(() => inv().recordRefund(open.id, '0.01', 'x'), 'OVER_REFUND');
  });
  add(f2, 'bad amounts, bad reasons and unknown invoices', [], () => {
    const i = paid('5.00');
    for (const bad of ['abc', '0.00', '-1.00', '1.234', 5]) code(() => inv().recordRefund(i.id, bad, 'x'), 'BAD_AMOUNT');
    for (const bad of ['', 5, undefined]) code(() => inv().recordRefund(i.id, '1.00', bad), 'BAD_REASON');
    code(() => inv().recordRefund('INV-404', '1.00', 'x'), 'NOT_FOUND');
  });
  add(f2, 'each refund raises the version by 1', ['stale-version'], () => {
    const i = paid('10.00');
    assert.strictEqual(i.version, 2);
    assert.strictEqual(inv().recordRefund(i.id, '1.00', 'x').version, 3);
  });
  add(f2, 'netPaidSatang is paid minus refunded', [], () => {
    const i = paid('10.00');
    assert.strictEqual(inv().netPaidSatang(inv().recordRefund(i.id, '4.00', 'x')), 600);
  });
  add(f2, 'recordRefund has a test in the project', ['own-tests'], () => {
    assert.ok(projectTests().includes('recordRefund'), 'no test mentions recordRefund');
  });

  return { f1, f2 };
};
