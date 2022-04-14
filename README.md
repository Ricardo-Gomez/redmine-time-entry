## Description
Small script to create time entries on Redmine, it only logs for weekdays when there are not entries logged already.

## Setup
- add execute permission
```shell
$ chmod +x ./time_entry.sh
```

- export REDMINE_KEY env variable
```shell
$ export REDMINE_KEY=$yourKey
```

## Usage
```shell
$ ./time_entry.sh -i $issueId -d 5 -u $yourRedmineUrl
```

## Options
- -i Required, the task you are assigned on.
- -u Required, your Redmine URL.
- -d Optional, number of days to fill up, if the value is negative eg. -5 it’ll log time entries for the previous 5 days, otherwise the next 5 days, starting from the current date, if omitted it will log for the current day.