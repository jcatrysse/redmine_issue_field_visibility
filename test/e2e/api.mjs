// REST API: issue show and list leave out the fields hidden for the API user
// (GET /issues/:id.json, /issues.json, xml), and an update through the API
// keeps the hidden values. Checked with HTTP basic auth against the server.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('api');
const expect = (ok, what) => { if (!ok) t.problems.push(what); };
const auth = u => ({ Authorization: 'Basic ' + Buffer.from(`${u}:Redmine7Test!`).toString('base64') });
const log = [];
await t.anonymous();
const get = async (user, path) => {
  const res = await t.page.request.get(t.BASE + path, { headers: user ? auth(user) : {} });
  log.push(`GET ${path} as ${user || 'anonymous'}: HTTP ${res.status()}`);
  return res;
};
const HIDDEN = ['assigned_to', 'category', 'start_date', 'due_date', 'estimated_hours', 'total_estimated_hours', 'description'];

const m = (await (await get('manager', '/issues/1.json')).json()).issue;
expect(m.assigned_to && m.category && m.estimated_hours === 6 && /Secret/.test(m.description),
  `manager: values missing ${JSON.stringify(m)}`);
log.push(`  manager: ${HIDDEN.map(k => `${k}=${JSON.stringify(m[k] && (m[k].name || m[k]))}`).join(' ')}`);

const r = (await (await get('reporter', '/issues/1.json')).json()).issue;
for (const k of HIDDEN) expect(r[k] == null, `reporter: ${k} = ${JSON.stringify(r[k])}`);
expect(r.subject === 'E2E assigned issue' && r.priority && r.fixed_version, 'reporter: visible fields missing');
log.push(`  reporter: ${HIDDEN.map(k => `${k}=${JSON.stringify(r[k])}`).join(' ')}; priority=${r.priority.name}, fixed_version=${r.fixed_version.name}`);

const list = (await (await get('reporter', '/projects/e2e-project/issues.json?status_id=*&limit=100')).json()).issues;
const leaked = list.filter(i => HIDDEN.some(k => i[k] != null));
expect(list.length > 1 && leaked.length === 0, `reporter list: ${leaked.length} of ${list.length} issues carry hidden fields`);
log.push(`  reporter list: ${list.length} issues, ${leaked.length} with a hidden field`);

const xml = await (await get('reporter', '/issues/1.xml')).text();
expect(!/<assigned_to |Secret description|<estimated_hours>\d/.test(xml), 'reporter xml carries hidden fields');
log.push(`  reporter xml: ${xml.match(/<estimated_hours[^>]*\/?>(?:[^<]*<\/estimated_hours>)?/)?.[0]} ${/<assigned_to /.test(xml) ? 'assigned_to present' : 'no assigned_to'}`);

const put = await t.page.request.put(`${t.BASE}/issues/1.json`, {
  headers: { ...auth('reporter'), 'Content-Type': 'application/json' },
  data: { issue: { notes: 'Note through the API', estimated_hours: 99, assigned_to_id: '' } } });
log.push(`PUT /issues/1.json as reporter {notes, estimated_hours: 99, assigned_to_id: ""}: HTTP ${put.status()}`);
expect(put.status() === 204, `reporter PUT: HTTP ${put.status()}`);
const after = (await (await get('manager', '/issues/1.json')).json()).issue;
expect(after.estimated_hours === 6 && after.assigned_to, `after reporter PUT: ${after.estimated_hours} h, assignee ${JSON.stringify(after.assigned_to)}`);
log.push(`  manager afterwards: estimated_hours=${after.estimated_hours}, assigned_to=${after.assigned_to?.name}`);

const a = (await (await get('admin', '/issues/1.json')).json()).issue;
expect(a.estimated_hours === 6, 'admin: estimated hours missing');

const o = await get('outsider', '/projects/e2e-private/issues.json');
expect(o.status() === 403, `outsider private: HTTP ${o.status()}`);
const anon = await get(null, '/projects/e2e-private/issues.json');
expect([401, 403].includes(anon.status()), `anonymous private: HTTP ${anon.status()}`);

await t.login('manager');
await t.go('/issues/1');
await t.shot('note-through-api', 'The note the reporter added through the API; estimated time still 6:00 h, assignee unchanged');
console.log(log.join('\n'));
const fs = await import('node:fs');
fs.writeFileSync((process.env.RMP_E2E_OUT || 'docs/e2e') + '/api.log', log.join('\n') + '\n');
await t.done();
