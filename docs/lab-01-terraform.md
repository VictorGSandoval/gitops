# Laboratorio 1: Configuración de Infraestructura con Terraform

Este laboratorio te guiará en la configuración de un cluster Kubernetes local usando Kind y la instalación de Argo CD usando Terraform.

## Prerrequisitos

- Docker instalado y en ejecución
- Terraform instalado (versión >= 1.0)
- kubectl instalado

## Pasos

### 1. Inicializar Terraform

```bash
cd terraform
terraform init
```

### 2. Revisar el Plan de Terraform

```bash
terraform plan
```

### 3. Aplicar la Configuración

```bash
terraform apply -auto-approve
```

### 4. Verificar la Instalación

```bash
# Listar todos los contextos disponibles
kubectl config get-contexts

# Configurar kubectl para usar el nuevo cluster
kubectl cluster-info --context kind-gitops-demo

# Verificar que Argo CD está instalado
kubectl get pods -n argocd
```

### 5. Acceder a Argo CD

```bash
# Obtener la contraseña inicial de admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Acceder a la UI de Argo CD
# Abrir en el navegador: http://localhost:8080
# Usuario: admin
# Contraseña: [la obtenida en el paso anterior]
```

## Limpieza

Para eliminar todo lo creado:

```bash
terraform destroy -auto-approve
```