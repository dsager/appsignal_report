#!/usr/bin/env ruby

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Script to generate a report based on the last Appsignal deploy marker.
#
# The script will obtain the time of the last deploy from AppSignal and then
# pull metrics for the time around that deploy (1 hour before to 1 hour after).
# Based on these metrics it will calculate changes in response time, error rate
# and throughput, possibly caused by the deploy.
# The 20 minutes around the deploy are ignored to account for errors or slow
# requests caused by service restarts or cold caches.
#
# Pull up the help message to learn about the usage of this script:
#
#         ./deploy-report.rb --help
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'uri'
require 'net/http'
require 'json'
require 'optparse'

require_relative 'lib/appsignal_deploy_report'

options = { format: :text, app_id: nil }
parser = OptionParser.new do |parser|
  parser.banner = 'Usage: APPSIGNAL_API_TOKEN=XXX ./deploy-report.rb [options]'
  parser.separator ''
  parser.separator 'Specific options:'
  parser.on('--app-id ID',
            String,
            'Specify Appsignal App Id') do |id|
    options[:app_id] = id
  end
  parser.on('--format FORMAT',
            %i(text json slack),
            'Select output format (text, json, slack), default is text') do |f|
    options[:format] = f.to_sym
  end
  parser.separator ''
  parser.separator 'Common options:'
  parser.on_tail('-h', '--help', 'Show this message') do
    puts parser
    exit
  end
end
parser.parse!

report = AppsignalDeployReport.new(
  api_token: ENV['APPSIGNAL_API_TOKEN'],
  app_id: options[:app_id]
)

case options[:format]
when :text
  report.print
when :json
  report.generate
  puts report.report.to_json
when :slack
  report.generate
  puts report.slack_message.to_json
end
