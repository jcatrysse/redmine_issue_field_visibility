// The settings page without any role shows a translated hint instead of the
// matrix (decision 3, 2026-10-07). The roles are moved aside in the e2e
// database (PostgreSQL) for the duration of the check and put back after.
// Core recreates the builtin roles (Non member, Anonymous) as soon as a request
// needs them, so the hint is rare in practice: the roles go aside after login
// and sudo, and builtin roles recreated meanwhile are removed again.
import { e2e } from '../../.codex/e2e/lib.mjs';
import { execFileSync } from 'node:child_process';

const t = await e2e('settings-no-roles');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const PAGE = '/settings/plugin/redmine_issue_field_visibility';
const sql = (q) => execFileSync('psql', ['-h', process.env.RMP_DB_HOST || '127.0.0.1', '-U', process.env.RMP_DB_USER || 'redmine',
  '-d', process.env.RMP_SERVER_DB_NAME || 'redmine_e2e', '-tAc', q],
  { env: { ...process.env, PGPASSWORD: process.env.RMP_DB_PASSWORD || 'redmine' } }).toString().trim();

const language = sql("SELECT language FROM users WHERE login = 'admin'");
await t.login('admin');
await t.go(PAGE);
await t.sudo();
sql("DROP TABLE IF EXISTS roles_e2e_aside; CREATE TABLE roles_e2e_aside AS SELECT * FROM roles; DELETE FROM roles");
try {
  await t.go(PAGE);
  let text = (await t.page.locator('#settings p, form p').allInnerTexts()).join(' ');
  expect(text.includes('Set up some roles before using this plugin.'), `admin (English): "${text}"`);
  expect(await t.page.locator('table.issue-visibilities').count() === 0, 'admin: a matrix without roles');
  await t.shot('admin-en', 'Admin, English: no roles, the hint instead of the matrix', { full: false });

  sql("UPDATE users SET language = 'de' WHERE login = 'admin'");
  await t.go(PAGE);
  text = (await t.page.locator('#settings p, form p').allInnerTexts()).join(' ');
  expect(text.includes('Legen Sie Rollen an, bevor Sie dieses Plugin verwenden.'), `admin (German): "${text}"`);
  await t.shot('admin-de', 'Admin, German: the same hint in the user\'s language', { full: false });

  for (const user of ['manager', 'reporter', 'outsider']) {
    await t.login(user);
    await t.go(PAGE, { status: 403 });
    await t.shot(`${user}-refused`, `${user}: the settings page is refused (403)`, { full: false });
  }
} finally {
  sql("DELETE FROM roles; INSERT INTO roles SELECT * FROM roles_e2e_aside; DROP TABLE roles_e2e_aside");
  sql(`UPDATE users SET language = '${language.replace(/'/g, "''")}' WHERE login = 'admin'`);
}

await t.login('admin');
await t.go(PAGE);
await t.sudo();
expect(await t.page.locator('table.issue-visibilities').count() === 1, 'admin: matrix not back after restoring the roles');
await t.shot('admin-restored', 'Roles back: the matrix again', { full: false });

await t.done();
