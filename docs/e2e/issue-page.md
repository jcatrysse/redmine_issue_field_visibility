# issue-page

Run 2026-10-06T20:31:14.168Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](issue-page-manager.png) | manager | `/issues/1` | Manager (no hidden fields): assignee, category, dates, estimated time, description and the estimate change in the history |
| ![](issue-page-manager-form.png) | manager | `/issues/1/edit` | Manager: the edit form has assignee, category, dates and estimated time |
| ![](issue-page-reporter.png) | reporter | `/issues/1` | Reporter (six fields hidden): no assignee, category, dates, estimated time, description; the history keeps the note, not the estimate change |
| ![](issue-page-reporter-new.png) | reporter | `/projects/e2e-project/issues/new` | Reporter: the new issue form without the hidden fields |
| ![](issue-page-reporter-created.png) | reporter | `/issues/8` | Reporter: the issue is created; the hidden fields are not shown on it |
| ![](issue-page-forged-ignored.png) | manager | `/issues/9` | Manager: issue #9, posted by the reporter with estimated_hours=77, has no estimated time |
| ![](issue-page-outsider.png) | outsider | `/issues/1` | Outsider (no membership) sees the public issue as a non member: Non member hides nothing |
