local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);

local defaults = {
  namespace:: error 'must provide namespace',
};

function(params) {
  local c = self,
  _config:: defaults + params,

  helm: t.k8s.patchKubernetesObjects(h.template('kubernetes-dashboard', './charts/kubernetes-dashboard', {
    namespace: c._config.namespace,
    values: c._config.helm,
  }), {
    metadata+: {
      namespace: c._config.namespace,
    },
  }),

  mixins: {
    namespace: k.core.v1.namespace.new(c._config.namespace),
  },
}
