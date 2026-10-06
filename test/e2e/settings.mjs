// The plugin's only page: Administration > Plugins > Configure, a matrix of
// hideable core fields per role. Admin only; the seed hides six fields for
// the role Reporter.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('settings');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const PAGE = '/settings/plugin/redmine_issue_field_visibility';

await t.login('admin');
await t.go('/admin/plugins');
expect(await t.page.locator('tr#plugin-redmine_issue_field_visibility a', { hasText: 'Configure' }).count() === 1,
  'plugin list: no Configure link');
await t.shot('plugin-list', 'The plugin is listed with a Configure link', { full: false });

await t.go(PAGE);
await t.sudo();
const box = (role, field) => t.page.locator(`input[name="settings[hiddenfields][${role}][${field}]"]`);
const roleId = await t.page.evaluate(() => {
  const th = [...document.querySelectorAll('table.issue-visibilities thead tr:nth-child(2) td')]
    .findIndex(td => td.textContent.trim() === 'Reporter');
  const cb = document.querySelectorAll('table.issue-visibilities tbody tr:first-child td')[th]
    ?.querySelector('input[type=checkbox]');
  return cb ? cb.name.match(/\[hiddenfields\]\[(\d+)\]/)[1] : null;
});
expect(roleId, 'settings: no column for the role Reporter');
expect(await box(roleId, 'estimated_hours').isChecked(), 'settings: estimated time is not checked for Reporter');
expect(!(await box(roleId, 'priority_id').isChecked()), 'settings: priority is checked for Reporter');
const fields = await t.page.locator('table.issue-visibilities tbody td.fieldname').allTextContents();
expect(fields.length === 8, `settings: ${fields.length} hideable fields, expected 8 (${fields.join(', ')})`);
await t.shot('matrix', `The matrix: ${fields.length} fields (${fields.map(f => f.trim()).join(', ')}) per role; Reporter has six hidden`);

// change one box, save, see it kept, and put it back
await box(roleId, 'priority_id').check();
await t.page.click('#settings input[type=submit], input[name=commit]');
await t.settle();
t.check('save settings');
await t.sudo();
expect(await t.page.locator('#flash_notice').count() === 1, 'save: no success message');
expect(await box(roleId, 'priority_id').isChecked(), 'save: priority not kept for Reporter');
await t.shot('saved', 'Saved: the success message, priority now hidden for Reporter', { full: false });

await t.login('reporter');
await t.go('/projects/e2e-project/issues/new');
expect(await t.page.locator('#issue_priority_id').count() === 0, 'reporter: priority still on the new issue form');
await t.shot('priority-hidden', 'With priority hidden the reporter\'s new issue form has no priority field');

await t.login('admin');
await t.go(PAGE);
await t.sudo();
await box(roleId, 'priority_id').uncheck();
await t.page.click('input[name=commit]');
await t.settle();
await t.sudo();
expect(!(await box(roleId, 'priority_id').isChecked()), 'restore: priority still checked');

for (const user of ['manager', 'reporter', 'outsider']) {
  await t.login(user);
  await t.go(PAGE, { status: 403 });
}
await t.shot('refused', 'The settings page is refused to a non-admin (here: outsider)', { full: false });
await t.anonymous();
await t.go(PAGE);
expect(new URL(t.page.url()).pathname === '/login', `anonymous: not sent to the login page (${t.page.url()})`);

await t.done();
