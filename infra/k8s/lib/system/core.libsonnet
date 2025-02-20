local k = import 'ksonnet-util/kausal.libsonnet';

local defaults = {
  user:: error 'must provide user',
  namespace:: error 'must provide namespace',
};

function(params) {
  local c = self,
  _config:: defaults + params,

  serviceAccount:
    local serviceAccount = k.core.v1.serviceAccount;

    serviceAccount.new(c._config.user)
    + serviceAccount.metadata.withNamespace(c._config.namespace),

  clusterRoleBinding:
    local clusterRoleBinding = k.rbac.v1.clusterRoleBinding;

    clusterRoleBinding.new(c._config.user)
    + clusterRoleBinding.metadata.withAnnotations({ 'tanka.dev/namespaced': 'false' })
    + clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
    + clusterRoleBinding.roleRef.withKind('ClusterRole')
    + clusterRoleBinding.roleRef.withName('cluster-admin')
    + clusterRoleBinding.withSubjects([{ kind: 'ServiceAccount', name: c._config.user, namespace: c._config.namespace }]),

  secret:
    local secret = k.core.v1.secret;

    secret.new(c._config.user, null)
    + secret.metadata.withNamespace(c._config.namespace)
    + secret.metadata.withAnnotations({ 'kubernetes.io/service-account.name': c._config.user })
    + secret.withType('kubernetes.io/service-account-token'),
}
