local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);
local cm = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.15/main.libsonnet';

local system = (import 'system/main.libsonnet') + {
  domain:: 'kind.gaelreyrol.dev',
  values+:: {
    system+: {
      certManager+: {
        enabled: true,
      },
      externalSecrets+: {
        enabled: true,
      },
      metricsServer+: {
        enabled: true,
        helm+: {
          args: [
            '--kubelet-insecure-tls',
          ],
        },
      },
      ingressNginx+: {
        enabled: true,
        // https://github.com/kubernetes/ingress-nginx/blob/main/hack/manifest-templates/provider/kind/values.yaml
        helm+: {
          controller+: {
            updateStrategy: {
              type: 'RollingUpdate',
              rollingUpdate: {
                maxUnavailable: 1,
              },
            },
            hostPort+: {
              enabled: true,
            },
            terminationGracePeriodSeconds: 0,
            service+: {
              type: 'LoadBalancer',
              annotations+: {
                // TODO: https://artifacthub.io/packages/helm/external-dns/external-dns
                // https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/cloudflare.md#cloudflare-dns
                // 'external-dns.alpha.kubernetes.io/hostname': $.domain + '.',
              },
            },
            watchIngressWithoutClass: true,
            tolerations+: [{
              key: 'node-role.kubernetes.io/master',
              operator: 'Equal',
              effect: 'NoSchedule',
            }, {
              key: 'node-role.kubernetes.io/control-plane',
              operator: 'Equal',
              effect: 'NoSchedule',
            }],
            publishService+: {
              enabled: false,
            },
            extraArgs+: {
              'publish-status-address': 'localhost',
            },
            allowSnippetAnnotations: true,
            config: {
              'annotations-risk-level': 'Critical',
            },
          },
        },
      },
      onepassword+: {
        enabled: true,
        credentials: importstr './1password-credentials.json',
        token: importstr './1password-token.jwt',
      },
      cloudnativePg+: {
        enabled: true,
        helm+: {},
      },
      kubernetesDashboard+: {
        enabled: false,
        helm+: {
          app+: {
            ingress+: {
              enabled: true,
              ingressClassName: 'nginx',
              hosts: ['dashboard.' + $.domain],
              issuer: {
                name: 'root-ca',
                scope: 'cluster',
              },
            },
          },
        },
      },
      polaris+: {
        enabled: false,
        helm+: {
          dashboard+: {
            ingress+: {
              enabled: true,
              ingressClassName: 'nginx',
              hosts: ['polaris.' + $.domain],
              annotations: {
                'cert-manager.io/cluster-issuer': 'root-ca',
                'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
              },
              tls: [{
                hosts: ['polaris.' + $.domain],
                secretName: 'polaris-dashboard-tls',
              }],
            },
          },
        },
      },
      bytebase+: {
        enabled: true,
        domain: $.domain,
        helm+: {},
      },
    },
  },

  mixins+: {
    certManager+: {
      rootCa: {
        secret:
          local s = k.core.v1.secret;

          s.new('root-ca', {
            'tls.crt': std.base64(importstr './ssl/ca.pem'),
            'tls.key': std.base64(importstr './ssl/ca-key.pem'),
          }) + s.metadata.withNamespace($.values.system.certManager.namespace),

        clusterIssuer:
          local c = cm.nogroup.v1.clusterIssuer;

          c.new('root-ca')
          + c.spec.ca.withSecretName('root-ca'),
      },
    },
  },
};

local nextcloud = (import 'nextcloud/main.libsonnet') + {
  domain:: 'kind.gaelreyrol.dev',
  values+:: {
    nextcloud+: {
      host: 'nextcloud.' + $.domain,
      helm+: {
        nextcloud+: {
          username: 'kind',
          password: 'kind',
          objectStore: {
            s3: {
              enabled: true,
              host: 'api.minio.nextcloud.svc.cluster.local',
              bucket: 'nextcloud',
              usePathStyle: true,
              existingSecret: 'nextcloud-minio',
              secretKeys: {
                accessKey: 'accessKey',
                secretKey: 'secretKey',
              },
            },
          },
        },
      },
    },
  },

  mixins+: {
    // minio: {
    //   secrets: {
    //     local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/0.9/main.libsonnet',
    //     local e = es.nogroup.v1beta1.externalSecret,

    //     admin: e.new('minio-auth')
    //            + e.metadata.withNamespace($.values.nextcloud.namespace)
    //            + e.spec.target.withName('minio-auth')
    //            + e.spec.target.template.withData({
    //              user: 'admin',
    //              password: '{{ .password }}',
    //            })
    //            + e.spec.withDataFrom(
    //              e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
    //              + e.spec.dataFrom.sourceRef.generatorRef.withName('default')
    //            ),

    //     credentials: e.new('nextcloud-minio')
    //                  + e.metadata.withNamespace($.values.nextcloud.namespace)
    //                  + e.spec.secretStoreRef.withKind('ClusterSecretStore')
    //                  + e.spec.secretStoreRef.withName('onepassword')
    //                  + e.spec.withData([
    //                    e.spec.data.withSecretKey('accessKey')
    //                    + e.spec.data.remoteRef.withKey('Nextcloud Minio Credentials')
    //                    + e.spec.data.remoteRef.withProperty('accessKey'),
    //                    e.spec.data.withSecretKey('secretKey')
    //                    + e.spec.data.remoteRef.withKey('Nextcloud Minio Credentials')
    //                    + e.spec.data.remoteRef.withProperty('secretKey'),
    //                  ]),
    //   },

    //   helm: h.template('minio', './charts/minio', {
    //     namespace: $.values.nextcloud.namespace,
    //     values: {
    //       mode: 'standalone',
    //       defaultBuckets: 'nextcloud',
    //       auth: {
    //         existingSecret: 'minio-auth',
    //         rootUserSecretKey: 'user',
    //         rootPasswordSecretKey: 'password',
    //       },
    //       ingress: {
    //         enabled: true,
    //         hostname: 'minio.' + $.domain,
    //         ingressClassName: 'nginx',
    //         annotations: {
    //           'cert-manager.io/cluster-issuer': 'root-ca',
    //           'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
    //         },
    //         tls: [{
    //           hosts: ['minio.' + $.domain],
    //           secretName: 'minio-tls',
    //         }],
    //       },
    //       apiIngress: {
    //         enabled: true,
    //         hostname: 'api.minio.' + $.domain,
    //         ingressClassName: 'nginx',
    //         annotations: {
    //           'cert-manager.io/cluster-issuer': 'root-ca',
    //           'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
    //         },
    //         tls: [{
    //           hosts: ['api.minio.' + $.domain],
    //           secretName: 'minio-api-tls',
    //         }],
    //       },
    //       nodeAffinityPreset: {
    //         type: 'hard',
    //         key: 'storage',
    //         values: ['minio'],
    //       },
    //     },
    //   }),
    // },
  },
};

{
  local kind = self,

  system: system,
  // nextcloud: nextcloud,
}
