{
  _config+:: {
    system: {
      namespace: 'kube-system',
      user: 'admin-user',
      ingress: {
        values: {},
      },
      dashboard: {
        values: {},
      },
      metrics: {
        values: {
          defaultArgs: [
            '--cert-dir=/tmp',
            '--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname',
            '--kubelet-use-node-status-port',
            '--metric-resolution=15s',
          ],
        },
      },
    },
  },
}
