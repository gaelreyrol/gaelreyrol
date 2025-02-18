local k = import 'ksonnet-util/kausal.libsonnet';
local t = import 'tanka-util/main.libsonnet';
local h = t.helm.new(std.thisFile);

(import './config.libsonnet') +
{
  local c = $._config.system,

  kubernetesDashboard: {
    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;

      serviceAccount.new(name=c.user)
      + serviceAccount.metadata.withNamespace(namespace=c.namespace),
    clusterRoleBinding:
      local clusterRoleBinding = k.rbac.v1.clusterRoleBinding;

      clusterRoleBinding.new(name=c.user)
      + clusterRoleBinding.metadata.withAnnotationsMixin({ 'tanka.dev/namespaced': 'false' })
      + clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
      + clusterRoleBinding.roleRef.withKind('ClusterRole')
      + clusterRoleBinding.roleRef.withName('cluster-admin')
      + clusterRoleBinding.withSubjects([{ kind: 'ServiceAccount', name: c.user, namespace: c.namespace }]),
    secret:
      local secret = k.core.v1.secret;

      secret.new(name=c.user, data={})
      + secret.metadata.withNamespace(namespace=c.namespace)
      + secret.metadata.withAnnotations({ 'kubernetes.io/service-account.name': c.user })
      + secret.withType('kubernetes.io/service-account-token'),

    ingress: h.template('ingress-nginx', './charts/ingress-nginx', {
      namespace: c.namespace,
      values: c.ingress.values,
    }),

    dashboard: h.template('kubernetes-dashboard', './charts/kubernetes-dashboard', {
      namespace: c.namespace,
      values: c.dashboard.values,
    }),

    metrics: h.template('metrics-server', './charts/metrics-server', {
      namespace: c.namespace,
      values: c.metrics.values,
    }),
  },
}
