# Laboratorio 2: Fundamentos de Kubernetes

## 🎯 Objetivo

Entender Kubernetes desde cero mediante la creación manual de recursos. Al finalizar este laboratorio serás capaz de:

- Crear y gestionar pods, servicios y deployments
- Entender ConfigMaps y Secrets
- Configurar Ingress para acceso externo
- Comprender el networking básico de Kubernetes

## ⏱️ Tiempo Estimado

**90-120 minutos**

## 📋 Prerrequisitos

- Laboratorio 1 completado
- Minikube funcionando
- kubectl configurado
- Conocimientos básicos de contenedores

## 🏗️ Paso 1: Creación de Pods Básicos

### 1.1 Crear Primer Pod

```bash
# Crear un pod simple de nginx
kubectl run nginx-pod --image=nginx:1.21 --port=80

# Verificar pod creado
kubectl get pods
kubectl describe pod nginx-pod
```

### 1.2 Crear Pod con YAML

**Crear archivo `pod-basico.yaml`:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod
  labels:
    app: nginx
    version: "1.21"
spec:
  containers:
  - name: nginx-container
    image: nginx:1.21
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Aplicar el pod:**
```bash
kubectl apply -f pod-basico.yaml

# Verificar
kubectl get pods
kubectl get pods -o wide
```

### 1.3 Interactuar con el Pod

```bash
# Ver logs del pod
kubectl logs mi-pod

# Ejecutar comandos en el pod
kubectl exec -it mi-pod -- /bin/bash

# Dentro del pod, probar nginx
curl localhost

# Salir del pod
exit
```

## 🔗 Paso 2: Servicios y Networking

### 2.1 Crear Servicio

**Crear archivo `servicio-basico.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-servicio
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

**Aplicar el servicio:**
```bash
kubectl apply -f servicio-basico.yaml

# Verificar servicio
kubectl get svc
kubectl describe svc mi-servicio
```

### 2.2 Probar Conectividad

```bash
# Crear pod temporal para probar conectividad
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup mi-servicio

# Probar conectividad HTTP
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- mi-servicio
```

### 2.3 Port Forward para Acceso Local

```bash
# Port forward para acceder desde localhost
kubectl port-forward pod/mi-pod 8080:80

# En otra terminal, probar acceso
curl http://localhost:8080
```

## 📦 Paso 3: Deployments y ReplicaSets

### 3.1 Crear Deployment

**Crear archivo `deployment-basico.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

**Aplicar deployment:**
```bash
kubectl apply -f deployment-basico.yaml

# Verificar deployment
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

### 3.2 Escalar Deployment

```bash
# Escalar a 5 réplicas
kubectl scale deployment mi-deployment --replicas=5

# Verificar escalado
kubectl get pods
kubectl get deployment mi-deployment

# Escalar de vuelta a 2 réplicas
kubectl scale deployment mi-deployment --replicas=2
```

### 3.3 Actualizar Deployment

```bash
# Actualizar imagen
kubectl set image deployment/mi-deployment nginx=nginx:1.22

# Ver el rollout en progreso
kubectl rollout status deployment/mi-deployment

# Ver historial de rollouts
kubectl rollout history deployment/mi-deployment

# Rollback si es necesario
kubectl rollout undo deployment/mi-deployment
```

## 🔧 Paso 4: ConfigMaps y Secrets

### 4.1 Crear ConfigMap

**Crear archivo `configmap-basico.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mi-configmap
data:
  database_url: "postgresql://localhost:5432/mydb"
  app_name: "Mi Aplicación"
  debug_mode: "true"
  config.yaml: |
    server:
      port: 8080
      host: "0.0.0.0"
    database:
      host: "localhost"
      port: 5432
      name: "mydb"
```

**Aplicar ConfigMap:**
```bash
kubectl apply -f configmap-basico.yaml

# Verificar ConfigMap
kubectl get configmaps
kubectl describe configmap mi-configmap
```

### 4.2 Crear Secret

**Crear archivo `secret-basico.yaml`:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mi-secret
type: Opaque
data:
  username: YWRtaW4=  # admin en base64
  password: cGFzc3dvcmQ=  # password en base64
```

**Aplicar Secret:**
```bash
kubectl apply -f secret-basico.yaml

# Verificar Secret
kubectl get secrets
kubectl describe secret mi-secret

# Ver contenido (decodificado)
kubectl get secret mi-secret -o jsonpath="{.data.username}" | base64 -d
echo
kubectl get secret mi-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### 4.3 Usar ConfigMap y Secret en Pod

**Crear archivo `pod-con-config.yaml`:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-con-config
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: mi-configmap
          key: database_url
    - name: APP_NAME
      valueFrom:
        configMapKeyRef:
          name: mi-configmap
          key: app_name
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: mi-secret
          key: username
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: mi-secret
          key: password
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: mi-configmap
```

**Aplicar y verificar:**
```bash
kubectl apply -f pod-con-config.yaml

# Verificar variables de entorno
kubectl exec pod-con-config -- env | grep -E "(DATABASE_URL|APP_NAME|USERNAME|PASSWORD)"

# Verificar archivos montados
kubectl exec pod-con-config -- ls -la /etc/config
kubectl exec pod-con-config -- cat /etc/config/config.yaml
```

## 🌐 Paso 5: Ingress y Acceso Externo

### 5.1 Habilitar Ingress en Minikube

```bash
# Habilitar addon de ingress
minikube addons enable ingress

# Verificar que esté habilitado
minikube addons list | grep ingress
```

### 5.2 Crear Ingress

**Crear archivo `ingress-basico.yaml`:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mi-servicio
            port:
              number: 80
```

**Aplicar Ingress:**
```bash
kubectl apply -f ingress-basico.yaml

# Verificar Ingress
kubectl get ingress
kubectl describe ingress mi-ingress
```

### 5.3 Configurar Acceso Local

```bash
# Obtener IP de Minikube
minikube ip

# Agregar entrada a /etc/hosts (Linux/macOS)
echo "$(minikube ip) nginx.local" | sudo tee -a /etc/hosts

# Verificar acceso
curl http://nginx.local
```

## 🧪 Paso 6: Casos de Uso Prácticos

### 6.1 Aplicación Web Completa

**Crear archivo `aplicacion-web.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-content
        configMap:
          name: web-content
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Web App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 GitOps Lab</h1>
                <p>Aplicación web desplegada en Kubernetes</p>
            </div>
            <div>
                <h2>Información del Pod</h2>
                <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
                <script>
                    document.getElementById('hostname').textContent = window.location.hostname;
                    document.getElementById('timestamp').textContent = new Date().toLocaleString();
                </script>
            </div>
        </div>
    </body>
    </html>
```

**Aplicar aplicación:**
```bash
kubectl apply -f aplicacion-web.yaml

# Verificar recursos
kubectl get all -l app=web

# Probar aplicación
kubectl port-forward svc/web-service 8080:80
# En otra terminal: curl http://localhost:8080
```

### 6.2 API con Base de Datos

**Crear archivo `api-database.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-app
  labels:
    app: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: node:18-alpine
        command: ["node"]
        args: ["-e", "
          const express = require('express');
          const app = express();
          app.get('/health', (req, res) => res.json({status: 'OK', timestamp: new Date()}));
          app.get('/info', (req, res) => res.json({
            app: 'GitOps Lab API',
            version: '1.0.0',
            hostname: process.env.HOSTNAME,
            database: process.env.DATABASE_URL
          }));
          app.listen(3000, () => console.log('API running on port 3000'));
        "]
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: mi-configmap
              key: database_url
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

**Aplicar API:**
```bash
kubectl apply -f api-database.yaml

# Verificar API
kubectl get pods -l app=api
kubectl logs -l app=api

# Probar API
kubectl port-forward svc/api-service 3000:3000
# En otra terminal: curl http://localhost:3000/health
```

## ✅ Verificación del Laboratorio

### Checklist de Completitud

- [ ] ✅ Pods creados y funcionando
- [ ] ✅ Servicios configurados
- [ ] ✅ Deployments con múltiples réplicas
- [ ] ✅ ConfigMaps y Secrets utilizados
- [ ] ✅ Ingress configurado
- [ ] ✅ Aplicación web completa
- [ ] ✅ API con variables de entorno

### Comandos de Verificación

```bash
# Ver todos los recursos
kubectl get all

# Ver ConfigMaps y Secrets
kubectl get configmaps,secrets

# Ver Ingress
kubectl get ingress

# Ver logs de aplicaciones
kubectl logs -l app=web
kubectl logs -l app=api
```

## 🎯 Conceptos Clave Aprendidos

1. **Pods**: Unidad básica de despliegue en Kubernetes
2. **Services**: Exposición de aplicaciones dentro del cluster
3. **Deployments**: Gestión de réplicas y actualizaciones
4. **ConfigMaps**: Configuración no sensible
5. **Secrets**: Datos sensibles encriptados
6. **Ingress**: Acceso externo a aplicaciones
7. **Volumes**: Almacenamiento para pods

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 3**: Helm Charts Prácticos
- **Laboratorio 4**: Argo CD en Acción
- **Laboratorio 5**: Casos de Uso GitOps

## 🆘 Solución de Problemas

### Problema: Pod no inicia
```bash
# Ver eventos del pod
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>

# Verificar imagen
kubectl get pod <pod-name> -o yaml
```

### Problema: Servicio no funciona
```bash
# Verificar selector del servicio
kubectl get svc <service-name> -o yaml

# Verificar labels de pods
kubectl get pods --show-labels

# Probar conectividad
kubectl run test --image=busybox --rm -it -- nslookup <service-name>
```

### Problema: Ingress no funciona
```bash
# Verificar addon de ingress
minikube addons list

# Ver logs del controlador
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Verificar DNS
nslookup nginx.local
```

---

**¡Excelente! Has completado el Laboratorio 2. Continúa con el Laboratorio 3 para aprender Helm charts.** 🎉
