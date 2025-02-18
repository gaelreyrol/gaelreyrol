{
  _config+:: {
    monitoring: {
      enabled: true,
      namespace: 'monitoring',
      kubePrometheus: {
        mixins: {},
      },
    },
  },
}
