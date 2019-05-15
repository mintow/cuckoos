Cuckoo Reminder
==========

[Plugin page on redmine.org](http://www.redmine.org/plugins/cuckoos)

Compatible with redmine 3.4 (on branch remotes/origin/3.4-stable)

The cuckoos plugin provides a powerful way to automatic send email reminder
for every project & every tracker & every user with web interface.

## Features:
 - Support to select one or multi-type of tracker
 - Four types of trigger cycle: daily, weekly, monthly, oneshot
 - Four types of user: author, assignee, watcher, user in custom field
 - Also can specify "other user" which can be anyone of the project members
 - Two types of email body: a single issue and a issue package
 - Can insert a tips in the subject of a issue package email
 - Have a "Send now" button to trigger a cuckoo any time you want
 - Can be a timed task triggered by the crontab
 - Configure permissions based on roles
 - Register as a project module

## Screenshots
### The list of cuckoos:

### The interface of edit & new a cuckoo:

### A cuckoo email of a single issue:

### A cuckoo email of a issue package:

## Installation

1. Clone this repository into ```redmine/plugins/cuckoos```
2. Install dependencies and migrate database
```console
cd redmine/
bundle install
RAILS_ENV=production rake redmine:plugins:migrate
```

## Configuration
* Activate `Manage cuckoos` permission in "Administration -> Roles and permissions"
* Activate `Cuckoos` module in project settings
* Set cronjob, after that you need restart cron daemon:
```
$ crontab -e
# Trigger cuckoos at 08:00 every day.
0 8 * * * cd redmine/ && rake redmine:reminder_all_cuckoos RAILS_ENV="production"
```

## Uninstall

First migrate plugin, then remove plugin files.
```console
$ cd /path/to/redmine
$ rake redmine:plugins:migrate NAME=cuckoos VERSION=0 RAILS_ENV="production"
$ rm -rf plugins/cuckoos
```

## License

Cuckoo Reminder is released under the GNU GENERAL PUBLIC LICENSE Version 3.
