local kp =
  (import './config.libsonnet') +
  (import 'kube-prometheus/main.libsonnet') +
  {
    local c = $._config.monitoring,
    values+:: {
      common+: {
        namespace: c.namespace,
      },
    } + c.kubePrometheus.mixins,
  };


(import './config.libsonnet') + {
  local c = $._config.monitoring,
  kubePrometheus: if !c.enabled then {} else
    { 'setup/0namespace-namespace': kp.kubePrometheus.namespace }
    + {
      ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
      for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
    }
    // serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
    + { 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor }
    + { 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule }
    + { 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule }
    + { ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) }
    + { ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) }
    + { ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
    + { ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) }
    + { ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
    + { ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) }
    + { ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) }
    + { ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) },
}
