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

# Cambiar entre clusters
kubectl config use-context kind-gitops-demo      # Ir a Kind

kubectl config use-context docker-desktop        # Ir a Docker Desktop

# Ver el cluster actual
kubectl config current-context

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

## *Opcional 

Para crear un nginx de prueba en cluster:

```bash
# 1. Crear deployment
kubectl create deployment nginx --image=nginx

# 2. Exponer como NodePort (IMPORTANTE)
kubectl expose deployment nginx --port=80 --type=NodePort

# 3. Ver el servicio y el puerto asignado
kubectl get svc nginx

# Redirección temporal
kubectl port-forward svc/nginx 8081:80

# Luego acceder a:
http://localhost:8081
```