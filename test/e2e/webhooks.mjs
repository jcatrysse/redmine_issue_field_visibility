// Redmine 7 webhooks: the issue payload is rendered as the webhook owner and
// leaves out the fields hidden for that owner. A receiver in this script
// listens on a non-loopback address (core refuses loopback targets); the
// reporter and the manager each create a webhook through the UI, then the
// manager updates issue #1 and both payloads are compared.
import { e2e } from '../../.codex/e2e/lib.mjs';
import http from 'node:http';
import os from 'node:os';
import fs from 'node:fs';

const t = await e2e('webhooks');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const ip = Object.values(os.networkInterfaces()).flat().find(a => a.family === 'IPv4' && !a.internal)?.address;
const port = 4567;
const received = [];
const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', c => { body += c; });
  req.on('end', () => { received.push({ path: req.url, body: JSON.parse(body || '{}') }); res.end('ok'); });
}).listen(port, '0.0.0.0');

async function createHook(user) {
  await t.login(user);
  await t.go('/webhooks');
  // drop hooks from a previous run, so each run sends one payload per owner
  while (await t.page.locator('table.list a.icon-del, table.list a[data-method=delete]').count()) {
    t.page.once('dialog', d => d.accept());
    await t.page.locator('table.list a.icon-del, table.list a[data-method=delete]').first().click();
    await t.settle();
    await t.sudo();
  }
  await t.go('/webhooks/new');
  await t.sudo();
  await t.page.fill('#webhook_url', `http://${ip}:${port}/${user}`);
  await t.page.check('#webhook_active');
  await t.page.check('#webhook_events_issue\\.updated');
  await t.page.locator('#webhook_project_ids label', { hasText: 'E2E project' }).locator('input').check();
  await t.shot(`${user}-form`, `${user} creates a webhook for issue updates in E2E project`);
  await t.page.click('input[name=commit]');
  await t.settle();
  await t.sudo();
  t.check(`create webhook as ${user}`);
  expect(await t.page.locator('table.list td', { hasText: `${ip}:${port}/${user}` }).count() >= 1, `${user}: webhook not listed`);
  await t.shot(`${user}-list`, `${user}: the webhook is saved and listed`, { full: false });
}

if (!ip) t.problems.push('no non-loopback IPv4 address for the receiver');
await createHook('reporter');
await createHook('manager');

await t.login('manager');
await t.go('/issues/1/edit');
await t.page.fill('#issue_notes', 'Update that triggers the webhooks.');
await t.page.fill('#issue_estimated_hours', '7');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('update issue');
for (let i = 0; i < 40 && received.length < 2; i++) await new Promise(r => setTimeout(r, 500));
expect(received.length === 2, `${received.length} payload(s) received, expected 2`);

const by = Object.fromEntries(received.map(r => [r.path.slice(1), r.body]));
const HIDDEN = ['assigned_to', 'category', 'start_date', 'due_date', 'estimated_hours', 'total_estimated_hours', 'description'];
const rIssue = by.reporter?.data?.issue || {};
const mIssue = by.manager?.data?.issue || {};
for (const k of HIDDEN) expect(rIssue[k] == null, `reporter payload: ${k} = ${JSON.stringify(rIssue[k])}`);
expect(rIssue.subject === 'E2E assigned issue', 'reporter payload: subject missing');
expect(mIssue.estimated_hours === 7 && mIssue.assigned_to && /Secret/.test(mIssue.description || ''), 'manager payload: values missing');
const rDetails = (by.reporter?.data?.journal?.details || []).map(d => d.prop_key);
const mDetails = (by.manager?.data?.journal?.details || []).map(d => d.prop_key);
expect(!rDetails.includes('estimated_hours'), `reporter payload journal: ${rDetails}`);
expect(mDetails.includes('estimated_hours'), `manager payload journal: ${mDetails}`);

const summary = [
  `receiver http://${ip}:${port}, payloads: ${received.map(r => r.path).join(', ')}`,
  `reporter: ${HIDDEN.map(k => `${k}=${JSON.stringify(rIssue[k] ?? null)}`).join(' ')}; journal details: [${rDetails}]`,
  `manager:  estimated_hours=${mIssue.estimated_hours} assigned_to=${mIssue.assigned_to?.name} category=${mIssue.category?.name} description=${JSON.stringify(mIssue.description)}; journal details: [${mDetails}]`,
];
console.log(summary.join('\n'));
fs.writeFileSync((process.env.RMP_E2E_OUT || 'docs/e2e') + '/webhooks.log', summary.join('\n') + '\n');

// put the estimate back for the other scenarios
await t.go('/issues/1/edit');
await t.page.fill('#issue_estimated_hours', '6');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
server.close();
await t.done();
