# Required variables.
variable "ssh_public_key" {
  description = "SSH public key to attach to the instances. Set to `null` to have an SSH key generated for you."
  type        = string

  validation {
    condition     = var.ssh_public_key != null && var.ssh_public_key != ""
    error_message = "SSH key cannot be `null` or empty."
  }
}

# Optional variables.
variable "ingress_port" {
  type        = number
  description = "Port to use for the load balancer ingress."
  default     = 80
}

variable "frontend_port" {
  type        = number
  description = "Port to use for the frontend service."
  default     = 80
}

variable "frontend_tag" {
  type        = string
  description = "Container image tag of the frontend image."
  default     = "6f25cec03dfe5edb2196d1bfd558adbec3fa94d6"
}

variable "backend_port" {
  type        = number
  description = "Port to use for the backend service."
  default     = 3030
}

variable "backend_tag" {
  type        = string
  description = "Container image tag of the backend image."
  default     = "6f25cec03dfe5edb2196d1bfd558adbec3fa94d6"
}
