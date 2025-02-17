(import 'system/system.libsonnet') +
{
  _config+: {
    system+: {
      metrics+:{
        values+: {
          defaultArgs+:[
            "--kubelet-insecure-tls"
          ]
        }
      }
    }
  }
}
