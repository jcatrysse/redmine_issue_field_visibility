// Mail notifications: the attribute list of an issue mail leaves out the
// fields hidden for the recipient (IssuesHelper#email_issue_attributes) and the
// change of a hidden field is not in the update mail (Journal#visible_details);
// the assignee header and the description follow the recipient too.
import { e2e } from '../../.codex/e2e/lib.mjs';
import fs from 'node:fs';
import path from 'node:path';

const t = await e2e('mail');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const since = Date.now() - 1000;
// delivery_method :file appends every mail to one file per address: start empty
const mailDir = path.join(process.env.REDMINE_DIR || 'redmine', 'tmp', 'mails');
if (fs.existsSync(mailDir)) for (const f of fs.readdirSync(mailDir)) fs.unlinkSync(path.join(mailDir, f));

await t.login('manager');
await t.go('/issues/1/edit');
await t.page.fill('#issue_notes', 'Update that sends mail.');
await t.page.fill('#issue_estimated_hours', '8');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('update issue');

let mails = [];
for (let i = 0; i < 40; i++) {
  mails = t.mails(since).filter(m => m.body.includes('Update that sends mail.'));
  if (mails.some(m => m.to.includes('reporter')) && mails.some(m => m.to.includes('manager'))) break;
  await new Promise(r => setTimeout(r, 500));
}
const forUser = u => mails.find(m => m.to.includes(u))?.body || '';
const text = body => body.replace(/=\r?\n/g, '');
const r = text(forUser('reporter'));
const m = text(forUser('manager'));
expect(r, `no mail for the reporter (${mails.map(x => x.to).join(', ')})`);
expect(m, 'no mail for the manager');
expect(/Assignee: Manager/.test(m) && /Estimated time/.test(m), 'manager mail: assignee or estimate change missing');
expect(!/Assignee:/.test(r.replace(/^X-Redmine-Issue-Assignee:.*$/m, '')), 'reporter mail: assignee listed');
expect(!/^X-Redmine-Issue-Assignee: \S/m.test(r), 'reporter mail: assignee header');
expect(/^X-Redmine-Issue-Assignee: manager/m.test(m), 'manager mail: no assignee header');
expect(!/Secret description/.test(r), 'reporter mail: description');
expect(/Secret description/.test(m), 'manager mail: no description');
expect(!/Estimated time/.test(r), 'reporter mail: estimated time change listed');
expect(/Update that sends mail\./.test(r), 'reporter mail: the note is missing');
const lines = s => s.split(/\r?\n/).filter(l => /^\s*\*?\s*(Assignee|Category|Start date|Due date|Estimated time|Status|Priority)/.test(l)).map(l => l.trim());
const summary = [`mails: ${mails.map(x => x.to).join(', ')}`,
  `manager lines:  ${JSON.stringify(lines(m))}`, `reporter lines: ${JSON.stringify(lines(r))}`,
  `assignee header: manager ${JSON.stringify(m.match(/^X-Redmine-Issue-Assignee:.*$/m)?.[0] ?? null)}, reporter ${JSON.stringify(r.match(/^X-Redmine-Issue-Assignee:.*$/m)?.[0] ?? null)}`,
  `description in the mail: manager ${/Secret description/.test(m)}, reporter ${/Secret description/.test(r)}`];
console.log(summary.join('\n'));
fs.writeFileSync((process.env.RMP_E2E_OUT || 'docs/e2e') + '/mail.log', summary.join('\n') + '\n');

// show the HTML part of both mails, as received
const htmlPart = body => {
  const qp = body.split(/Content-Type: text\/html[^\n]*\n/)[1] || '';
  const html = qp.split(/\r?\n\r?\n/).slice(1).join('\n\n').split(/\r?\n--/)[0];
  return html.replace(/=\r?\n/g, '').replace(/=([0-9A-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
};
for (const [user, body] of [['manager', m], ['reporter', r]]) {
  const header = body.match(/^X-Redmine-Issue-Assignee:.*$/m)?.[0] || 'X-Redmine-Issue-Assignee: (none)';
  await t.page.setContent(`<pre style="background:#eee;padding:6px">To: ${user}  |  ${header}</pre>` +
    Buffer.from(htmlPart(body), 'latin1').toString('utf8'));
  await t.shot(`${user}-mail`, `The update mail as ${user} received it: ${user === 'manager'
    ? 'assignee header and line, category, estimate change and description'
    : 'no assignee header or line, no category, no estimate change, no description; the note is there'}`);
}

await t.go('/issues/1/edit');
await t.page.fill('#issue_estimated_hours', '6');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
await t.done();
