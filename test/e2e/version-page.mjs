// The version page and roadmap: estimated and remaining time are summed over
// the version's issues; a role with estimated time hidden gets 0.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('version-page');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };

await t.login('manager');
await t.go('/projects/e2e-project/roadmap');
const link = await t.page.locator('a', { hasText: 'E2E 1.0' }).first().getAttribute('href');
const versionPath = link.startsWith('/versions/') ? link : '/versions/1';
await t.go(versionPath);
const managerHours = await t.page.locator('.time-tracking td.total-hours').allInnerTexts();
expect(managerHours.length >= 2 && /6[:.]00/.test(managerHours[0]), `manager: estimated time ${managerHours[0]}`);
expect(/6[:.]00/.test(managerHours[1] || ''), `manager: remaining time ${managerHours[1]}`);
await t.shot('manager', `Manager: estimated ${managerHours[0]}, remaining ${managerHours[1]}`);

await t.login('reporter');
await t.go(versionPath);
const reporterHours = await t.page.locator('.time-tracking td.total-hours').allInnerTexts();
expect(!reporterHours.some(h => /6[:.]00/.test(h)), `reporter: version shows ${reporterHours.join(' / ')}`);
await t.shot('reporter', `Reporter: estimated and remaining time are 0 (${reporterHours.join(' / ')})`);
await t.go('/projects/e2e-project/roadmap');
await t.shot('reporter-roadmap', 'Reporter: the roadmap renders');

const api = await t.page.request.get(`${t.BASE}${versionPath}.json`, {
  headers: { Authorization: 'Basic ' + Buffer.from('reporter:Redmine7Test!').toString('base64') } });
const v = (await api.json()).version;
expect(Number(v.estimated_hours) === 0, `reporter API: estimated_hours ${v.estimated_hours}`);
const api2 = await t.page.request.get(`${t.BASE}${versionPath}.json`, {
  headers: { Authorization: 'Basic ' + Buffer.from('manager:Redmine7Test!').toString('base64') } });
const v2 = (await api2.json()).version;
expect(Number(v2.estimated_hours) === 6, `manager API: estimated_hours ${v2.estimated_hours}`);
console.log(`GET ${versionPath}.json estimated_hours: reporter ${v.estimated_hours}, manager ${v2.estimated_hours}`);

await t.done();
