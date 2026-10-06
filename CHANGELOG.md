== 1.2.0 2026-10-06

* Redmine 7 (Rails 8.1) support; still runs on Redmine 5.1
* Hide the estimated remaining time column and total, and the estimated and
  remaining time on the version page and in the version API
* Leave hidden fields out of REST API responses (issue show, list, create)
  and Redmine 7 webhook payloads; the getter wrappers had not been active
  since 1.1.0
* Leave a hidden description out of the issue page, PDF and Atom feed, and
  hidden fields out of issue mail headers and body
* Compute the hidden fields again when an issue changes project
* Issue#reload accepts its arguments again (issue.lock!)

== 1.1.0 2023-08-07

* Author: Jan Catrysse
* Resolved issue: `SystemStackError (stack level too deep)`  
    Converted all methods to use `alias_method`  
* Removal of `setup` method
* Renamed `History.txt` to `CHANGELOG.md`

== 1.0.1 2016-03-12

* fixes issue with hiding assigned_to

== 1.0.0 2015-11-06

* Initial release
