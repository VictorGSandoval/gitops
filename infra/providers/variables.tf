variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "gitops-lab"
}
