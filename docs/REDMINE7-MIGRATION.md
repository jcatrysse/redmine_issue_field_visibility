# Redmine 7 migration: redmine_issue_field_visibility

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. That includes the plugin's tests on
> PostgreSQL and MariaDB, every function exercised end to end on a real running Redmine in a
> browser (with and without permissions, failure paths included) with screenshots you looked at,
> and an OpenAI review of the diff when OPENAI_API_KEY is set. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_issue_field_visibility` |
| GEOxyz runs today | `master` |
| Upstream | planio-gmbh/redmine_issue_field_visibility (master @ a1ff152, 2022-06-27, voorouder van master) |
| Runs on Redmine 7 as is | DEELS (before this branch); on this branch: JA |
| Upstream sync | UPSTREAM DOOD |
| After sync | n.v.t. |
| State of this branch (2026-10-06) | work list done; tests green on 7.0-stable-GEOxyz PostgreSQL 16 and MariaDB 10.11 (33 runs, 195 assertions each) and on 5.1-stable (32 runs, 160 assertions); e2e 7 scenarios + smoke + core green on both databases; OpenAI review: last round no findings |
| Complexity (1 trivial .. 5 rewrite) | 3 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `975af11` |

## Already on this branch

Commits after the plan (`9367e5f`), oldest first:

| commit | what |
|---|---|
| `b8e78f0` | estimated remaining time column and total hidden with estimated time (item 1/4) |
| `34f7b19` | estimated and remaining time 0 on the version page and version API (`visible_fixed_issues`), `Version#estimated_remaining_hours` (item 1/4) |
| `facda17` | `Issue#reload(*args)`: `issue.lock!` raised ArgumentError with the plugin |
| `33aa8c5` | hidden fields cached per user **and project** (a new issue whose project comes from the params was not hidden). Note: this commit also carries `application_controller_patch.rb` and `test/integration/api_test.rb`, which belong to `ebf665a` (init.rb only requires the patch from `ebf665a`); pushed, so not rewritten |
| `ebf665a` | REST API leaves hidden fields out (item 2/5): readers guarded inside `RedmineIssueFieldVisibility.hide_values`, API rendering wrapped |
| `eb4fba8` | webhook payloads leave hidden fields out (item 3/6) |
| `84dd3f7` | test for GEOxyz `4139400` |
| `8e71a85` | hidden description left out of the issue page, PDF and Atom (all IssuesController rendering inside `hide_values`) |
| `98cbb36` | issue mails: `X-Redmine-Issue-Assignee` header and description follow the recipient |
| `31b2158` | test independent of the MariaDB clock (Setting cache) |
| `ffe1644` | version 1.2.0, README, CHANGELOG |
| `8f3aed3` | OpenAI finding: zero-estimate version relation not kept for a user who sees estimates |
| `b2fe8a5`, `b7e3ad8` | PDF test (answers an OpenAI finding), `require 'zlib'` |
| `308f8e5`, `6c55afa`, `9389227`, `dd49db6` | e2e scenarios and evidence: PostgreSQL, MariaDB, before (5.1), final PostgreSQL run |
| `bf9a550`, `0b94037`, `6657698` | OpenAI reviews with resolutions |

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Priority items**

1. DONE (`b8e78f0`, `34f7b19`, `8f3aed3`) Hide estimated_remaining_hours (column, total, version page) together with estimated_hours.
2. DONE (`ebf665a`, `33aa8c5`) Make the getter wrappers work on Redmine 7 (they are not installed today, so the REST API returns hidden values). Measured: they were not installed on 5.1 either (test and production/eager load, plugin alone), so GEOxyz has run without them since `cd3554e` (2023). Redesigned as readers that answer nil only inside `RedmineIssueFieldVisibility.hide_values`, used while rendering for a user; see open question 1.
3. DONE (`eb4fba8`) Redmine 7 webhooks (#29664) send the core issue API payload (app/views/issues/show.api.rsb, rendered as the webhook owner) and bypass plugin hooks and patches on controllers/views. Check whether this plugin changes what an issue shows, hides or adds, and make webhook payloads consistent with that. `Issue#webhook_payload` renders inside `hide_values`; journal details already went through `Journal#visible_details(user)`. Proven in `test/unit/issue_values_test.rb` and `test/e2e/webhooks.mjs` (real POSTs to a receiver).

**Open items from the analysis** (Dutch; where they conflict with a decision or a priority item above, those win)

4. DONE, see 1.
5. DONE, see 2 (define_method on Issue calling super into the generated attribute/association methods; no prepend, so it composes with other plugins' alias chains).
6. DONE, see 3.

**Checks**

7. DONE. See "Results".
8. DONE. See "Inventory of functions" and "Results".

## GEOxyz changes to review or re-apply

These GEOxyz commits are on the branch GEOxyz runs today and therefore on this branch. Review each one against the code it now sits on (upstream merges and Redmine 7 core): drop it if upstream or core now does the same, rewrite it if it is not up to the quality rules below (tests, I18n, security, portability), keep it otherwise. Record the verdict per commit in this file.

| commit | date | subject |
|---|---|---|
| `4139400` | 2023-08-07 | The column_content_with_ifv method expects an Issue instance but received a Project instance. We need to ensure that this method is only invoked with Issue objects. |
| `e0c7abf` | 2023-08-07 | Correction on wrong file move on my side |
| `cd3554e` | 2023-08-07 | * Resolved issue: `SystemStackError (stack level too deep)`     Converted all methods to use `alias_method` * Removal of `setup` method * Renamed `History.txt` to `CHANGELOG.md` |

Verdicts:

- `4139400` KEEP. Still needed on Redmine 7: the project list as a list renders its rows through `QueriesHelper#column_content`. Test `test/functional/projects_controller_test.rb` (`84dd3f7`) raises `NoMethodError hidden_core_field? for Project` without it; e2e `issue-list-project-list.png`.
- `e0c7abf` KEEP. File move only.
- `cd3554e` KEEP, partly REWRITTEN. `alias_method` instead of upstream's `prepend` stays (it fixed a SystemStackError with other plugins' alias chains, and the overlapping GEOxyz plugins use alias chains or prepend on other methods). Its getter part was silently inactive (`Issue.method_defined?(field)` is false when init.rb runs): rewritten in `ebf665a` without `prepend` (define_method on Issue with super, alias where Issue defines the reader itself) and scoped to rendering, see open question 1.

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- No migrations, no new settings, no new gems; the plugin settings are kept as they are. Version is 1.2.0.
- Behaviour change for users whose roles hide fields (intended, these were leaks on 5.1 as well, see `docs/e2e/before/`):
  REST API responses (`/issues.json|xml`, `/issues/:id.json|xml`, the create response, `/versions/:id.json`) and Redmine 7 webhook payloads now return `null` (or leave out the `assigned_to`, `category`, `fixed_version`, `priority` objects) for fields hidden for the API user or the webhook owner. **Check the roles of integration accounts** (API keys, webhook owners): if one of their roles hides a field an integration needs, give the account a role that does not hide it (an admin sees everything).
- Issue mails no longer carry `X-Redmine-Issue-Assignee` or the description for recipients who have these fields hidden: mail filters that sort on that header for such users stop matching.
- The version page shows 0:00 for estimated and remaining time to users with estimated time hidden.

## Inventory of functions

Seed (`test/e2e/seed.rb`): role Reporter hides assignee, category, start and due date, estimated time and description; issue #1 has all of them set, a version, a journal that changed the estimate; role E2E full (manager) hides nothing. Screenshots in `docs/e2e/` (PostgreSQL), `docs/e2e/mariadb/` (same set on MariaDB), `docs/e2e/before/` (Redmine 5.1 with master @ 4139400).

| function | how a user reaches it | scenario | screenshots |
|---|---|---|---|
| Settings matrix (fields x roles), save, admin only | Administration > Plugins > Configure (`/settings/plugin/redmine_issue_field_visibility`) | `settings.mjs` | `settings-plugin-list`, `settings-matrix`, `settings-saved`, `settings-priority-hidden`, `settings-refused` (403 for manager, reporter, outsider; anonymous to login) |
| Issue page: hidden attributes, description, history details | `/issues/:id` | `issue-page.mjs` | `issue-page-manager`, `issue-page-reporter`, `issue-page-outsider` (Non member hides nothing) |
| Issue forms: hidden fields not shown and not settable (forged POST ignored) | new / edit issue | `issue-page.mjs` | `issue-page-manager-form`, `issue-page-reporter-new`, `issue-page-reporter-created`, `issue-page-forged-ignored` |
| Issue list: columns, filters, totals (incl. remaining time), group by, CSV, filter probing via URL | `/projects/:id/issues` | `issue-list.mjs` | `issue-list-manager`, `issue-list-reporter`, `issue-list-reporter-options`, `issue-list-reporter-probe`; CSV header as reporter: `#,Subject` |
| Project list as list (GEOxyz 4139400) | `/projects?display_type=list` | `issue-list.mjs` | `issue-list-project-list` |
| Version page and version API: estimated / remaining time | Roadmap > version, `/versions/:id.json` | `version-page.mjs` | `version-page-manager` (6:00), `version-page-reporter` (0:00), `version-page-reporter-roadmap`; API: reporter 0, manager 6 |
| REST API: issue show, list, xml, update keeps hidden values, refusals | `/issues/1.json` etc. with basic auth | `api.mjs` (log `docs/e2e/api.log`) | `api-note-through-api` |
| Webhooks (Redmine 7): payload per owner | My account > Webhooks; receiver in the script | `webhooks.mjs` (log `webhooks.log`) | `webhooks-reporter-form`, `webhooks-reporter-list`, `webhooks-manager-form`, `webhooks-manager-list` |
| Mail: attributes, assignee header, description, change details | issue update notification (`tmp/mails`) | `mail.mjs` (log `mail.log`) | `mail-manager-mail`, `mail-reporter-mail` |
| Issue PDF and Atom: hidden description | `/issues/:id.pdf`, `/issues.atom` | unit/functional tests; pdftotext on the server: description 1x as manager, 0x as reporter | (no page) |
| Core flows with the plugin | new issue, note, context menu, refusal | `.codex/e2e/core.mjs` | `core-*` |
| Smoke | the plugin adds no GET routes besides the settings page | `.codex/e2e/smoke.mjs` | `smoke-*` |

No rake tasks, cron jobs, macros, hooks, migrations or mail handlers in this plugin.

## Results

Baseline (before any change, `9367e5f`): 7.0-stable-GEOxyz PostgreSQL: 8 runs, 42 assertions, 0 failures; smoke 11 / core 6 screenshots, 0 problems (`docs/e2e/baseline/`). 5.1-stable PostgreSQL with master: 8 runs, 35 assertions, 0 failures. Getter wrappers installed: 0 of 8 on both (test and production mode).

Final (`dd49db6`, code unchanged since `b7e3ad8`):

| run | result |
|---|---|
| tests, 7.0-stable-GEOxyz, PostgreSQL 16.15 | 33 runs, 195 assertions, 0 failures, 0 errors, 0 skips |
| tests, 7.0-stable-GEOxyz, MariaDB 10.11.14 | 33 runs, 195 assertions, 0 failures, 0 errors, 0 skips (3 runs in a row) |
| tests, 5.1-stable, PostgreSQL, Ruby 3.2.6 | 32 runs, 160 assertions, 0 failures (the webhook test exists on 7 only) |
| e2e, PostgreSQL, fresh database | smoke 11, core 6, scenarios 7 with 27 screenshots, 0 problems |
| e2e, MariaDB, fresh database | same, 0 problems (`docs/e2e/mariadb/`) |
| e2e, 5.1 with this branch (not committed) | 0 problems except checks of Redmine 6+ features (remaining time) and 7.0 markup |
| e2e before, 5.1 with master | API: 9 leaks; version page shows 6:00 to reporter; description on the issue page; mail assignee header and description (`docs/e2e/before/*.md`) |
| together with redmine_itil_priority, redmine_parent_child_filters, redmine_issue_todo_lists2, redmine_extended_api, redmine_view_issue_description, redmine_tint_issues (their redmine70-migration branch where it exists) | tests 31/31 green (role permission `view_issue_description` granted in a temporary setup hook: that plugin makes it mandatory to open an issue, core fixtures lack it); e2e all green after granting the same permission to the seeded roles. Static scan of 34 public GEOxyz plugins: none patches the readers, `render_to_body`, `Mailer#issue_add/issue_edit`, `Version#visible_fixed_issues` or `webhook_payload`; overlaps only on `IssueQuery` filters/columns and `column_content` (alias chains or prepend, compose fine) |
| migrations | none in this plugin |
| own review | see "Own review notes" |
| OpenAI review | 3 rounds: `docs/reviews/openai-2026-10-06-ffe1644.md` (1 fixed, 1 not a bug), `-bf9a550.md` (not a bug, proven by a new PDF test), `-0b94037.md` (1 hardening, 1 not a bug), `-6657698.md`: no findings |

## Own review notes

- Readers are guarded only inside `hide_values`: API rendering (any controller), every IssuesController rendering (HTML, PDF, Atom, CSV, JS), webhook payloads, issue mails. Never around an action, so saves and Redmine's calculations (parent dates, done ratio weighted by `total_estimated_hours`, rescheduling) see the real values; `test_update_json_should_keep_hidden_values` and the e2e PUT prove an update by a user with hidden fields keeps them.
- The guard is a thread/fiber-local flag; nested renders restore the previous value.
- Inside IssuesController views a hidden `priority` is nil; core reads it nil-safe there (`css_classes` uses `try`, the show row is skipped through `disabled_core_fields`). Gantt and calendar tooltips (`issue.priority.name`) are outside IssuesController and not wrapped.
- `Issue#visible?` for a role with "own issues" visibility checks `assigned_to`; inside `hide_values` a hidden assignee makes such child issues drop out of the API children list (over-hiding, not a leak).
- Version totals use the version's project for the hidden check, as before; issues of other projects in a shared version follow that project's setting.

## Open questions for Jan

1. **Scope of the getter wrappers.** Upstream (planio) overrode the readers globally (always nil for a hidden field); GEOxyz `cd3554e` disabled that by accident in 2023, so production has run without it. Options: (a) global, like upstream: also hides on gantt, calendar, activity, search, but Redmine's own calculations would see nil (parent done ratio weighted by estimated time, copying, rescheduling) and could store wrong values; (b) scoped to rendering for a user (API, webhooks, issue pages, mails). **Built: (b)**, recommended: no data risk, no behaviour change for users who see the fields.
2. **Remaining places where a hidden field is still visible** (same on 5.1, not fixed because it changes pages users use daily): gantt and calendar (dates, and the tooltip with assignee and priority), activity and search results (description), the project overview "Estimated time" total (`ProjectsController#show`), the subtask list on 5.1 (on 7 it goes through `column_content` and is hidden). Recommendation: hide the project overview total and the tooltip lines next; leave gantt/calendar bars (hiding dates there makes the charts useless for that role).
3. The settings page still has one hard-coded English string ("Set up some roles before using this plugin.", only shown without roles). Not changed (pre-existing); recommend an I18n key in a later change.
4. `.codex/test_setup.sh` fails as root when it provisions PostgreSQL (`$SUDO -u postgres` with an empty `$SUDO`); worked around by creating the role by hand and `RMP_PROVISION_DB=0`. The script is shared tooling, so not changed here.

## What is left

- Nothing of the work list. Not testable here: none (no IdP/LDAP/OAuth/mail server involved in this plugin; mail checked through file delivery, webhooks through a local receiver).

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```

```sh
./.codex/start_server.sh       # real Redmine (production mode) with this plugin, seeded users and projects
./.codex/e2e.sh                # browser: smoke over the plugin's pages, core issue flows, test/e2e/*.mjs
./.codex/openai_review.sh      # independent OpenAI review of the diff, only when OPENAI_API_KEY is set
```
Write one scenario per function in `test/e2e/<function>.mjs` (example at the top of
`.codex/e2e/lib.mjs`); screenshots and a table per scenario land in `docs/e2e/`. Users:
`admin`, `manager` (every permission), `reporter` (no plugin permissions), `outsider` (no
membership); password `Redmine7Test!`. Needs Node with Playwright and Chromium
(`npm install -g playwright && npx playwright install --with-deps chromium`).

On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow (tick
"e2e" for the browser run; screenshots come back as an artifact).

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline, before you change anything**:
   - the plugin's tests on Redmine 7.0-stable-GEOxyz with PostgreSQL and with MariaDB;
   - a real running Redmine with this plugin (`./.codex/start_server.sh`) and the browser run
     (`./.codex/e2e.sh`: smoke over every page the plugin adds, plus the core issue flows).
   Write the numbers here. Something already broken now is a finding, not your regression.
3. **Inventory of functions**: list every function of the plugin in this file, in a table
   "function | how a user reaches it | scenario | screenshot". Take them from the README,
   `init.rb` (permissions, menus, settings, project modules), routes, hooks and view
   overrides, macros, mail handling, API endpoints, rake tasks and cron jobs. This table is the
   coverage list for step 8; a function that is not in it will not be tested.
4. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
5. **Work list**: then the numbered list, in order. One concern per commit.
6. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **End to end, visually, every function**: on the real Redmine from `start_server.sh`
   (production mode, the way GEOxyz runs it), write one scenario per function in
   `test/e2e/<function>.mjs` with `.codex/e2e/lib.mjs` and run them with `./.codex/e2e.sh`.
   - Each function as the users that matter: `admin`, `manager` (every permission, the
     plugin's included), `reporter` (member without the plugin's permissions), `outsider`
     (no membership, private project must stay invisible).
   - The failure paths too: setting off, permission absent, empty state, invalid input, the
     value that used to raise. A refusal that is shown is evidence as much as a success.
   - One screenshot per function and per path, with a caption saying what it proves. Open
     every screenshot and look at it: a picture nobody looked at proves nothing. Commit them
     in `docs/e2e/` and list them in the inventory table.
   - Functions without a page (mail in and out, REST API, rake tasks, cron, webhooks): exercise
     them against the same running instance (mails land in `redmine/tmp/mails`, `t.mails()`
     reads them; API through `t.page.request`) and record command and result.
   - Before pictures where behaviour or layout changes: the branch GEOxyz runs today, on
     Redmine 5.1, same scenarios, `RMP_E2E_OUT=docs/e2e/before`.
   - Run the whole e2e set once on MariaDB as well (`RMP_DB=mariadb`, then `start_server.sh --reset`).
9. **Independent review**: first your own, adversarial: re-read the whole diff as if someone
   else wrote it and you are paid to reject it. Then, **when `OPENAI_API_KEY` is set in the
   session**, `./.codex/openai_review.sh`: it sends the diff of this branch to an OpenAI model
   and writes `docs/reviews/openai-<date>-<sha>.md`. Every finding gets a `Resolution:` line
   there (fixed in <commit>, with a test, or why not). Fix, re-run the tests and the e2e set,
   and run the review again until it has nothing new that you accept. Without the key: write
   "OpenAI review: skipped, no OPENAI_API_KEY" in the report; never send code anywhere else.
10. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
    settings, cron, files, removed features) goes into the section "After the upgrade".
11. **Finish**: update "Status", the inventory and the work list in this file, push
    `redmine70-migration`, and report: what changed, test numbers on both databases, e2e
    numbers (scenarios, screenshots, problems), the review result, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service (the OpenAI review of the code diff is the
  one exception Jan approved, and only when the key is present);
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint, browser check or review as passed without having seen
  it. Quote the summary lines; list the screenshots. "Should work" is not a result, and a green
  test suite is not proof that a feature works in the browser.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module, sudo mode
  (on by default: `t.sudo()` in a scenario). The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why). Push after every
  commit, together with the updated status in this file: a cloud session can stop at a usage
  limit, and work that is not pushed is lost with its container.
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every function in the inventory exercised end to end on a real running Redmine, with and
  without permissions and on its failure paths; `./.codex/e2e.sh` green; screenshots looked at,
  committed in `docs/e2e/` and listed.
- Review done: your own, and the OpenAI review when the key is present, every finding resolved
  in `docs/reviews/`.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_issue_field_visibility
- Gebruikte branch: master @ 4139400 (2023-08-07) - plugin id redmine_issue_field_visibility, versie 1.1.0
- Upstream: planio-gmbh/redmine_issue_field_visibility - upstream HEAD master @ a1ff152 (2022-06-27)
- Fork t.o.v. upstream: 3 eigen commits (cd3554e alias_method i.p.v. alias_method_chain/SystemStackError, e0c7abf, 4139400 column_content alleen voor Issue), 0 upstream-commits ontbreken (a1ff152 is voorouder van origin/master; planio/4.2 en planio/3.4 hebben 0 commits die niet in master zitten)
- Andere relevante branches: origin/planio/3.2, 3.3, 3.4, 4.2, origin/fix/hide_in_emails (allemaal oud, in master opgenomen of verouderd). Geen migraties, geen Gemfile.

## 1. Werkt out of the box op Redmine 7?   DEELS
Harness `redmine_issue_field_visibility@origin/master` (1006-085855-s2):
- OK bundle, boot (1.1.0), eager load, plugin migrations dev+test
- OK minitest: 8 runs, 42 assertions, 0 failures, 0 errors, 0 skips
- OK smoke: 60/60 zonder serverfout (smoke stelt geen verborgen velden in)

Runtime-check (slot, dev-DB; `estimated_hours` verborgen voor de rol van gebruiker `dev`, issue met 8 h, 0 % gedaan), als `dev`:
- OK kolommen `estimated_hours`, `total_estimated_hours` en filter `estimated_hours` verborgen
- LEK kolom `estimated_remaining_hours` beschikbaar, totaal = 8.0 (nieuw in 7.0: IssueQuery-kolom + totaal met `ESTIMATED_REMAINING_HOURS_SQL`; lib/redmine_issue_field_visibility/patches/issue_query_patch.rb:38-41 voegt alleen `total_estimated_hours` toe, core zelf voegt bij uitgeschakelde estimated_hours ook `estimated_remaining_hours` toe, app/models/issue_query.rb:348-351)
- LEK `GET /issues/<id>.json` met de API key van `dev`: `estimated_hours=8.0, total_estimated_hours=8.0`. Oorzaak: de getter-wrappers (issue_patch.rb:15-20, `if Issue.method_defined?(field)`) worden op Redmine 7 niet geïnstalleerd - gemeten: 0 van de 8 velden gewrapt, want ActiveRecord-attribuutmethodes bestaan nog niet wanneer init.rb draait. De HTML-issuepagina verbergt het veld wel (via `disabled_core_fields`). Of de wrappers op 5.1 wél actief waren hangt af van de laadvolgorde (een eerder geladen plugin die `Issue` instantieert definieert de attribuutmethodes vroeger); niet geverifieerd op 5.1.
- `Version#estimated_hours` geeft 0 (gepatcht), `Version#estimated_remaining_hours` 0.0 in deze seed (versie zonder issues; niet gepatcht, dus bij issues in een versie zichtbaar op de roadmap/versiepagina 7.0 `versions/show.html.erb:26-29`).

## 2. Upstream sync?   UPSTREAM DOOD
planio master (2022-06-27) zit volledig in de fork; upstream heeft niets nieuwers en geen Redmine 6/7-ondersteuning. Geen onderhouden fork gevonden (korte WebSearch).

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 3
- Blokkers (raise): geen.
- Stille breuken (privacy - verborgen velden toch zichtbaar):
  - issue_query_patch.rb:38-41: `estimated_remaining_hours` (kolom, totaal, versiepagina) niet mee verborgen - fix: in `hidden_core_fields` ook `estimated_remaining_hours` toevoegen wanneer `estimated_hours` verborgen is (spiegelt core issue_query.rb:349-350); Version#estimated_remaining_hours idem als version_patch.rb.
  - issue_patch.rb:15-20 / 44-50: getter-wrappers niet actief op R7 (gemeten) -> REST API (show/index), CSV van niet-kolom-attributen en elke code die de getter leest tonen verborgen waarden. Fix vraagt ontwerp: wrappers definiëren zonder `method_defined?`-guard (bv. via `prepend` van een module met `define_method`), of in een `after_initialize`/`to_prepare` na `Issue.define_attribute_methods`.
  - NIEUW in 7.0: webhooks (#29664) renderen core `issues/show.api.rsb` -> zelfde getter-lek richting webhook-ontvangers; journal-details lopen via het gepatchte `Journal#visible_details(user)` (wel afgeschermd).
  - issue_patch.rb:59-71 en journal_patch.rb:24-36: `each_notification` bestaat al lang niet meer in core (5.1 noch 7.0) - dode code, onschuldig.
  - issue_patch.rb:12-13: `reload` wordt vervangen door een methode zonder argumenten; core `Issue#reload(*)` - een aanroep met argumenten (`reload(lock: true)`, `lock!`) zou ArgumentError geven. Core 7.0 doet dat niet op Issue (alleen `@user.reload(lock: true)` in EmailAddressesController); pre-existing risico.
- Gepatchte core-methodes 5.1 vs 7.0 (bestaan nog, zelfde signatuur): `Issue#disabled_core_fields`, `Issue#reload(*)`, `IssueQuery#initialize_available_filters`, `IssueQuery#available_columns`, `IssuesHelper#email_issue_attributes(issue, user, html)`, `Journal#visible_details(user=User.current)`, `QueriesHelper#column_content(column, item)`, `Version#estimated_hours`. `Tracker::CORE_FIELDS` is ongewijzigd.
- Overlap met Redmine 7 core: geen (core kan velden alleen per tracker uitschakelen of per workflow read-only maken, niet per rol verbergen).
- Pairwise (statisch): `IssueQuery#initialize_available_filters` en `#available_columns` ook gepatcht door redmine_itil_priority (alias_method) en redmine_parent_child_filters (prepend, alleen filters). Alfabetisch laadt deze plugin eerst, dus haar alias-ketens staan vóór de prepends - veilig; omgekeerd zou SystemStackError geven. `QueriesHelper#column_content` (alias) - geen andere plugin van deze set. redmine_view_issue_description aliast `Query#columns`/`has_column?` - andere methodes.
- Open werk voor ansif:
  - `estimated_remaining_hours` toevoegen aan de verborgen velden (IssueQuery + Version) - kleine patch, maar wel functioneel werk.
  - Getter-wrappers betrouwbaar maken op R7 (zie boven) en daarna de REST API als beperkte gebruiker hertesten.
  - Beslissen of webhooks gebruikt worden (zelfde lek).

## Branch redmine70-migration
- Niet aangemaakt: geen fix voor een raise nodig; de privacy-lekken vragen functionele wijzigingen (en commits in de plugin-repo werden in deze sessie door de permissie-classifier geweigerd).
- Eindresultaat harness: zie sectie 1.
- Rollback migraties: n.v.t. (geen migraties)


## Aanvulling coordinator
Branch `redmine70-migration` is wel gepusht, als startpunt zonder commits: gelijk aan de gebruikte branch (4139400). Fixes die hierboven als diff staan, zijn nog niet gecommit.

