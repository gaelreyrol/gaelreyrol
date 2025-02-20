# Kubernetes Development Conventions

These conventions are used to guide the development and configuration of Kubernetes aka k8s.

## General

- When working on files in the `infra/k8s` directory, always follow the following conventions.
- [Infrastructure As Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) is a mandatory practice, everything should be configurable and deployed from code. 

### Kubernetes

[Kubernetes](https://kubernetes.io/docs/concepts/) is used to deploy services on the infrastructure. Currently these are the following environments deployed:

- Always refer to [Kubernetes API resources](https://kubernetes.io/docs/reference/kubernetes-api/) when create a Kubernetes definition.

Defintions and Custom Resource Definitions documentation tools:
- <https://kubespec.dev/>
    - for the Pod definition: <https://kubespec.dev/v1/Pod>
- <https://doc.crds.dev/>
    - for the external-secrets CRDs: <https://doc.crds.dev/github.com/external-secrets/external-secrets>

### Kind

[Kind](https://kind.sigs.k8s.io/) is a tool for running local Kubernetes clusters using Docker container "nodes".
Kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.

- You must always consider kind specific features when working on local/testing environment related files.
- You can refer to the examples folder of the GitHub repository to reference code: <https://github.com/kubernetes-sigs/kind/tree/main/site/static/examples>.

### Helm

[Helm](https://helm.sh/docs/intro/using_helm/) is used as a service library, that helps to deploy production ready services.

- When a service requirement is identified always look for an available Helm chart on [ArtifactHub](https://artifacthub.io/).
- Prefer an Helm [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) chart to an Helm chart that only deploys services.

For example:

If you need to deploy a service that requires a PostgreSQL database, you will look for a PostgreSQL chart available on [ArtifactHub](https://artifacthub.io/).
But if an operator that helps to manage a PostgreSQL database is available, you must prefer it.

### Jsonnet

[Jsonnet](https://jsonnet.org/ref/language.html) is used to write Kubernetes definitions, it helps writing configuration files without errors and allows to reuse sets of configuration easily.

- When writing Kubernetes definitions, you must use [k8s jsonnet library](https://jsonnet-libs.github.io/k8s-libsonnet/).
- Check for other jsonnet libraries that would help to writing definitions that refers to [Custom Resource Definitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) in the jsonnet-libs GitHub organization [repositories](https://github.com/orgs/jsonnet-libs/repositories).

### Tanka

[Tanka](https://tanka.dev/) is the utility tool to deploy configuration files rewritten in Jsonnet to a Kubernetes cluster.

- When referencing an Helm chart, always the documentation on [Helm support](https://tanka.dev/helm/).
- Always follow this directory [structure](https://tanka.dev/directory-structure/).
