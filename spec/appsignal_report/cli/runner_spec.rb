require 'spec_helper'

describe AppsignalReport::CLI::Runner do
  let(:instance) { AppsignalReport::CLI::Runner.new(options) }

  describe '#run' do
    let(:report_mock) { Minitest::Mock.new }

    describe 'when no slack webhook url is provided' do
      let(:options) { {} }
      it 'generates the report and prints json' do
        report_mock.expect(:generate, nil)
        instance.stub(:report, report_mock) do
          instance.stub(:print_json, :json) do
            assert_equal instance.run, :json
          end
        end
      end
    end

    describe 'when a slack webhook url is provided' do
      let(:options) { { slack_webhook: 'foobar' } }
      it 'generates the report and posts to slack' do
        report_mock.expect(:generate, nil)
        instance.stub(:report, report_mock) do
          instance.stub(:post_to_slack, :slack) do
            assert_equal instance.run, :slack
          end
        end
      end
    end
  end

  describe '#report' do
    describe 'when there is no report type' do
      let(:options) { {} }
      it 'raises an argument error' do
        assert_raises(ArgumentError) { instance.report }
      end
    end

    describe 'when the report type is invalid' do
      let(:options) { { type: :foobar } }
      it 'raises an argument error' do
        assert_raises(ArgumentError) { instance.report }
      end
    end

    describe 'when the report type is :deploy' do
      let(:options) do
        {
          api_token: 's3cr3t',
          app_id: 'abc123',
          app_name: 'my app',
          type: :deploy,
        }
      end
      it 'returns the deploy report' do
        @report = instance.report
        assert_equal @report.class, AppsignalReport::DeployReport
        assert_equal @report.api_token, 's3cr3t'
        assert_equal @report.app_id, 'abc123'
        assert_equal @report.app_name, 'my app'
      end
    end

    describe 'when the report type is :weekly' do
      let(:options) do
        {
          api_token: 's3cr3t',
          app_id: 'abc123',
          app_name: 'my app',
          type: :weekly,
        }
      end
      it 'returns the deploy report' do
        @report = instance.report
        assert_equal @report.class, AppsignalReport::WeeklyReport
        assert_equal @report.api_token, 's3cr3t'
        assert_equal @report.app_id, 'abc123'
        assert_equal @report.app_name, 'my app'
      end
    end
  end
end
