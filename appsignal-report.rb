#!/usr/bin/env ruby

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Script to pull some data from Appsignal
#
#
# Usage:
#         ./appsignal-report.rb --help
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'uri'
require 'net/http'
require 'json'
require 'optparse'

require_relative 'lib/appsignal_weekly_report'
require_relative 'lib/appsignal_deploy_report'

options = { type: :weekly, format: :text, app_id: nil }
parser = OptionParser.new do |parser|
  parser.banner = 'Usage: ./appsignal-report.rb [options]'
  parser.separator ''
  parser.separator 'Specific options:'
  parser.on('--app-id ID',
            String,
            'Specify Appsignal App Id') do |id|
    options[:app_id] = id
  end
  parser.on('--type TYPE',
            %i(weekly deploy),
            'Select report type (weekly, deploy), default is weekly') do |t|
    options[:type] = t
  end
  parser.on('--format FORMAT',
            %i(text json),
            'Select output format (text, json), default is text') do |f|
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

report_class =
  case options[:type]
  when :weekly
    AppsignalWeeklyReport
  when :deploy
    AppsignalDeployReport
  end

report = report_class.new(
  api_token: ENV['APPSIGNAL_API_TOKEN'],
  app_id: options[:app_id]
)

case options[:format]
when :text
  report.print
when :json
  report.generate
  puts report.report.to_json
end
