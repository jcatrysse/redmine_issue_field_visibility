Redmine Issue Field Visibility Plugin ![Build Status](https://github.com/planio-gmbh/redmine_issue_field_visibility/workflows/Test%20with%20Redmine/badge.svg?branch=master)
=====================================

This plugin allows to hide certain core fields from specific roles.

The fields you can hide are `assigned to`, `category`, `start date`, `due
date`, `target version`, `estimated time`, `description` and `priority`.
Hiding the estimated time also hides the total and remaining estimated time.

A hidden field is left out of the issue page and forms, the issue list
(columns, filters, totals, CSV), the history, the issue PDF and Atom feed,
the version page, issue mails (attributes, the `X-Redmine-Issue-Assignee`
header and the description), REST API responses and, on Redmine 7, webhook
payloads (rendered for the webhook owner). Redmine's own calculations (parent
dates, done ratio, totals) keep using the real values.

Development of this plugin has been sponsored by
[SDZeCOM GmbH & Co. KG](http://www.sdzecom.de).


Installation
------------

[Standard Redmine plugin installation instructions](https://redmine.org/projects/redmine/wiki/Plugins#Installing-a-plugin) apply.


Usage
-----

Use the plugin settings (_Administration_ / _Plugins_ , find the row for this plugin and click _Configure_) to select which fields you want to hide for which roles.

Author & License
----------------

Created by Jens Krämer for [Planio GmbH](https://plan.io)

The Issue Field Visibility plugin for Redmine is free software: you can
redistribute it and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

The Issue Field Visibility plugin for Redmine is distributed in the hope that
it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
the plugin. If not, see [www.gnu.org/licenses](https://www.gnu.org/licenses/).

