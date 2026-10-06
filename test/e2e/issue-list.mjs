// The issue list: columns, filters and totals of hidden fields are not
// offered, and asking for them in the URL gives nothing (IssueQuery patch,
// QueriesHelper#column_content). Redmine 6+ adds the estimated remaining time
// column and total, hidden with estimated time.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('issue-list');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const count = sel => t.page.locator(sel).count();
const LIST = '/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id' +
  '&c[]=subject&c[]=assigned_to&c[]=category&c[]=start_date&c[]=due_date' +
  '&c[]=estimated_hours&c[]=estimated_remaining_hours&c[]=total_estimated_hours' +
  '&t[]=estimated_hours&t[]=estimated_remaining_hours';

await t.login('manager');
await t.go(LIST);
for (const c of ['assigned_to', 'category', 'estimated_hours', 'estimated_remaining_hours', 'total_estimated_hours']) {
  expect(await count(`table.issues th.${c}`) === 1, `manager: column ${c} missing`);
}
expect(await count('.query-totals .total-for-estimated-hours') === 1, 'manager: estimated time total missing');
expect(await count('.query-totals .total-for-estimated-remaining-hours') === 1, 'manager: remaining time total missing');
await t.shot('manager', 'Manager: assignee, category, dates, estimated, remaining and total estimated time columns, with totals');

await t.page.click('legend:has-text("Options")').catch(() => {});
expect(await count('#available_c option[value=estimated_remaining_hours], select[name="c[]"] option[value=estimated_remaining_hours]') >= 1,
  'manager: remaining time not in the column options');

await t.login('reporter');
await t.go(LIST);
for (const c of ['assigned_to', 'category', 'start_date', 'due_date', 'estimated_hours', 'estimated_remaining_hours', 'total_estimated_hours']) {
  expect(await count(`table.issues th.${c}`) === 0, `reporter: column ${c} shown`);
  expect(await count(`table.issues td.${c}`) === 0, `reporter: cells ${c} shown`);
}
expect(await count('table.issues th.subject') === 1, 'reporter: subject column missing');
expect(await count('.query-totals .total-for-estimated-hours, .query-totals .total-for-estimated-remaining-hours') === 0,
  'reporter: estimated or remaining total shown');
await t.shot('reporter', 'Reporter, same URL: only the subject column, no estimated or remaining totals');

const options = await t.page.evaluate(() => [...document.querySelectorAll('option')].map(o => o.value));
for (const v of ['assigned_to', 'assigned_to_id', 'category', 'category_id', 'start_date', 'due_date', 'estimated_hours',
                 'estimated_remaining_hours', 'total_estimated_hours']) {
  expect(!options.includes(v), `reporter: option ${v} offered (filter, column, total or group)`);
}
expect(options.includes('status_id'), 'reporter: the status filter is missing');
await t.page.click('legend:has-text("Options")').catch(() => {});
await t.shot('reporter-options', 'Reporter: filters and column/total options without the hidden fields');

// a filter on a hidden field in the URL is ignored, so it cannot be used to probe values
await t.go('/projects/e2e-project/issues?set_filter=1&f[]=estimated_hours&op[estimated_hours]=>=&v[estimated_hours][]=5');
const probed = await count('table.issues tr.issue');
expect(probed > 1, `reporter: probing filter applied (${probed} issue(s) left, only #1 has 5 h or more)`);
await t.shot('reporter-probe', 'Reporter: a filter on estimated time in the URL is dropped, the list is not narrowed by it');

const csv = await t.page.request.get(`${t.BASE}${LIST.replace('/issues?', '/issues.csv?')}&csv[columns]=all`);
const head = (await csv.text()).split('\n')[0];
expect(csv.status() === 200, `reporter CSV: HTTP ${csv.status()}`);
expect(!/Estimated|Assignee|Start date|Due date|Category|Description/i.test(head), `reporter CSV header has a hidden field: ${head}`);
t.check('csv');

await t.go('/projects?display_type=list');
expect(await count('table.projects td.name') > 0, 'reporter: project list rows missing');
await t.shot('project-list', 'Reporter: the project list as a list renders (QueriesHelper patch only touches issues, GEOxyz 4139400)');

await t.done();
console.log('reporter CSV header:', head);
