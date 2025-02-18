(import 'system/system.libsonnet') +
(import 'monitoring/monitoring.libsonnet') +
{
  _config+: {
    system+: {
      metrics+: {
        values+: {
          defaultArgs+: [
            '--kubelet-insecure-tls',
          ],
        },
      },
    },
    monitoring+: {
      kubePrometheus+: {
        mixins: (import 'kube-prometheus/addons/node-ports.libsonnet')
                + (import 'kube-prometheus/addons/strip-limits.libsonnet'),
      },
    },
  },
}
