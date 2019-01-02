require 'spec_helper'

describe 'puppet_metrics_dashboard::dashboards::graphite' do
  on_supported_os(facterversion: '3.7').each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(pe_server_version: '2017.2')
      end

      let(:pre_condition) do
        <<-PRE_COND
          class {'puppet_metrics_dashboard':
            add_dashboard_examples => false,
            influxdb_database_name => ['puppet_metrics','telegraf','graphite'],
            grafana_password       => 'puppetlabs',
          }
        PRE_COND
      end

      it 'should contain Grafana_dashboard[Graphite Puppetserver Performance]' do
        is_expected.to contain_grafana_dashboard('Graphite Puppetserver Performance').with(
          grafana_url: 'http://localhost:3000',
          grafana_user: 'admin',
          grafana_password: 'puppetlabs',
          require: 'Grafana_datasource[influxdb_graphite]',
        )
      end
    end
  end
end
