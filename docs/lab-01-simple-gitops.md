# Laboratorio 1: GitOps Básico - Empezando Simple

## 🎯 Objetivo

Aprender GitOps paso a paso, empezando con lo más básico: YAMLs simples de Kubernetes y cómo Argo CD los sincroniza automáticamente.

## ⏱️ Tiempo Estimado

**30-45 minutos**

## 📋 Prerrequisitos

- Minikube funcionando
- kubectl configurado
- Argo CD instalado

## 🚀 Paso 1: Configuración Básica

### 1.1 Verificar que todo funciona

```bash
# Verificar cluster
kubectl get nodes

# Verificar Argo CD
kubectl get pods -n argocd

# Acceder a Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 📱 Paso 2: Crear Aplicación Simple con YAML

### 2.1 Crear Deployment básico

**Crear archivo `apps/simple-app/deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

### 2.2 Crear Service básico

**Crear archivo `apps/simple-app/service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### 2.3 Crear ConfigMap básico

**Crear archivo `apps/simple-app/configmap.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Simple App</title>
    </head>
    <body>
        <h1>🚀 GitOps Lab</h1>
        <p>Aplicación simple desplegada con GitOps</p>
        <p>Hostname: <span id="hostname"></span></p>
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
        </script>
    </body>
    </html>
```

## 🔄 Paso 3: Configurar Argo CD

### 3.1 Agregar repositorio a Argo CD

```bash
# Agregar repositorio
argocd repo add https://github.com/VictorGSandoval/gitops.git --name gitops-lab

# Verificar repositorio
argocd repo list
```

### 3.2 Crear aplicación simple

```bash
# Crear aplicación
argocd app create simple-app \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path apps/simple-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Ver aplicación creada
argocd app list
```

### 3.3 Sincronizar aplicación

```bash
# Sincronizar
argocd app sync simple-app

# Ver estado
argocd app get simple-app
```

## 🧪 Paso 4: Verificar que funciona

### 4.1 Ver recursos creados

```bash
# Ver pods
kubectl get pods

# Ver servicios
kubectl get svc

# Ver configmaps
kubectl get configmaps
```

### 4.2 Probar aplicación

```bash
# Port forward para probar
kubectl port-forward svc/nginx-service 8080:80

# En otra terminal, probar
curl http://localhost:8080
```

## 🔄 Paso 5: Probar GitOps

### 5.1 Hacer cambio simple

**Editar `apps/simple-app/configmap.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Simple App</title>
    </head>
    <body>
        <h1>🚀 GitOps Lab</h1>
        <p>Aplicación simple desplegada con GitOps</p>
        <p>Hostname: <span id="hostname"></span></p>
        <p>✅ GitOps funcionando - cambio aplicado!</p>
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
        </script>
    </body>
    </html>
```

### 5.2 Commit y push

```bash
# Hacer commit
git add .
git commit -m "Update simple app - GitOps test"
git push origin main
```

### 5.3 Ver sincronización automática

```bash
# Ver estado en Argo CD
argocd app get simple-app

# Verificar que el cambio se aplicó
kubectl port-forward svc/nginx-service 8080:80
# Probar: curl http://localhost:8080
```

## ✅ Verificación

### Checklist simple:
- [ ] ✅ Pods funcionando
- [ ] ✅ Servicio funcionando
- [ ] ✅ Aplicación accesible
- [ ] ✅ Cambio en Git se aplicó automáticamente

### Comandos de verificación:
```bash
kubectl get pods
kubectl get svc
argocd app list
```

## 🎯 Conceptos Aprendidos

1. **YAMLs básicos**: Deployment, Service, ConfigMap
2. **Argo CD**: Sincronización automática desde Git
3. **GitOps**: Cambios en Git se aplican automáticamente

## 🚀 Próximo Paso

Una vez que esto funcione, podemos avanzar gradualmente:
- Agregar más recursos (Ingress, Secrets)
- Introducir Helm charts simples
- Configurar múltiples ambientes

---

**¡Simple y funcional! GitOps básico funcionando.** 🎉
