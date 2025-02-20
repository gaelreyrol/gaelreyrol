local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);

local defaults = {
  namespace:: error 'must provide namespace',
  credentials:: error 'must provide credentials',
  token:: error 'must provide token',
};

function(params) {
  local c = self,
  _config:: defaults + params,

  helm: h.template('connect', './charts/connect', {
    namespace: c._config.namespace,
    values: c._config.helm {
      connect+: {
        credentials: c._config.credentials,
        serviceType: 'ClusterIP',
      },
      operator+: {
        create: true,
        token: {
          value: c._config.token,
        },
      },
    },
  }),

  mixins: {
    namespace: k.core.v1.namespace.new(c._config.namespace),
  },
}
