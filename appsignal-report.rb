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

require 'date'

require_relative 'lib/appsignal_report'

report = AppsignalReport.new
