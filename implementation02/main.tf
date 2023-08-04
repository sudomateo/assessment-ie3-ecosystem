terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
  }
}

# Read the Kubernetes configuration from the base infrastructure state. In a
# production scenario we won't store the state in a local file.
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "${path.module}/base/terraform.tfstate"
  }
}

# Kubernetes provider configuration.
provider "kubernetes" {
  host                   = data.terraform_remote_state.base.outputs.kubeconfig[0].host
  username               = data.terraform_remote_state.base.outputs.kubeconfig[0].username
  password               = data.terraform_remote_state.base.outputs.kubeconfig[0].password
  client_certificate     = base64decode(data.terraform_remote_state.base.outputs.kubeconfig[0].client_certificate)
  client_key             = base64decode(data.terraform_remote_state.base.outputs.kubeconfig[0].client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.base.outputs.kubeconfig[0].cluster_ca_certificate)
}

# Tag of frontend container.
variable "frontend_tag" {
  type        = string
  description = "Container image tag of the frontend image."
  default     = "6f25cec03dfe5edb2196d1bfd558adbec3fa94d6"
}

# Tag of backend container.
variable "backend_tag" {
  type        = string
  description = "Container image tag of the backend image."
  default     = "6f25cec03dfe5edb2196d1bfd558adbec3fa94d6"
}
