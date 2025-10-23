terraform {
  required_version = ">= 1.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.2.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  host = kind_cluster.cluster.endpoint
  cluster_ca_certificate = kind_cluster.cluster.cluster_ca_certificate
  client_certificate     = kind_cluster.cluster.client_certificate
  client_key            = kind_cluster.cluster.client_key
}

provider "helm" {
  kubernetes {
    host = kind_cluster.cluster.endpoint
    cluster_ca_certificate = kind_cluster.cluster.cluster_ca_certificate
    client_certificate     = kind_cluster.cluster.client_certificate
    client_key            = kind_cluster.cluster.client_key
  }
}

# Crear cluster local con Kind
resource "kind_cluster" "cluster" {
  name = "gitops-demo"
  wait_for_ready = true

  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      # Exponer puerto para Argo CD
      extra_port_mappings {
        container_port = 30080
        host_port     = 8080
      }
    }

    node {
      role = "worker"
    }
  }
}

# Crear namespace para Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [kind_cluster.cluster]
}

# Instalar Argo CD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.46.7"

  values = [
    <<-EOT
    server:
      service:
        type: NodePort
        nodePortHttp: 30080
    configs:
      params:
        server.insecure: true
      secret:
        existingSecret: "argocd-secret"
    EOT
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Crear secret Argo
resource "kubernetes_secret" "argocd_admin_password" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    "admin.password" = base64encode("pssadmin123!")
  }

  depends_on = [kubernetes_namespace.argocd]
}