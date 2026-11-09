'use strict';

function codeError(code) {
  const e = new Error(code);
  e.code = code;
  return e;
}

// "100.50" -> 10050. Accepts a string of digits with at most two decimals; anything else is BAD_AMOUNT.
function toSatang(str) {
  if (typeof str !== 'string' || !/^\d+(\.\d{1,2})?$/.test(str)) throw codeError('BAD_AMOUNT');
  const [baht, frac = ''] = str.split('.');
  return Number(baht) * 100 + Number(frac.padEnd(2, '0'));
}

// 10050 -> "100.50"
function formatBaht(satang) {
  return `${Math.floor(satang / 100)}.${String(satang % 100).padStart(2, '0')}`;
}

module.exports = { codeError, toSatang, formatBaht };
