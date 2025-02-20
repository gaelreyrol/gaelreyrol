local bytebase = import './bytebase.libsonnet';
local certManager = import './cert-manager.libsonnet';
local cloudnativePG = import './cloudnative-pg.libsonnet';
local core = import './core.libsonnet';
local externalSecrets = import './external-secrets.libsonnet';
local ingressNginx = import './ingress-nginx.libsonnet';
local kubernetesDashboard = import './kubernetes-dashboard.libsonnet';
local metricsServer = import './metrics-server.libsonnet';
local onepassword = import './onepassword.libsonnet';
local polaris = import './polaris.libsonnet';

local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);

{
  values:: {
    system: {
      core: {
        user: 'admin-user',
        namespace: 'kube-system',
      },
      ingressNginx: {
        enabled: false,
        namespace: 'ingress-nginx',
        helm+: {},
      },
      kubernetesDashboard: {
        enabled: false,
        namespace: 'kubernetes-dashboard',
        helm+: {},
      },
      metricsServer: {
        enabled: false,
        namespace: 'kube-system',
        helm+: {},
      },
      certManager: {
        enabled: false,
        namespace: 'cert-manager',
        helm+: {},
      },
      polaris: {
        enabled: false,
        namespace: 'polaris',
        helm+: {},
      },
      onepassword: {
        enabled: true,
        namespace: 'onepassword',
        helm+: {},
      },
      externalSecrets: {
        enabled: false,
        namespace: 'external-secrets',
        helm+: {},
      },
      bytebase: {
        enabled: false,
        namespace: 'bytebase',
        helm+: {},
      },
      cloudnativePg: {
        enabled: false,
        namespace: 'cnpg',
        helm+: {},
      },
    },
  },

  mixins: {
    core: core($.values.system.core),

    [if $.values.system.ingressNginx.enabled then 'ingressNginx']: ingressNginx($.values.system.ingressNginx),

    [if $.values.system.kubernetesDashboard.enabled then 'kubernetesDashboard']: kubernetesDashboard($.values.system.kubernetesDashboard),

    [if $.values.system.metricsServer.enabled then 'metricsServer']: metricsServer($.values.system.metricsServer),

    [if $.values.system.certManager.enabled then 'certManager']: certManager($.values.system.certManager),

    [if $.values.system.polaris.enabled then 'polaris']: polaris($.values.system.polaris),

    [if $.values.system.onepassword.enabled then 'onepassword']: onepassword($.values.system.onepassword) + {
      [if $.values.system.externalSecrets.enabled then 'externalSecrets']: {
        local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/0.9/main.libsonnet',

        clusterSecretStore:
          local css = es.nogroup.v1beta1.clusterSecretStore;

          css.new('onepassword')
          + css.spec.provider.onepassword.withConnectHost('http://onepassword-connect.onepassword.svc.cluster.local:8080')
          + css.spec.provider.onepassword.withVaults({
            Kubernetes: 1,
          })
          + css.spec.provider.onepassword.auth.secretRef.connectTokenSecretRef.withName('onepassword-token')
          + css.spec.provider.onepassword.auth.secretRef.connectTokenSecretRef.withKey('token')
          + css.spec.provider.onepassword.auth.secretRef.connectTokenSecretRef.withNamespace($.values.system.onepassword.namespace),
      },
    },

    [if $.values.system.externalSecrets.enabled then 'externalSecrets']: externalSecrets($.values.system.externalSecrets),

    [if $.values.system.bytebase.enabled then 'bytebase']: bytebase($.values.system.bytebase),

    [if $.values.system.cloudnativePg.enabled then 'cloudnativePg']: cloudnativePG($.values.system.cloudnativePg),
  },
}
