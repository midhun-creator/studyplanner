/**
 * StudyPlanner — pure helper functions.
 * No DOM or network access, so they can be unit-tested in Node.
 * Loaded before app.js in the browser; exported for tests via CommonJS.
 */
'use strict';

const MS_PER_DAY = 86_400_000;

/**
 * Format a Date as YYYY-MM-DD using the LOCAL timezone.
 * (Date#toISOString returns UTC, which is wrong for users east of UTC
 * during the first hours of the day.)
 * @param {Date} [d]
 * @returns {string}
 */
function localDateStr(d = new Date()) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/**
 * Parse 'YYYY-MM-DD' (or an ISO string starting with it) as LOCAL midnight.
 * `new Date('2026-01-05')` would be parsed as UTC instead.
 * @param {string} str
 * @returns {Date} Invalid Date if the input is malformed
 */
function parseLocalDate(str) {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(str ?? ''));
  if (!m) return new Date(NaN);
  return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
}

/**
 * Whole calendar days from today until the given date. 0 = today, <0 = past.
 * @param {string} dateStr
 * @param {Date} [now]
 * @returns {number} NaN if dateStr is invalid
 */
function daysUntil(dateStr, now = new Date()) {
  const target = parseLocalDate(dateStr);
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.round((target - today) / MS_PER_DAY);
}

/**
 * Count consecutive days, ending today, that appear in `dates`.
 * @param {Iterable<string>} dates YYYY-MM-DD strings
 * @param {Date} [now]
 * @returns {number}
 */
function calcStreak(dates, now = new Date()) {
  const set = new Set(dates);
  const cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let streak = 0;
  for (let i = 0; i < 366; i++) {
    if (!set.has(localDateStr(cursor))) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

/**
 * Seconds left until `endAt` (epoch ms), never negative.
 * Based on the wall clock, so it stays accurate when tabs are throttled.
 * @param {number} endAt
 * @param {number} [now]
 * @returns {number}
 */
function remainingSeconds(endAt, now = Date.now()) {
  return Math.max(0, Math.ceil((endAt - now) / 1000));
}

/**
 * Format seconds as MM:SS.
 * @param {number} totalSeconds
 * @returns {string}
 */
function formatClock(totalSeconds) {
  const s = Math.max(0, Math.floor(totalSeconds));
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
}

/**
 * Arithmetic mean of finite numbers. Returns null for an empty input.
 * @param {Array<number|string>} values
 * @returns {number|null}
 */
function average(values) {
  const nums = values.map(Number).filter(Number.isFinite);
  if (!nums.length) return null;
  return nums.reduce((a, b) => a + b, 0) / nums.length;
}

/**
 * Client-side admin check. UI gating only — real enforcement must be
 * done with Row Level Security (see supabase/schema.sql).
 * Reads `app_metadata.isAdmin`, which only the server can write
 * (unlike `user_metadata`, which users can edit themselves).
 * @param {{app_metadata?: {isAdmin?: boolean}}|null} user
 * @returns {boolean}
 */
function isAdminUser(user) {
  return user?.app_metadata?.isAdmin === true;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    localDateStr, parseLocalDate, daysUntil, calcStreak,
    remainingSeconds, formatClock, average, isAdminUser,
  };
}
