local t = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local h = t.helm.new(std.thisFile);
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/0.9/main.libsonnet';

{
  values:: {
    nextcloud: {
      namespace: 'nextcloud',
      host: error 'must provide a host',
      nextcloud: {
        helm+: {
          image: {
            flavor: 'fpm',
          },
          ingress: {
            enabled: true,
            className: 'nginx',
            annotations: {
              'cert-manager.io/cluster-issuer': 'root-ca',
              'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
              'nginx.ingress.kubernetes.io/affinity': 'cookie',
              'nginx.ingress.kubernetes.io/enable-cors': 'true',
              'nginx.ingress.kubernetes.io/cors-allow-headers': 'X-Forwarded-For',
              'nginx.ingress.kubernetes.io/server-snippet': |||
                server_tokens off;
                proxy_hide_header X-Powered-By;
                rewrite ^/.well-known/webfinger /index.php/.well-known/webfinger last;
                rewrite ^/.well-known/nodeinfo /index.php/.well-known/nodeinfo last;
                rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
                rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json;
                location = /.well-known/carddav {
                  return 301 $scheme://$host/remote.php/dav;
                }
                location = /.well-known/caldav {
                  return 301 $scheme://$host/remote.php/dav;
                }
                location = /robots.txt {
                  allow all;
                  log_not_found off;
                  access_log off;
                }
                location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
                  deny all;
                }
                location ~ ^/(?:autotest|occ|issue|indie|db_|console) {
                  deny all;
                }
              |||,
            },
            tls: [{
              hosts: [$.values.nextcloud.host],
              secretName: $.values.nextcloud.host + '-tls',
            }],
          },
          nextcloud: {
            host: $.values.nextcloud.host,
            existingSecret: {
              enabled: true,
              secretName: 'nextcloud-admin',
              usernameKey: 'username',
              passwordKey: 'password',
              smtpHostKey: 'smtpHost',
              smtpUsernameKey: 'smtpUsername',
              smtpPasswordKey: 'smtpPassword',
            },
            mail: {
              enabled: true,
              fromAddress: 'nextcloud.kind@gaelreyrol.com',
              domain: 'gaelreyrol.com',
              host: 'smtp-relay.brevo.com',
              port: 587,
              secure: 'tls',
            },
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
            configs: {
              'proxy.config.php': |||
                <?php
                $CONFIG = array (
                  'trusted_proxies' => array(
                    0 => '127.0.0.1',
                    1 => '10.0.0.0/8',
                  ),
                  'forwarded_for_headers' => array('HTTP_X_FORWARDED_FOR'),
                );
              |||,
            },
          },
          nginx: {
            enabled: true,
          },
          redis: {
            enabled: true,
            auth: {
              enabled: true,
              existingSecret: 'redis-auth',
              existingSecretPasswordKey: 'password',
            },
            architecture: 'standalone',
          },
          cronjob: {
            enabled: false,
          },
          rbac: {
            enabled: false,
          },
          hpa: {
            enabled: false,
          },
          internalDatabase: {
            enabled: false,
          },
          externalDatabase: {
            enabled: true,
            type: 'postgresql',
            host: 'postgresql.nextcloud.svc.cluster.local',
            database: 'nextcloud',
            user: 'nextcloud',
            existingSecret: {
              enabled: true,
              secretName: 'postgresql-auth',
              usernameKey: 'username',
              passwordKey: 'password',
            },
          },
        },
      },
      postgresql: {
        helm+: {
          global: {
            postgresql: {
              auth: {
                enablePostgresUser: true,
                username: 'nextcloud',
                database: 'nextcloud',
                existingSecret: 'postgresql-auth',
                secretKeys: {
                  adminPasswordKey: 'adminPassword',
                  userPasswordKey: 'password',
                },
              },
            },
          },
          primary: {
            nodeAffinityPreset: {
              type: 'hard',
              key: 'storage',
              values: ['postgresql'],
            },
          },
          architecture: 'standalone',
        },
      },
    },
  },

  mixins: {
    local e = es.nogroup.v1beta1.externalSecret,

    namespace: k.core.v1.namespace.new($.values.nextcloud.namespace),

    // nextcloud: {
    //   secrets: {
    //     admin: e.new('nextcloud-admin')
    //            + e.metadata.withNamespace('nextcloud')
    //            + e.spec.target.withName('nextcloud-admin')
    //            + e.spec.target.template.withData({
    //              username: 'admin@cloud.gaelreyrol.dev',
    //              password: '{{ .password }}',
    //              smtpHost: 'smtp-relay.brevo.com',
    //              smtpUsername: '{{ .smtpUsername }}',
    //              smtpPassword: '{{ .smtpPassword }}',
    //            })
    //            + e.spec.secretStoreRef.withKind('ClusterSecretStore')
    //            + e.spec.secretStoreRef.withName('onepassword')
    //            + e.spec.withDataFrom(
    //              e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
    //              + e.spec.dataFrom.sourceRef.generatorRef.withName('default'),
    //            )
    //            + e.spec.withData([
    //              e.spec.data.withSecretKey('smtpUsername')
    //              + e.spec.data.remoteRef.withKey('Nextcloud Brevo SMTP Credentials')
    //              + e.spec.data.remoteRef.withProperty('username'),
    //              e.spec.data.withSecretKey('smtpPassword')
    //              + e.spec.data.remoteRef.withKey('Nextcloud Brevo SMTP Credentials')
    //              + e.spec.data.remoteRef.withProperty('password'),
    //            ]),
    //   },
    //   helm: t.k8s.patchKubernetesObjects(h.template('nextcloud', './charts/nextcloud', {
    //     namespace: $.values.nextcloud.namespace,
    //     values: $.values.nextcloud.nextcloud.helm,
    //   }), {
    //     metadata+: {
    //       namespace: $.values.nextcloud.namespace,
    //     },
    //   }),
    // },

    passwordGenerator:
      local p = es.generators.v1alpha1.password;

      p.new('default')
      + p.metadata.withNamespace('nextcloud')
      + p.spec.withAllowRepeat(true)
      + p.spec.withLength(32)
      + p.spec.withDigits(5)
      + p.spec.withSymbols(5)
      + p.spec.withSymbolCharacters('-_$@'),

    postgresql: {
      secrets: {
        auth: e.new('postgresql-auth')
              + e.metadata.withNamespace('nextcloud')
              + e.spec.target.withName('postgresql-auth')
              + e.spec.target.template.withData({
                adminPassword: '{{ .adminPassword }}',
                username: 'nextcloud',
                password: '{{ .password }}',
              })
              + e.spec.withDataFrom([
                e.spec.dataFrom.withRewrite(
                  e.spec.dataFrom.rewrite.regexp.withSource('(.*)')
                  + e.spec.dataFrom.rewrite.regexp.withTarget('adminPassword')
                )
                + e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
                + e.spec.dataFrom.sourceRef.generatorRef.withName('default'),
                e.spec.dataFrom.withRewrite(
                  e.spec.dataFrom.rewrite.regexp.withSource('(.*)')
                  + e.spec.dataFrom.rewrite.regexp.withTarget('password')
                )
                + e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
                + e.spec.dataFrom.sourceRef.generatorRef.withName('default'),
              ]),
      },

      helm: h.template('postgresql', './charts/postgresql', {
        namespace: $.values.nextcloud.namespace,
        values: $.values.nextcloud.postgresql.helm,
      }),
    },

    // redis: {
    //   secrets: {
    //     auth: e.new('redis-auth')
    //           + e.metadata.withNamespace('nextcloud')
    //           + e.spec.target.withName('redis-auth')
    //           + e.spec.withDataFrom(
    //             e.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
    //             + e.spec.dataFrom.sourceRef.generatorRef.withName('default')
    //           ),
    //   },
    // },
  },
}
