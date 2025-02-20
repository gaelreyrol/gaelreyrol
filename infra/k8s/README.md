# Kubernetes

## Dependencies

### Jsonnet Libraries

```bash
jb install
```

### Helm Charts

```bash
find lib -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cd "{}" && tk tool charts vendor' \;
find environments -mindepth 2 -maxdepth 2 -type d -exec sh -c 'cd "{}" && tk tool charts vendor' \;
```

## Environments

### Kind

#### Setup

```bash
cfssl genkey -initca environments/kind/cfssl.json | cfssljson -bare environments/kind/ssl/ca

cd environments/kind && op connect server create "Kind" --vaults "Kubernetes"
op connect token create "$(uname -n)" --server "Kind" --vault "Kubernetes" --expires-in "1w" > environments/kind/1password-token.jwt

kind create cluster --config=./environments/kind/kind.yaml
docker compose -f ./environments/kind/compose.yaml up -d

tk apply environments/kind -t CustomResourceDefinition/.+
tk apply environments/kind

mc alias set kind/ https://api.minio.kind.gaelreyrol.dev:443 admin $(kubectl get secrets minio-auth -n nextcloud -o jsonpath="{.data.password}" | base64 -d)
mc admin accesskey create kind/ --name "Nextcloud" --description "Access key for Nextcloud"
op item create --template=onepassword/s3-credentials.json \
    --vault Kubernetes \
    --title "Nextcloud Minio Credentials" \
    --tags "nextcloud,minio,kind" - \
    'accessKey=ACCESS_KEY' \
    'secretKey=SECRET_KEY' \
    "validFrom=$(date +%s)"
```