# mail

Run 2026-10-06T20:00:52.310Z against http://127.0.0.1:3001.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](mail-manager-mail.png) | manager | `/issues/1` | The update mail as manager received it: assignee header and line, category, estimate change and description |
| ![](mail-reporter-mail.png) | manager | `/issues/1` | The update mail as reporter received it: no assignee header or line, no category, no estimate change, no description; the note is there |

## Problems

- reporter mail: assignee header
- reporter mail: description
