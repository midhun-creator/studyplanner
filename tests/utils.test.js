'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const u = require('../utils.js');

test('localDateStr uses local date parts', () => {
  assert.equal(u.localDateStr(new Date(2026, 0, 5, 0, 30)), '2026-01-05');
  assert.equal(u.localDateStr(new Date(2026, 11, 31, 23, 59)), '2026-12-31');
});

test('parseLocalDate returns local midnight', () => {
  const d = u.parseLocalDate('2026-03-09');
  assert.equal(d.getFullYear(), 2026);
  assert.equal(d.getMonth(), 2);
  assert.equal(d.getDate(), 9);
  assert.equal(d.getHours(), 0);
});

test('parseLocalDate rejects bad input', () => {
  assert.ok(Number.isNaN(u.parseLocalDate('nope').getTime()));
  assert.ok(Number.isNaN(u.parseLocalDate(null).getTime()));
});

test('daysUntil: today is 0, tomorrow 1, yesterday -1', () => {
  const now = new Date(2026, 5, 15, 13, 45);
  assert.equal(u.daysUntil('2026-06-15', now), 0);
  assert.equal(u.daysUntil('2026-06-16', now), 1);
  assert.equal(u.daysUntil('2026-06-14', now), -1);
  assert.equal(u.daysUntil('2026-06-22', now), 7);
});

test('daysUntil ignores time of day', () => {
  assert.equal(u.daysUntil('2026-06-15', new Date(2026, 5, 15, 0, 1)), 0);
  assert.equal(u.daysUntil('2026-06-15', new Date(2026, 5, 15, 23, 59)), 0);
});

test('calcStreak counts consecutive days ending today', () => {
  const now = new Date(2026, 5, 15, 9);
  assert.equal(u.calcStreak(['2026-06-15', '2026-06-14', '2026-06-13'], now), 3);
});

test('calcStreak breaks on a gap and is 0 without today', () => {
  const now = new Date(2026, 5, 15, 9);
  assert.equal(u.calcStreak(['2026-06-15', '2026-06-13'], now), 1);
  assert.equal(u.calcStreak(['2026-06-14'], now), 0);
  assert.equal(u.calcStreak([], now), 0);
});

test('calcStreak crosses month boundaries', () => {
  const now = new Date(2026, 2, 2, 9);
  assert.equal(u.calcStreak(['2026-03-02', '2026-03-01', '2026-02-28'], now), 3);
});

test('remainingSeconds never goes negative', () => {
  assert.equal(u.remainingSeconds(10_000, 4_000), 6);
  assert.equal(u.remainingSeconds(10_000, 4_001), 6);
  assert.equal(u.remainingSeconds(10_000, 20_000), 0);
});

test('formatClock', () => {
  assert.equal(u.formatClock(1500), '25:00');
  assert.equal(u.formatClock(65), '01:05');
  assert.equal(u.formatClock(-5), '00:00');
});

test('average', () => {
  assert.equal(u.average([8, 9, 10]), 9);
  assert.equal(u.average(['7.5', 8.5]), 8);
  assert.equal(u.average([]), null);
  assert.equal(u.average([NaN, 'x']), null);
});

test('isAdminUser reads server-controlled app_metadata only', () => {
  assert.equal(u.isAdminUser({ app_metadata: { isAdmin: true } }), true);
  assert.equal(u.isAdminUser({ app_metadata: { isAdmin: 'true' } }), false);
  assert.equal(u.isAdminUser({ app_metadata: {} }), false);
  // user_metadata is user-editable and must never grant admin
  assert.equal(u.isAdminUser({ user_metadata: { isAdmin: true } }), false);
  assert.equal(u.isAdminUser({ email: 'admin@example.com' }), false);
  assert.equal(u.isAdminUser(null), false);
});
