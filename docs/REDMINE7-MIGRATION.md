# Redmine 7 migration: redmine_issue_field_visibility

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_issue_field_visibility` |
| GEOxyz runs today | `master` |
| Upstream | planio-gmbh/redmine_issue_field_visibility (master @ a1ff152, 2022-06-27, voorouder van master) |
| Runs on Redmine 7 as is | DEELS |
| Upstream sync | UPSTREAM DOOD |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 3 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `4139400` |

## Already on this branch

- nothing: the branch equals the branch GEOxyz runs today.

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Priority items**

1. Hide estimated_remaining_hours (column, total, version page) together with estimated_hours.
2. Make the getter wrappers work on Redmine 7 (they are not installed today, so the REST API returns hidden values).
3. Redmine 7 webhooks (#29664) send the core issue API payload (app/views/issues/show.api.rsb, rendered as the webhook owner) and bypass plugin hooks and patches on controllers/views. Check whether this plugin changes what an issue shows, hides or adds, and make webhook payloads consistent with that.

**Open items from the analysis** (Dutch; where they repeat a priority item, the priority item wins)

4. issue_query_patch.rb: estimated_remaining_hours mee verbergen (kolom, totaal) + Version#estimated_remaining_hours
5. issue_patch.rb:15-20 getter-wrappers worden op R7 niet geinstalleerd (method_defined? false bij init) -> REST API/webhooks tonen verborgen velden; herontwerpen (prepend/define_method of na define_attribute_methods)
6. Webhooks (7.0) renderen show.api.rsb -> zelfde lek

**Checks**

7. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
8. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).

## GEOxyz changes to review or re-apply

These GEOxyz commits are on the branch GEOxyz runs today and therefore on this branch. Review each one against the code it now sits on (upstream merges and Redmine 7 core): drop it if upstream or core now does the same, rewrite it if it is not up to the quality rules below (tests, I18n, security, portability), keep it otherwise. Record the verdict per commit in this file.

| commit | date | subject |
|---|---|---|
| `4139400` | 2023-08-07 | The column_content_with_ifv method expects an Issue instance but received a Project instance. We need to ensure that this method is only invoked with Issue objects. |
| `e0c7abf` | 2023-08-07 | Correction on wrong file move on my side |
| `cd3554e` | 2023-08-07 | * Resolved issue: `SystemStackError (stack level too deep)`     Converted all methods to use `alias_method` * Removal of `setup` method * Renamed `History.txt` to `CHANGELOG.md` |

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- None known. Add here what the session finds.

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```
On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow.

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline**: set up Redmine 7.0-stable-GEOxyz and run the plugin's tests on PostgreSQL and
   on MariaDB (see "How to test"). Write the numbers here before you change anything.
3. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
4. **Work list**: then the numbered list, in order. One concern per commit.
5. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
6. **Browser**: start a Redmine 7 with this plugin, exercise every feature as admin and as a
   normal user with and without the plugin's permissions, and save screenshots (before on 5.1 or
   the old branch, after on 7.0) where behaviour or layout matters.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
   settings, cron, files, removed features) goes into the section "After the upgrade".
9. **Finish**: update "Status" and the work list in this file, push `redmine70-migration`, and
   report: what changed, test numbers on both databases, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service;
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint or browser check as passed without having seen it.
  Quote the summary lines. "Should work" is not a result.
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
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module.
  The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why).
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every feature verified by hand on Redmine 7; screenshots listed.
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

