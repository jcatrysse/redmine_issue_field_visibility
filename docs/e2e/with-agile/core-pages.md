# core-pages

Run 2026-10-07T19:37:49.977Z against http://127.0.0.1:3001.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](core-pages-manager-issue-list.png) | manager | `/projects/e2e-project/issues` | manager: /projects/e2e-project/issues answers 200 |
| ![](core-pages-manager-bulk-edit.png) | manager | `/issues/bulk_edit?ids[]=1` | manager: /issues/bulk_edit?ids[]=1 answers 200 |
| ![](core-pages-manager-version.png) | manager | `/versions/1` | manager: /versions/1 answers 200 |
| ![](core-pages-manager-project-settings.png) | manager | `/projects/e2e-project/settings` | manager: /projects/e2e-project/settings answers 200 |
| ![](core-pages-reporter-bulk-edit-refused.png) | reporter | `/issues/bulk_edit?ids[]=1` | reporter: /issues/bulk_edit?ids[]=1 answers 403 |
| ![](core-pages-reporter-issue.png) | reporter | `/issues/1` | reporter: /issues/1 answers 200 |
| ![](core-pages-reporter-settings-refused.png) | reporter | `/projects/e2e-project/settings` | reporter: /projects/e2e-project/settings answers 403 |
| ![](core-pages-outsider-private-refused.png) | outsider | `/projects/e2e-private/issues` | outsider: /projects/e2e-private/issues answers 403 |
| ![](core-pages-reporter-issue-list.png) | reporter | `/projects/e2e-project/issues?set_filter=1&c[]=subject&c[]=assigned_to&c[]=estimated_hours&c[]=estimated_remaining_hours&t[]=estimated_hours` | Reporter: hidden columns left out of the issue list (, #, Subject, ) |
| ![](core-pages-manager-agile-board.png) | manager | `/projects/e2e-project/agile/board` | Manager: the agile board (redmine_agile) answers 200 |
