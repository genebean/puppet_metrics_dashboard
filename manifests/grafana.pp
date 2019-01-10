# @summary Install and configure Grafana
#
# Install and configure Grafana. This work is broken out into its own class
# because it requires the InfluxDB service to be running before it can even
# start doing its thing.
#
# @api private
class puppet_metrics_dashboard::grafana {
  if $puppet_metrics_dashboard::use_dashboard_ssl {
    $grafana_cfg = {
      server => {
        http_port => $puppet_metrics_dashboard::grafana_http_port,
        protocol  => 'https',
        cert_file => $puppet_metrics_dashboard::dashboard_cert_file,
        cert_key  => $puppet_metrics_dashboard::dashboard_cert_key,
      },
    }

    file {
      default:
        ensure  => present,
        owner   => 'grafana',
        mode    => '0400',
        require => Package['grafana'],
        notify  => Service['grafana-server'],
        before  => Service['grafana-server'],
      ;
      $puppet_metrics_dashboard::dashboard_cert_file:
        source  => "${facts['puppet_sslpaths']['certdir']['path']}/${facts['clientcert']}.pem",
      ;
      $puppet_metrics_dashboard::dashboard_cert_key:
        source  => "${facts['puppet_sslpaths']['privatekeydir']['path']}/${facts['clientcert']}.pem",
      ;
    }
  } else {
    $grafana_cfg = {
      server    => {
        http_port => $puppet_metrics_dashboard::grafana_http_port,
      },
    }
  }

  class { 'grafana':
    install_method      => 'repo',
    manage_package_repo => false,
    version             => $puppet_metrics_dashboard::grafana_version,
    cfg                 => $grafana_cfg,
    require             => Service[$puppet_metrics_dashboard::influx_db_service_name],
    notify              => Exec['update Grafana admin password'],
  }

  $_uri = $puppet_metrics_dashboard::use_dashboard_ssl ? {
    true    => 'https',
    default => 'http',
  }

  exec { 'update Grafana admin password':
    path        => '/usr/bin',
    command     => @("CHANGE_GRAFANA_PW"),
      curl -X PUT -H "Content-Type: application/json" -d '{
        "oldPassword": "${puppet_metrics_dashboard::grafana_old_password}",
        "newPassword": "${puppet_metrics_dashboard::grafana_password}",
        "confirmNew": "${puppet_metrics_dashboard::grafana_password}"
      }' ${_uri}://admin:${puppet_metrics_dashboard::grafana_old_password}@localhost:${puppet_metrics_dashboard::grafana_http_port}/api/user/password
      | CHANGE_GRAFANA_PW
    cwd         => '/usr/share/grafana',
    refreshonly => true,
  }
}
