// The project overview: the "Estimated time" total of the time tracking box is
// left out for a role with estimated time hidden (decision 2, 2026-10-07).
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('project-overview');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };

const box = async () => (await t.page.locator('div.spent_time').allInnerTexts()).join(' ').replace(/\s+/g, ' ');

for (const user of ['admin', 'manager', 'outsider']) {
  await t.login(user);
  await t.go('/projects/e2e-project');
  const text = await box();
  expect(/Estimated time: 6[:.]00/.test(text), `${user}: time tracking box "${text}"`);
  await t.shot(user, `${user}: the time tracking box shows the estimated time total (${text.match(/Estimated time: \S+/)?.[0]})`);
}

await t.login('reporter');
await t.go('/projects/e2e-project');
const text = await box();
expect(text.includes('Spent time'), `reporter: no spent time in "${text}"`);
expect(!text.includes('Estimated time'), `reporter: time tracking box "${text}"`);
await t.shot('reporter', `Reporter (estimated time hidden): the box shows spent time only ("${text}")`);

await t.go('/projects/e2e-private', { status: 403 });
await t.shot('reporter-private-refused', 'Reporter: the private project stays refused');
await t.login('outsider');
await t.go('/projects/e2e-private', { status: 403 });
await t.shot('outsider-private-refused', 'Outsider: the private project stays refused');

await t.done();
