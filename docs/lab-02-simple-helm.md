# Laboratorio 2: GitOps con Helm Simple

## 🎯 Objetivo

Introducir Helm de forma gradual, empezando con charts básicos y entendiendo cómo Argo CD los maneja.

## ⏱️ Tiempo Estimado

**45-60 minutos**

## 📋 Prerrequisitos

- Laboratorio 1 completado
- Helm instalado
- Argo CD funcionando

## 🚀 Paso 1: Crear Chart Helm Básico

### 1.1 Generar chart simple

```bash
# Crear directorio para chart
mkdir -p charts/simple-helm-app
cd charts/simple-helm-app

# Generar chart básico
helm create simple-helm-app

# Ver estructura creada
ls -la simple-helm-app/
```

### 1.2 Simplificar Chart.yaml

**Editar `simple-helm-app/Chart.yaml`:**
```yaml
apiVersion: v2
name: simple-helm-app
description: Aplicación simple con Helm para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
```

### 1.3 Simplificar values.yaml

**Editar `simple-helm-app/values.yaml`:**
```yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## 🧪 Paso 2: Probar Chart Localmente

### 2.1 Validar chart

```bash
# Validar sintaxis
helm lint simple-helm-app

# Ver templates generados
helm template simple-helm-app simple-helm-app

# Instalar chart localmente
helm install test-app simple-helm-app

# Ver recursos creados
kubectl get all
```

### 2.2 Limpiar instalación local

```bash
# Desinstalar chart
helm uninstall test-app

# Verificar limpieza
kubectl get all
```

## 🔄 Paso 3: Usar Chart con Argo CD

### 3.1 Crear aplicación Argo CD

```bash
# Volver al directorio raíz
cd /Users/geovani/Documents/LABFAPE/gitops

# Crear aplicación con Helm chart
argocd app create helm-app \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/simple-helm-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Ver aplicación
argocd app list
```

### 3.2 Sincronizar aplicación

```bash
# Sincronizar
argocd app sync helm-app

# Ver estado
argocd app get helm-app
```

### 3.3 Verificar despliegue

```bash
# Ver recursos
kubectl get all

# Probar aplicación
kubectl port-forward svc/simple-helm-app 8080:80
# En otra terminal: curl http://localhost:8080
```

## 🔧 Paso 4: Personalizar Chart

### 4.1 Modificar valores

**Crear `charts/simple-helm-app/values-dev.yaml`:**
```yaml
replicaCount: 1

image:
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  hosts:
    - host: helm-app-dev.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

### 4.2 Actualizar aplicación Argo CD

```bash
# Actualizar aplicación con valores específicos
argocd app set helm-app --helm-set-file values=charts/simple-helm-app/values-dev.yaml

# Sincronizar cambios
argocd app sync helm-app

# Verificar cambios
kubectl get pods
kubectl get svc
```

## 🧪 Paso 5: Probar GitOps con Helm

### 5.1 Hacer cambio en values

**Editar `charts/simple-helm-app/values-dev.yaml`:**
```yaml
replicaCount: 3  # Cambiar de 1 a 3

image:
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  hosts:
    - host: helm-app-dev.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

### 5.2 Commit y push

```bash
# Hacer commit
git add .
git commit -m "Update helm app - increase replicas to 3"
git push origin main
```

### 5.3 Ver sincronización automática

```bash
# Ver estado en Argo CD
argocd app get helm-app

# Verificar que se crearon más pods
kubectl get pods
```

## ✅ Verificación

### Checklist:
- [ ] ✅ Chart Helm creado y validado
- [ ] ✅ Aplicación Argo CD funcionando
- [ ] ✅ Valores personalizados aplicados
- [ ] ✅ Cambios en Git se sincronizan automáticamente

### Comandos de verificación:
```bash
helm list
kubectl get pods
argocd app list
```

## 🎯 Conceptos Aprendidos

1. **Helm Charts**: Empaquetado de aplicaciones Kubernetes
2. **Values**: Configuración específica por ambiente
3. **Argo CD + Helm**: Sincronización de charts desde Git
4. **GitOps**: Cambios en charts se aplican automáticamente

## 🚀 Próximo Paso

Una vez que esto funcione, podemos avanzar:
- Agregar más recursos al chart
- Configurar múltiples ambientes
- Introducir dependencias entre charts

---

**¡Helm básico funcionando con GitOps!** 🎉
