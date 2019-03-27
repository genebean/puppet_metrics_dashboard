# @summary Manages services
#
# Manages services
#
# @api private
class puppet_metrics_dashboard::service {
  service { $puppet_metrics_dashboard::influx_db_service_name:
    ensure  => running,
    enable  => true,
    require => Package['influxdb'],
  }

  http_conn_validator { 'influxdb-conn-validator' :
    host        => 'localhost',
    port        => 8086,
    use_ssl     => false,
    test_url    => '/ping?verbose=true',
    verify_peer => false,
    try_sleep   => 10,
    require     => Service[$puppet_metrics_dashboard::influx_db_service_name],
  }

  if $puppet_metrics_dashboard::enable_chronograf {
    service { 'chronograf':
      ensure  => running,
      enable  => true,
      require => [
        Package['chronograf'],
        Service[$puppet_metrics_dashboard::influx_db_service_name]
      ],
    }
  }

  if $puppet_metrics_dashboard::enable_kapacitor {
    service { 'kapacitor':
      ensure  => running,
      enable  => true,
      require => [
        Package['kapacitor'],
        Service[$puppet_metrics_dashboard::influx_db_service_name]
      ],
    }
  }
}
