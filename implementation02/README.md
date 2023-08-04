# Implementation 02: Azure Kubernetes Service

## Deployment

This deployment is split into base infrastructure and application
infrastructure. The base infrastructure deploys a Kubernetes cluster using Azure
Kubernetes Service. The application infrastructure deploys Taskly to Kubernetes.

### Create Kubernetes Cluster

First, create the Kubernetes cluster to deploy Taskly to.

```sh
export ARM_CLIENT_ID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
export ARM_CLIENT_SECRET='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
export ARM_SUBSCRIPTION_ID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
export ARM_TENANT_ID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
cd base && terraform init && terraform apply
```

### Deploy Taskly (Terraform)

With the Kubernetes cluster created, deploy Taskly.

```sh
terraform init && terraform apply
```

### Deploy Taskly (Kubernetes)

A Kubernetes YAML manifest is included to deploy Taskly to a Kubernetes cluster
via `kubectl`.

```
kubectl apply -f taskly.yaml
```
