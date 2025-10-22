# Configuración de proveedores para GitOps Lab
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

# Configuración del proveedor AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "gitops-lab"
      ManagedBy   = "terraform"
    }
  }
}

# Configuración del proveedor Kubernetes
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Configuración del proveedor Helm
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
