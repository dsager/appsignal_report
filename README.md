# appsignal_report

`appsignal_report` is a gem that generates reports based on data obtained from
[Appsignal](https://www.appsignal.com), a tool for monitoring of Ruby and 
Elixir applications.

## Status

[![Gem Version](https://badge.fury.io/rb/appsignal_report.svg)](https://badge.fury.io/rb/appsignal_report)
[![Build Status](https://travis-ci.org/dsager/appsignal_report.svg?branch=master)](https://travis-ci.org/dsager/appsignal_report)

## Usage

Use `gem install appsignal_report` to get `appsignal_report` (or add 
`gem 'appsignal_report'` to your Gemfile). That will provide two executables
`appsignal_report_deploy` and `appsignal_report_weekly`, they both support
the same set of options:

```
$ appsignal_report_deploy -h
Usage: APPSIGNAL_API_TOKEN=XXX ./bin/appsignal_report_deploy [options]

Specific options:
    -i, --app-id ID                  Specify Appsignal App Id
    -n, --app-name NAME              Specify a name for the Appsignal App
    -s, --slack WEBHOOK_URL          Post the report to a Slack Webhook

Common options:
    -h, --help                       Show this message
```

The option `--app-id` is the only required one, by default the tool will
output the report data in JSON format to STDOUT. 

## Posting to Slack

`appsignal_report` supports posting formatted messages about the report 
to Slack, instead of printing the raw report data. To do so, you need to 
provide the URL of a 
[Slack webhook](https://api.slack.com/custom-integrations/incoming-webhooks) 
using the CLI option `--slack`:

```
$ APPSIGNAL_API_TOKEN=XXX ./bin/appsignal_report_weekly \
  -app-id XYZ123 \
  -app-name 'back-end' \
  -slack https://hooks.slack.com/services/X/Y/Z
```

This is an example of how the post looks on Slack:

![Slack Post Example](img/slack-post.png?raw=true "Slack Post Example")

## Reports

Currently the gem supports two kinds of reports, a deploy report and a weekly
report.

## Deploy Report

The deploy report pulls metrics for the time around the last deploy recorded on 
AppSignal (1 hour before to 1 hour after). Based on these metrics it calculates
changes in response time, error rate and throughput, possibly caused by the 
deploy. The 20 minutes around the deploy are ignored to account for timeouts or 
slow requests caused by service restarts or cold caches.

This only works if you are using AppSignal's 
[deploy markers](https://docs.appsignal.com/push-api/deploy-marker.html) to
record your deployments.

### Example

```
{
  "title": "AppSignal Deploy Report",
  "last_deploy_time": "2017-08-10 09:47:52 UTC",
  "resolution": "minutely",
  "before": {
    "data_points": 62,
    "error_rate": 0.4675038958657989,
    "response_time": 94.9387856438841,
    "throughput": 32727
  },
  "after": {
    "data_points": 62,
    "error_rate": 0.0733371596199222,
    "response_time": 56.71109484008057,
    "throughput": 31362
  },
  "data_samples_from": "2017-08-10 08:47:00 UTC",
  "data_samples_to": "2017-08-10 10:48:00 UTC",
  "diff": {
    "error_rate": -0.39416673624587667,
    "error_rate_pct": -0.8431303775894644,
    "response_time": -38.22769080380353,
    "response_time_pct": -0.40265620151489834,
    "throughput": -1365,
    "throughput_pct": -0.041708680905674214
  },
  "messages": {
    "info": "The deploy finished at 2017-08-10 09:47:52 UTC",
    "error_rate": "The error rate decreased by 0.39% (from 0.47% to 0.07%, that is a change of -84.31%).",
    "response_time": "The response time decreased by 38.23ms (from 94.94ms to 56.71ms, that is a change of -40.27%).",
    "throughput": "The hourly throughput decreased by 1365.0 req/m (from 32727.0 req/m to 31362.0 req/m, that is a change of -4.17%)."
  }
}
```

## Weekly Report

The weekly report pulls metrics for the last two weeks. Based on these metrics 
it calculates changes in response time, error rate and throughput, comparing one 
week to the other.

### Example

```
{
  "title": "AppSignal Weekly Report",
  "now": "2017-08-14 13:19:15 UTC",
  "one_week_ago": "2017-08-07 13:19:15 UTC",
  "two_weeks_ago": "2017-07-31 13:19:15 UTC",
  "resolution": "hourly",
  "before": {
    "data_points": 168,
    "error_rate": 0.19637939102939866,
    "response_time": 74.6427894180237,
    "throughput": 34611.166666666664
  },
  "after": {
    "data_points": 168,
    "error_rate": 0.06227341986188213,
    "response_time": 61.364840452820985,
    "throughput": 30819.684523809523
  },
  "data_samples_from": "2017-07-31 14:00:00 UTC",
  "data_samples_to": "2017-08-14 13:00:00 UTC",
  "diff": {
    "error_rate": -0.13410597116751655,
    "error_rate_pct": -0.6828922855119783,
    "response_time": -13.277948965202711,
    "response_time_pct": -0.17788655901967856,
    "throughput": -3791.4821428571413,
    "throughput_pct": -0.1095450546169726
  },
  "messages": {
    "info": "Comparing the weeks 2017-07-31-2017-08-07 and 2017-08-07-2017-08-14.",
    "error_rate": "The error rate decreased by 0.13% (from 0.2% to 0.06%, that is a change of -68.29%).",
    "response_time": "The response time decreased by 13.28ms (from 74.64ms to 61.36ms, that is a change of -17.79%).",
    "throughput": "The hourly throughput decreased by 3791.48 req/h (from 34611.17 req/h to 30819.68 req/h, that is a change of -10.95%)."
  }
}
```

## FAQ

### Where do I get an AppSignal API Token?

Every AppSignal user automatically has an API token, which is displayed at the
bottom of [your personal settings page](https://appsignal.com/users/edit).

### Where do I find the AppSignal application ID?

The application ID is part of any appsignal.com URL, as soon as you open an
application. If you look at the example URL
`appsignal.com/devex/sites/XYZ456/web/exceptions`, the application ID is 
`XYZ456`.

### How do I set up a Slack webhook?

Go to this [page](https://my.slack.com/services/new/incoming-webhook) to set up
a Slack webhook. You can specify some settings like user name or an avatar, and
should be provided a webhook URL in the format of 
`https://hooks.slack.com/services/ABC/123/XYZ`.

## Maintainer

- [Devex](https://github.com/orgs/Devex) 
- [Daniel Sager](https://github.com/dsager)

## Contributing

- Fork this repository
- Implement your feature or fix including Tests
- Update the [change log](CHANGELOG.md)
- Commit your changes with a meaningful commit message
- Create a pull request

Thank you!

See the 
[list of contributors](https://github.com/dsager/appsignal-report/contributors).

### Tests

For the whole test suite, run `rake test`.
For individual tests, run 
`ruby -Ilib:spec spec/appsignal_report/version_spec.rb`. 

## License

MIT License, see the [license file](LICENSE).
