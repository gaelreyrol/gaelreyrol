local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);

local defaults = {
  namespace:: error 'must provide namespace',
};

function(params) {
  local c = self,
  _config:: defaults + params,

  helm: t.k8s.patchKubernetesObjects(h.template('polaris', './charts/polaris', {
    namespace: c._config.namespace,
    values: {
      templateOnly: true,
      dashboard+: {
        replicas: 1,
      },
    } + c._config.helm,
  }), {
    metadata+: {
      namespace: c._config.namespace,
    },
  }),

  mixins: {},
}
