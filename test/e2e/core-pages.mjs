// The core pages this plugin patches (issue query, issue, version, the issue
// and queries helpers, rendering) answer 200, also with other plugins installed
// that prepend on the same methods (redmine_agile: SystemStackError on every
// issue query while this plugin used alias_method chains). Run alone and on a
// Redmine with RMP_EXTRA_PLUGINS; the refusals stay refusals.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('core-pages');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };

await t.login('manager');
await t.go('/projects/e2e-project/roadmap');
const link = await t.page.locator('a', { hasText: 'E2E 1.0' }).first().getAttribute('href');
const versionPath = link.startsWith('/versions/') ? link : '/versions/1';
const issueId = (await (await t.page.request.get(`${t.BASE}/projects/e2e-project/issues.json?subject=E2E+assigned+issue&status_id=*`)).json())
  .issues?.[0]?.id || 1;

// [path, status per user]
const pages = [
  ['/issues', { admin: 200, manager: 200, reporter: 200, outsider: 200 }],
  ['/projects/e2e-project/issues', { admin: 200, manager: 200, reporter: 200, outsider: 200 }],
  ['/projects/e2e-project/issues?set_filter=1&c[]=subject&c[]=assigned_to&c[]=estimated_hours&c[]=estimated_remaining_hours&t[]=estimated_hours&group_by=category',
    { admin: 200, manager: 200, reporter: 200, outsider: 200 }],
  [`/issues/bulk_edit?ids[]=${issueId}`, { admin: 200, manager: 200, reporter: 403, outsider: 403 }],
  [`/issues/${issueId}`, { admin: 200, manager: 200, reporter: 200, outsider: 200 }],
  [versionPath, { admin: 200, manager: 200, reporter: 200, outsider: 200 }],
  ['/projects/e2e-project/settings', { admin: 200, manager: 200, reporter: 403, outsider: 403 }],
  ['/projects/e2e-private/issues', { admin: 200, manager: 200, reporter: 403, outsider: 403 }],
];

const shots = {
  manager: { '/projects/e2e-project/issues': 'issue-list', [`/issues/bulk_edit?ids[]=${issueId}`]: 'bulk-edit',
    [versionPath]: 'version', '/projects/e2e-project/settings': 'project-settings' },
  reporter: { [`/issues/${issueId}`]: 'issue', '/projects/e2e-project/settings': 'settings-refused',
    [`/issues/bulk_edit?ids[]=${issueId}`]: 'bulk-edit-refused' },
  outsider: { '/projects/e2e-private/issues': 'private-refused' },
};

const table = [];
for (const user of ['admin', 'manager', 'reporter', 'outsider']) {
  await t.login(user);
  for (const [p, statuses] of pages) {
    await t.go(p, { status: statuses[user] });
    const got = statuses[user];
    table.push(`${user} ${got} ${p}`);
    const name = shots[user]?.[p];
    if (name) await t.shot(`${user}-${name}`, `${user}: ${p} answers ${got}`);
  }
}

// the plugin still hides on these pages
await t.login('reporter');
await t.go('/projects/e2e-project/issues?set_filter=1&c[]=subject&c[]=assigned_to&c[]=estimated_hours&c[]=estimated_remaining_hours&t[]=estimated_hours');
const headers = (await t.page.locator('table.list.issues th').allInnerTexts()).join('|');
expect(!/Assignee|Estimated/.test(headers), `reporter: issue list columns ${headers}`);
await t.shot('reporter-issue-list', `Reporter: hidden columns left out of the issue list (${headers.replace(/\|+/g, ', ')})`);
await t.login('manager');
await t.go(`/issues/bulk_edit?ids[]=${issueId}`);
expect(await t.page.locator('#issue_assigned_to_id').count() === 1, 'manager: bulk edit has no assignee field');
expect(await t.page.locator('#issue_estimated_hours').count() === 1, 'manager: bulk edit has no estimated time field');

// redmine_agile, when installed: its board runs the same issue query
const board = await t.page.request.get(`${t.BASE}/projects/e2e-project/agile/board`);
if (board.status() !== 404) {
  await t.go('/projects/e2e-project/agile/board');
  await t.shot('manager-agile-board', 'Manager: the agile board (redmine_agile) answers 200');
  table.push(`manager 200 /projects/e2e-project/agile/board`);
}

console.log(table.join('\n'));
await t.done();
