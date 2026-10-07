// The issue tooltip in the gantt chart and the calendar leaves out the lines
// of fields hidden for the user (decision 2, 2026-10-07); the bars stay.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('tooltip');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };

const pages = { gantt: '/projects/e2e-project/issues/gantt', calendar: '/projects/e2e-project/issues/calendar' };

async function tip(kind) {
  const sel = kind === 'gantt' ? 'div.tooltip' : 'div.issue.tooltip';
  const all = t.page.locator(sel).filter({ hasText: 'E2E assigned issue' });
  if (!(await all.count())) return null;
  const el = all.first();
  await el.hover();
  await t.page.waitForTimeout(300);
  return (await el.locator('span.tip').textContent()).replace(/\s+/g, ' ');
}

for (const user of ['admin', 'manager', 'outsider', 'reporter']) {
  await t.login(user);
  for (const [kind, url] of Object.entries(pages)) {
    await t.go(url);
    const text = await tip(kind);
    if (text === null) { t.problems.push(`${user} ${kind}: no bar for issue #1`); continue; }
    if (user === 'reporter') {
      expect(/Status:/.test(text) && /Priority:/.test(text), `reporter ${kind}: tooltip "${text}"`);
      expect(!/Assignee|Manager E2E|Start date|Due date/.test(text), `reporter ${kind}: hidden field in tooltip "${text}"`);
      await t.shot(`${user}-${kind}`, `Reporter (assignee and dates hidden): ${kind} tooltip "${text}"`, { full: false });
    } else {
      expect(/Assignee: .*Manager E2E/.test(text) && /Start date:/.test(text) && /Due date:/.test(text),
        `${user} ${kind}: tooltip "${text}"`);
      await t.shot(`${user}-${kind}`, `${user}: ${kind} tooltip with dates and assignee "${text}"`, { full: false });
    }
  }
}

await t.login('outsider');
await t.go('/projects/e2e-private/issues/gantt', { status: 403 });
await t.shot('outsider-private-refused', 'Outsider: the gantt of the private project stays refused');

await t.done();
