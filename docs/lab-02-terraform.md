# Laboratorio 2: Infraestructura con Terraform

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:
- Entender el concepto de Infraestructura como Código (IaC)
- Crear recursos básicos con Terraform
- Configurar módulos reutilizables
- Integrar Terraform con Kubernetes
- Gestionar estados de Terraform de forma segura

## ⏱️ Tiempo Estimado

**60-90 minutos**

## 📋 Prerrequisitos

- Laboratorio 1 completado
- Conocimientos básicos de Terraform
- Acceso a un proveedor de nube (AWS, GCP, Azure) o Minikube

## 🏗️ Paso 1: Configuración Inicial de Terraform

### 1.1 Estructura de directorios

```bash
# Crear estructura para infraestructura
mkdir -p infra/{environments/{dev,staging,prod},modules/{vpc,eks,security},providers}

# Verificar estructura
tree infra/
```

### 1.2 Configuración de proveedores

**infra/providers/main.tf:**
```hcl
# Configuración de proveedores
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
```

**infra/providers/variables.tf:**
```hcl
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
```

## 🏢 Paso 2: Crear Módulo de VPC

### 2.1 Módulo base de VPC

**infra/modules/vpc/main.tf:**
```hcl
# Crear VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Subnets públicas
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone        = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

# Subnets privadas
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block         = var.private_subnet_cidrs[count.index]
  availability_zone  = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type = "private"
  }
}

# Route Table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Asociar subnets públicas con route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**infra/modules/vpc/variables.tf:**
```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

**infra/modules/vpc/outputs.tf:**
```hcl
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}
```

## ☸️ Paso 3: Crear Módulo de EKS

### 3.1 Módulo EKS básico

**infra/modules/eks/main.tf:**
```hcl
# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_cloudwatch_log_group.cluster,
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-eks"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.project_name}-${var.environment}-eks/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-logs"
  }
}

# IAM Role para EKS Cluster
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.instance_types

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nodes"
  }
}

# IAM Role para Node Group
resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
```

**infra/modules/eks/variables.tf:**
```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "node_desired_size" {
  description = "Número deseado de nodos"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Número máximo de nodos"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "Tipos de instancia para los nodos"
  type        = list(string)
  default     = ["t3.medium"]
}
```

## 🌍 Paso 4: Configuración por Ambiente

### 4.1 Ambiente de Desarrollo

**infra/environments/dev/main.tf:**
```hcl
# Configuración para ambiente de desarrollo
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = "dev"
  
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["us-west-2a", "us-west-2b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = "dev"
  
  subnet_ids         = module.vpc.public_subnet_ids
  kubernetes_version = "1.28"
  node_desired_size  = 1
  node_max_size      = 2
  node_min_size      = 1
  instance_types     = ["t3.small"]
}

# Configurar kubectl
resource "null_resource" "kubectl_config" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  }
}
```

**infra/environments/dev/variables.tf:**
```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "gitops-lab"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-west-2"
}
```

**infra/environments/dev/outputs.tf:**
```hcl
output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = module.vpc.vpc_id
}
```

## 🚀 Paso 5: Despliegue de Infraestructura

### 5.1 Inicializar Terraform

```bash
# Navegar al ambiente de desarrollo
cd infra/environments/dev

# Inicializar Terraform
terraform init

# Verificar configuración
terraform validate
terraform plan
```

### 5.2 Aplicar configuración

```bash
# Aplicar infraestructura
terraform apply

# Confirmar con 'yes' cuando se solicite
```

### 5.3 Verificar despliegue

```bash
# Verificar cluster EKS
aws eks list-clusters --region us-west-2

# Verificar nodos
kubectl get nodes

# Verificar namespaces
kubectl get namespaces
```

## 🔧 Paso 6: Integración con Argo CD

### 6.1 Crear namespace para Argo CD

**infra/modules/eks/argocd.tf:**
```hcl
# Namespace para Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    
    labels = {
      name = "argocd"
    }
  }
}

# Instalar Argo CD con Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hosts = ["argocd.${var.environment}.${var.project_name}.local"]
        }
      }
      configs = {
        cm = {
          "url" = "https://argocd.${var.environment}.${var.project_name}.local"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}
```

### 6.2 Configurar Argo CD Application

**infra/modules/eks/argocd-app.tf:**
```hcl
# Aplicación de ejemplo en Argo CD
resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "nginx-example"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/argoproj/argocd-example-apps.git"
        targetRevision = "HEAD"
        path           = "guestbook"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
```

## ✅ Verificación del Laboratorio

### Checklist de completitud:

- [ ] ✅ Estructura de directorios creada
- [ ] ✅ Módulos de VPC y EKS configurados
- [ ] ✅ Configuración por ambiente implementada
- [ ] ✅ Infraestructura desplegada con Terraform
- [ ] ✅ Cluster EKS funcionando
- [ ] ✅ Argo CD instalado en el cluster
- [ ] ✅ Aplicación de ejemplo desplegada

### Comandos de verificación:

```bash
# Verificar infraestructura
terraform output

# Verificar cluster
kubectl get nodes
kubectl get pods -n argocd

# Verificar aplicaciones Argo CD
kubectl get applications -n argocd
```

## 🎯 Conceptos Clave Aprendidos

1. **Infraestructura como Código:** Definir infraestructura en archivos de configuración
2. **Módulos Terraform:** Reutilización de código para diferentes ambientes
3. **Gestión de Estados:** Control de versiones de la infraestructura
4. **Integración Kubernetes:** Provisionar clusters desde Terraform
5. **GitOps Integration:** Conectar infraestructura con Argo CD

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 3:** Aplicaciones con Helm
- **Laboratorio 4:** GitOps Avanzado con Argo CD
- **Laboratorio 5:** Casos de Uso Complejos

## 🆘 Solución de Problemas

### Problema: Error de permisos AWS
```bash
# Configurar credenciales AWS
aws configure

# Verificar permisos
aws sts get-caller-identity
```

### Problema: Cluster EKS no responde
```bash
# Actualizar kubeconfig
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>

# Verificar conectividad
kubectl get nodes
```

### Problema: Argo CD no se instala
```bash
# Verificar namespace
kubectl get namespaces

# Verificar pods
kubectl get pods -n argocd

# Reinstalar si es necesario
helm uninstall argocd -n argocd
helm install argocd argo/argo-cd -n argocd
```

---

**¡Excelente! Has completado el Laboratorio 2. Continúa con el Laboratorio 3 para aprender sobre aplicaciones con Helm.** 🎉
