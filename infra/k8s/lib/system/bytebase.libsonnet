local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/0.9/main.libsonnet';
local cp = import 'github.com/jsonnet-libs/cloudnative-pg-libsonnet/1.25.0/main.libsonnet';

local defaults = {
  namespace:: error 'must provide a namespace',
  domain:: error 'must provide a domain',
};

function(params) {
  local c = self,
  _config:: defaults + params,

  helm: h.template('bytebase', './charts/bytebase', {
    namespace: c._config.namespace,
    values: c._config.helm {
      bytebase: {
        option: {
          'external-url': 'https://bytebase.' + c._config.domain,
          'disable-sample': true,
          externalPg: {
            pgHost: 'postgresql.bytebase.svc.cluster.local',
            pgPort: 5432,
            pgUsername: 'bytebase',
            pgDatabase: 'bytebase',
            existingPgPasswordSecret: 'postgresql-auth',
            existingPgPasswordSecretKey: 'password',
          },
        },
      },
    },
  }),

  mixins: {
    namespace: k.core.v1.namespace.new(c._config.namespace),

    passwordGenerator:
      local p = es.generators.v1alpha1.password;

      p.new('default')
      + p.metadata.withNamespace(c._config.namespace)
      + p.spec.withAllowRepeat(true)
      + p.spec.withLength(32)
      + p.spec.withDigits(5)
      + p.spec.withSymbols(5)
      + p.spec.withSymbolCharacters('-_$@'),

    ingress:
      local i = k.networking.v1.ingress;

      i.new('bytebase')
      + i.metadata.withNamespace(c._config.namespace)
      + i.metadata.withAnnotations({
        'cert-manager.io/cluster-issuer': 'root-ca',
        'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
      })
      + i.spec.withIngressClassName('nginx')
      + i.spec.withRules(
        k.networking.v1.ingressRule.withHost('bytebase.' + c._config.domain)
        + k.networking.v1.ingressRule.http.withPaths(
          k.networking.v1.httpIngressPath.withPath('/')
          + k.networking.v1.httpIngressPath.withPathType('Prefix')
          + k.networking.v1.httpIngressPath.backend.service.withName('bytebase-entrypoint')
          + k.networking.v1.httpIngressPath.backend.service.port.withNumber(80)
        )
      )
      + i.spec.withTls(
        k.networking.v1.ingressTLS.withHosts('bytebase.' + c._config.domain)
        + k.networking.v1.ingressTLS.withSecretName('bytebase.' + c._config.domain + '-tls')
      ),

    postgresql: {
      secrets: {
        auth:
          local e = es.nogroup.v1beta1.externalSecret;

          e.new('postgresql-auth')
          + e.metadata.withNamespace(c._config.namespace)
          + e.spec.target.withName('postgresql-auth')
          + e.spec.target.template.withData({
            username: 'bytebase',
            password: '{{ .password }}',
          })
          + e.spec.withDataFrom(
            e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
            + e.spec.dataFrom.sourceRef.generatorRef.withName('default'),
          ),

        cluster:
          local pc = cp.postgresql.v1.cluster;

          pc.new('bytebase')
          + pc.metadata.withNamespace($._config.namespace)
          + pc.spec.withInstances(1)
          + pc.spec.storage.withSize('1Gi')
          + pc.spec.bootstrap.initdb.withDatabase('bytebase')
          + pc.spec.bootstrap.initdb.withOwner('bytebase')
          + pc.spec.bootstrap.initdb.secret.withName('postgresql-auth')
          + pc.spec.managed.services.withDisabledDefaultServices(['ro', 'r'])
          + pc.spec.managed.services.withAdditional(
            pc.spec.managed.services.additional.withSelectorType('rw')
            + pc.spec.managed.services.additional.serviceTemplate.metadata.withName('postgresql')
          )
          + pc.spec.postgresql.withParameters({
            timezone: 'Europe/Paris',
          }),
      },
    },
  },
}
