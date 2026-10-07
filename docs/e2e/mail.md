# mail

Run 2026-10-07T20:12:40.240Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](mail-manager-mail.png) | manager | `/issues/1` | The update mail as manager received it: assignee header and line, category, estimate change and description |
| ![](mail-reporter-mail.png) | manager | `/issues/1` | The update mail as reporter received it: no assignee header or line, no category, no estimate change, no description; the note is there |
