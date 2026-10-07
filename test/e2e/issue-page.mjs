// The issue page and form: fields hidden for a role are not shown, not
// editable and not in the history (Issue#disabled_core_fields and
// Journal#visible_details). Seed: issue #1 has every hideable field set and a
// journal that changed the estimated time; Reporter hides assignee,
// category, dates, estimated time and description.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('issue-page');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const has = async (sel, text) => (await t.page.locator(sel, text ? { hasText: text } : {}).count()) > 0;

await t.login('manager');
await t.go('/issues/1');
expect(await has('.subject h3', 'E2E assigned issue'), 'issue #1 is not the seeded issue');
for (const cls of ['assigned-to', 'category', 'start-date', 'due-date', 'estimated-hours']) {
  expect(await has(`.issue .attributes .${cls}`), `manager: .${cls} missing`);
}
expect(await has('.issue .description', 'Secret description'), 'manager: description missing');
expect(await has('.journal .journal-details li', 'Estimated time'), 'manager: estimated time change missing in history');
await t.shot('manager', 'Manager (no hidden fields): assignee, category, dates, estimated time, description and the estimate change in the history');

await t.go('/issues/1/edit');
expect(await has('#issue_estimated_hours'), 'manager: no estimated time in the form');
expect(await has('#issue_assigned_to_id'), 'manager: no assignee in the form');
await t.shot('manager-form', 'Manager: the edit form has assignee, category, dates and estimated time');

await t.login('reporter');
await t.go('/issues/1');
expect(await has('.subject h3', 'E2E assigned issue'), 'reporter: issue not shown');
for (const cls of ['assigned-to', 'category', 'start-date', 'due-date', 'estimated-hours']) {
  expect(!(await has(`.issue .attributes .${cls}`)), `reporter: .${cls} shown`);
}
expect(!(await has('body', 'Secret description')), 'reporter: description shown');
expect(!(await has('.journal .journal-details li', 'Estimated time')), 'reporter: estimated time change in history');
expect(await has('.journal', 'Estimate revised.'), 'reporter: the note of that journal is missing');
expect(await has('.issue .attributes .status'), 'reporter: status missing');
await t.shot('reporter', 'Reporter (six fields hidden): no assignee, category, dates, estimated time, description; the history keeps the note, not the estimate change');

// the new issue form leaves the hidden fields out
await t.go('/projects/e2e-project/issues/new');
for (const id of ['issue_assigned_to_id', 'issue_category_id', 'issue_start_date', 'issue_due_date', 'issue_estimated_hours']) {
  expect(!(await has(`#${id}`)), `reporter new form: #${id} shown`);
}
expect(await has('#issue_subject'), 'reporter new form: no subject');
// redmine_itil_priority, when installed, replaces the priority select by urgency and impact
expect(await has('#issue_priority_id') || await has('select[name="issue[urgency_id]"]'), 'reporter new form: no priority');
await t.page.fill('#issue_subject', `Created by the reporter ${Date.now()}`);
await t.shot('reporter-new', 'Reporter: the new issue form without the hidden fields');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('reporter creates an issue');
expect(/\/issues\/\d+$/.test(t.page.url()), `reporter create: still on ${t.page.url()}`);
await t.shot('reporter-created', 'Reporter: the issue is created; the hidden fields are not shown on it');

// a forged hidden value is ignored (safe_attributes)
await t.go('/projects/e2e-project/issues/new');
const forged = await t.page.evaluate(async () => {
  const form = document.querySelector('#issue-form');
  const data = new FormData(form);
  data.set('issue[subject]', 'Forged estimate');
  data.set('issue[estimated_hours]', '77');
  const res = await fetch(form.action, { method: 'POST', body: data, redirect: 'follow' });
  return res.url;
});
const forgedId = (forged.match(/\/issues\/(\d+)/) || [])[1];
expect(forgedId, `forged post: no issue created (${forged})`);

await t.login('manager');
if (forgedId) {
  await t.go(`/issues/${forgedId}`);
  expect(!(await has('.issue .attributes .estimated-hours', '77')), 'forged estimated time 77 was saved');
  await t.shot('forged-ignored', `Manager: issue #${forgedId}, posted by the reporter with estimated_hours=77, has no estimated time`);
}

await t.login('outsider');
await t.go('/issues/1');
await t.shot('outsider', 'Outsider (no membership) sees the public issue as a non member: Non member hides nothing');
const priv = await t.page.request.get(`${t.BASE}/projects/e2e-private/issues`);
expect(priv.status() === 403, `outsider: private project issues answered ${priv.status()}`);

await t.done();
