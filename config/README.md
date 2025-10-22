# Configuración de GitOps Lab

## 🎯 Descripción

Este archivo contiene la configuración principal del laboratorio GitOps, incluyendo variables de entorno, configuraciones por defecto y parámetros personalizables.

## ⚙️ Variables de Configuración

### Configuración General
```yaml
# Configuración general del laboratorio
lab:
  name: "GitOps Lab"
  version: "1.0.0"
  description: "Laboratorio práctico de GitOps con Terraform, Argo CD y Helm"
  
# Configuración de ambientes
environments:
  dev:
    name: "Desarrollo"
    namespace: "dev"
    replicas: 1
    resources:
      cpu: "100m"
      memory: "128Mi"
  
  staging:
    name: "Staging"
    namespace: "staging"
    replicas: 2
    resources:
      cpu: "200m"
      memory: "256Mi"
  
  prod:
    name: "Producción"
    namespace: "prod"
    replicas: 3
    resources:
      cpu: "500m"
      memory: "512Mi"
```

### Configuración de Clúster
```yaml
# Configuración del clúster Kubernetes
cluster:
  type: "minikube"  # minikube, kind, eks, gke, aks
  version: "1.28"
  nodes: 1
  memory: "4096"
  cpu: "2"
  disk: "20g"
```

### Configuración de Argo CD
```yaml
# Configuración de Argo CD
argocd:
  version: "2.7.0"
  namespace: "argocd"
  server:
    port: 8080
    host: "localhost"
  admin:
    username: "admin"
    password: "generated"
  projects:
    - name: "dev-project"
      description: "Proyecto para desarrollo"
    - name: "prod-project"
      description: "Proyecto para producción"
```

### Configuración de Monitoreo
```yaml
# Configuración de monitoreo
monitoring:
  enabled: true
  namespace: "monitoring"
  prometheus:
    enabled: true
    retention: "30d"
    storage: "50Gi"
  grafana:
    enabled: true
    adminPassword: "admin123"
    storage: "10Gi"
  alertmanager:
    enabled: true
    storage: "10Gi"
```

### Configuración de Aplicaciones
```yaml
# Configuración de aplicaciones
applications:
  nginx:
    enabled: true
    chart: "nginx-app"
    namespace: "dev"
    values:
      replicaCount: 2
      image:
        repository: "nginx"
        tag: "1.21"
      service:
        type: "ClusterIP"
        port: 80
  
  api:
    enabled: true
    chart: "api-app"
    namespace: "dev"
    values:
      replicaCount: 2
      image:
        repository: "node"
        tag: "18-alpine"
      service:
        type: "ClusterIP"
        port: 3000
```

## 🔧 Configuración por Ambiente

### Desarrollo
```yaml
# Configuración para desarrollo
dev:
  cluster:
    type: "minikube"
    memory: "2048"
    cpu: "2"
  
  applications:
    nginx:
      replicaCount: 1
      resources:
        cpu: "100m"
        memory: "128Mi"
    
    api:
      replicaCount: 1
      resources:
        cpu: "100m"
        memory: "128Mi"
  
  monitoring:
    enabled: false
```

### Producción
```yaml
# Configuración para producción
prod:
  cluster:
    type: "eks"
    region: "us-west-2"
    nodeGroup:
      instanceTypes: ["t3.medium"]
      minSize: 2
      maxSize: 10
  
  applications:
    nginx:
      replicaCount: 3
      resources:
        cpu: "500m"
        memory: "512Mi"
      autoscaling:
        enabled: true
        minReplicas: 3
        maxReplicas: 10
    
    api:
      replicaCount: 5
      resources:
        cpu: "500m"
        memory: "512Mi"
      autoscaling:
        enabled: true
        minReplicas: 5
        maxReplicas: 20
  
  monitoring:
    enabled: true
    prometheus:
      retention: "90d"
      storage: "100Gi"
    grafana:
      storage: "20Gi"
```

## 🚀 Scripts de Configuración

### Script de Configuración Inicial
```bash
#!/bin/bash
# scripts/configure-lab.sh

# Cargar configuración
source config/lab-config.yaml

# Configurar variables de entorno
export LAB_NAME="${lab.name}"
export LAB_VERSION="${lab.version}"
export CLUSTER_TYPE="${cluster.type}"
export ARGOCD_VERSION="${argocd.version}"

# Configurar cluster
case "${cluster.type}" in
  "minikube")
    minikube start --memory="${cluster.memory}" --cpus="${cluster.cpu}"
    ;;
  "kind")
    kind create cluster --name gitops-lab
    ;;
  "eks")
    terraform -chdir=infra/environments/prod init
    terraform -chdir=infra/environments/prod apply
    ;;
esac

# Configurar Argo CD
kubectl create namespace "${argocd.namespace}"
kubectl apply -n "${argocd.namespace}" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Configurar monitoreo si está habilitado
if [ "${monitoring.enabled}" = "true" ]; then
    kubectl create namespace "${monitoring.namespace}"
    helm install monitoring-stack prometheus-community/kube-prometheus-stack \
      -n "${monitoring.namespace}" \
      --set prometheus.prometheusSpec.retention="${monitoring.prometheus.retention}" \
      --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage="${monitoring.prometheus.storage}" \
      --set grafana.adminPassword="${monitoring.grafana.adminPassword}" \
      --set grafana.persistence.size="${monitoring.grafana.storage}"
fi

echo "✅ Configuración del laboratorio completada"
```

### Script de Validación
```bash
#!/bin/bash
# scripts/validate-config.sh

# Validar configuración
validate_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "❌ Archivo de configuración no encontrado: $config_file"
        return 1
    fi
    
    # Validar YAML
    if ! yq eval '.' "$config_file" > /dev/null 2>&1; then
        echo "❌ Archivo de configuración inválido: $config_file"
        return 1
    fi
    
    echo "✅ Configuración válida: $config_file"
    return 0
}

# Validar archivos de configuración
validate_config "config/lab-config.yaml"
validate_config "config/environments/dev.yaml"
validate_config "config/environments/prod.yaml"

echo "✅ Validación de configuración completada"
```

## 📋 Checklist de Configuración

### Configuración Inicial
- [ ] Variables de entorno configuradas
- [ ] Archivos de configuración creados
- [ ] Scripts de configuración ejecutados
- [ ] Cluster Kubernetes funcionando
- [ ] Argo CD instalado y configurado

### Configuración por Ambiente
- [ ] Configuración de desarrollo
- [ ] Configuración de staging
- [ ] Configuración de producción
- [ ] Aplicaciones desplegadas
- [ ] Monitoreo configurado

### Validación
- [ ] Configuración validada
- [ ] Aplicaciones funcionando
- [ ] Monitoreo activo
- [ ] Alertas configuradas
- [ ] Backup configurado

## 🔧 Personalización

### Modificar Configuración
1. **Editar archivos de configuración** en `config/`
2. **Ejecutar script de configuración** `./scripts/configure-lab.sh`
3. **Validar configuración** `./scripts/validate-config.sh`
4. **Reiniciar servicios** si es necesario

### Agregar Nuevos Ambientes
1. Crear archivo de configuración en `config/environments/`
2. Agregar configuración en `config/lab-config.yaml`
3. Actualizar scripts de configuración
4. Documentar cambios

## 📚 Documentación

- [Configuración General](config/lab-config.yaml)
- [Configuración de Desarrollo](config/environments/dev.yaml)
- [Configuración de Producción](config/environments/prod.yaml)
- [Scripts de Configuración](scripts/)

---

**¡Configura tu laboratorio GitOps según tus necesidades!** 🎯
