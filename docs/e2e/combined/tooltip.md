# tooltip

Run 2026-10-07T20:13:56.291Z against http://127.0.0.1:3002.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](tooltip-admin-gantt.png) | admin | `/projects/e2e-project/issues/gantt` | admin: gantt tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-admin-calendar.png) | admin | `/projects/e2e-project/issues/calendar` | admin: calendar tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-manager-gantt.png) | manager | `/projects/e2e-project/issues/gantt` | manager: gantt tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-manager-calendar.png) | manager | `/projects/e2e-project/issues/calendar` | manager: calendar tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-outsider-gantt.png) | outsider | `/projects/e2e-project/issues/gantt` | outsider: gantt tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-outsider-calendar.png) | outsider | `/projects/e2e-project/issues/calendar` | outsider: calendar tooltip with dates and assignee "Bug #1: E2E assigned issueProject: E2E projectStatus: NewStart date: 10/07/2026Due date: 10/14/2026Assignee: Manager E2EPriority: Normal" |
| ![](tooltip-reporter-gantt.png) | reporter | `/projects/e2e-project/issues/gantt` | Reporter (assignee and dates hidden): gantt tooltip "Bug #1: E2E assigned issueProject: E2E projectStatus: NewPriority: Normal" |
| ![](tooltip-reporter-calendar.png) | reporter | `/projects/e2e-project/issues/calendar` | Reporter (assignee and dates hidden): calendar tooltip "Bug #1: E2E assigned issueProject: E2E projectStatus: NewPriority: Normal" |
| ![](tooltip-outsider-private-refused.png) | outsider | `/projects/e2e-private/issues/gantt` | Outsider: the gantt of the private project stays refused |

## Problems

- /projects/e2e-project/issues/calendar as admin: 404 image /assets/plugin_assets/redmineup/bullet_end.png
- /projects/e2e-project/issues/calendar as admin: 404 image /assets/plugin_assets/redmineup/bullet_go.png
- /projects/e2e-project/issues/calendar as admin: 404 image /assets/plugin_assets/redmineup/bullet_diamond.png
- /projects/e2e-project/issues/calendar as manager: 404 image /assets/plugin_assets/redmineup/bullet_go.png
- /projects/e2e-project/issues/calendar as manager: 404 image /assets/plugin_assets/redmineup/bullet_diamond.png
- /projects/e2e-project/issues/calendar as manager: 404 image /assets/plugin_assets/redmineup/bullet_end.png
- /projects/e2e-project/issues/calendar as outsider: 404 image /assets/plugin_assets/redmineup/bullet_go.png
- /projects/e2e-project/issues/calendar as outsider: 404 image /assets/plugin_assets/redmineup/bullet_end.png
- /projects/e2e-project/issues/calendar as outsider: 404 image /assets/plugin_assets/redmineup/bullet_diamond.png
- /projects/e2e-project/issues/calendar as reporter: 404 image /assets/plugin_assets/redmineup/bullet_go.png
- /projects/e2e-project/issues/calendar as reporter: 404 image /assets/plugin_assets/redmineup/bullet_diamond.png
- /projects/e2e-project/issues/calendar as reporter: 404 image /assets/plugin_assets/redmineup/bullet_end.png
