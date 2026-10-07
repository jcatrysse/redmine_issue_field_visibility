# Before the switch to prepend: redmine_agile + this plugin (alias_method chains)

Redmine 7.0-stable-GEOxyz, PostgreSQL 16, `start_server.sh` with `RMP_EXTRA_PLUGINS=redmine_agile@redmine70-migration`, plugin at `0c661cd`: `redmine:load_default_data` already fails on the first issue query:

```
rake aborted!
SystemStackError: stack level too deep (SystemStackError)
plugins/redmine_issue_field_visibility/lib/redmine_issue_field_visibility/patches/issue_query_patch.rb:18:in `initialize_available_filters_with_ifv'
plugins/redmine_agile/lib/redmine_agile/patches/issue_query_patch.rb:62:in `initialize_available_filters'
plugins/redmine_issue_field_visibility/lib/redmine_issue_field_visibility/patches/issue_query_patch.rb:18:in `initialize_available_filters_with_ifv'
plugins/redmine_agile/lib/redmine_agile/patches/issue_query_patch.rb:62:in `initialize_available_filters'
```
