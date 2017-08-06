#!/usr/bin/env ruby

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Script to pull some data from Appsignal
#
#
# Usage:
#
#   APPSIGNAL_API_TOKEN=XXX APPSIGNAL_APP_ID=YYY ./appsignal-report.rb
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'uri'
require 'net/http'
require 'json'

require_relative 'lib/appsignal_weekly_report'
require_relative 'lib/appsignal_deploy_report'

weekly_report = AppsignalWeeklyReport.new(
  api_token: ENV['APPSIGNAL_API_TOKEN'],
  app_id: ENV['APPSIGNAL_APP_ID'],
)
weekly_report.print

deploy_report = AppsignalDeployReport.new(
  api_token: ENV['APPSIGNAL_API_TOKEN'],
  app_id: ENV['APPSIGNAL_APP_ID'],
)
deploy_report.print
