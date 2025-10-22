# Laboratorio 3: Aplicaciones con Helm

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:
- Entender el concepto de Helm charts
- Crear charts personalizados
- Configurar valores para diferentes ambientes
- Integrar Helm con Argo CD
- Gestionar dependencias entre charts

## ⏱️ Tiempo Estimado

**60-75 minutos**

## 📋 Prerrequisitos

- Laboratorio 2 completado
- Conocimientos básicos de Kubernetes
- Cluster funcionando con Argo CD

## 📦 Paso 1: Introducción a Helm

### 1.1 ¿Qué es Helm?

Helm es el gestor de paquetes para Kubernetes. Permite:
- Empaquetar aplicaciones Kubernetes
- Gestionar dependencias
- Simplificar despliegues
- Facilitar actualizaciones y rollbacks

### 1.2 Conceptos clave

- **Chart:** Paquete de recursos Kubernetes
- **Release:** Instancia desplegada de un chart
- **Repository:** Repositorio de charts
- **Values:** Archivos de configuración

### 1.3 Verificar instalación

```bash
# Verificar Helm instalado
helm version

# Verificar repositorios
helm repo list

# Agregar repositorio oficial
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

## 🏗️ Paso 2: Crear Chart Personalizado

### 2.1 Estructura de directorios

```bash
# Crear estructura para aplicaciones
mkdir -p apps/{base,overlays/{dev,staging,prod},charts/{nginx-app,api-app,monitoring}}

# Verificar estructura
tree apps/
```

### 2.2 Crear chart básico de Nginx

**apps/charts/nginx-app/Chart.yaml:**
```yaml
apiVersion: v2
name: nginx-app
description: Aplicación web Nginx para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.21"
keywords:
  - nginx
  - web
  - gitops
home: https://nginx.org/
sources:
  - https://github.com/nginx/nginx
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

**apps/charts/nginx-app/values.yaml:**
```yaml
# Configuración por defecto
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 80

ingress:
  enabled: false
  className: "nginx"
  annotations: {}
  hosts:
    - host: nginx.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

# Configuración personalizada
config:
  customHtml: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Nginx App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
            .content { padding: 20px; background: #ecf0f1; border-radius: 5px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 GitOps Lab</h1>
                <p>Aplicación Nginx desplegada con Helm</p>
            </div>
            <div class="content">
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

**apps/charts/nginx-app/templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nginx-app.fullname" . }}
  labels:
    {{- include "nginx-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "nginx-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "nginx-app.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: custom-html
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html
      volumes:
        - name: custom-html
          configMap:
            name: {{ include "nginx-app.fullname" . }}-config
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

**apps/charts/nginx-app/templates/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "nginx-app.fullname" . }}
  labels:
    {{- include "nginx-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- include "nginx-app.selectorLabels" . | nindent 4 }}
```

**apps/charts/nginx-app/templates/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "nginx-app.fullname" . }}-config
  labels:
    {{- include "nginx-app.labels" . | nindent 4 }}
data:
  index.html: |
{{ .Values.config.customHtml | indent 4 }}
```

**apps/charts/nginx-app/templates/ingress.yaml:**
```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "nginx-app.fullname" . }}
  labels:
    {{- include "nginx-app.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "nginx-app.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

**apps/charts/nginx-app/templates/_helpers.tpl:**
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "nginx-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "nginx-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nginx-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nginx-app.labels" -}}
helm.sh/chart: {{ include "nginx-app.chart" . }}
{{ include "nginx-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nginx-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nginx-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

## 🌍 Paso 3: Configuración por Ambiente

### 3.1 Valores para Desarrollo

**apps/overlays/dev/nginx-values.yaml:**
```yaml
# Configuración para ambiente de desarrollo
replicaCount: 1

image:
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: nginx-dev.local
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

config:
  customHtml: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - DEV Environment</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #e8f5e8; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #27ae60; color: white; padding: 20px; border-radius: 5px; }
            .content { padding: 20px; background: white; border-radius: 5px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 GitOps Lab - DEV</h1>
                <p>Ambiente de Desarrollo</p>
            </div>
            <div class="content">
                <h2>Información del Pod</h2>
                <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                <p><strong>Environment:</strong> Development</p>
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

### 3.2 Valores para Producción

**apps/overlays/prod/nginx-values.yaml:**
```yaml
# Configuración para ambiente de producción
replicaCount: 3

image:
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: nginx.gitops-lab.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nginx-tls
      hosts:
        - nginx.gitops-lab.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

config:
  customHtml: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Production</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f8f9fa; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
            .content { padding: 20px; background: white; border-radius: 5px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 GitOps Lab - PRODUCTION</h1>
                <p>Ambiente de Producción</p>
            </div>
            <div class="content">
                <h2>Información del Pod</h2>
                <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                <p><strong>Environment:</strong> Production</p>
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

## 🚀 Paso 4: Desplegar con Helm

### 4.1 Instalar chart localmente

```bash
# Navegar al directorio del chart
cd apps/charts/nginx-app

# Verificar chart
helm lint .

# Instalar en desarrollo
helm install nginx-dev . -f ../../overlays/dev/nginx-values.yaml --namespace dev --create-namespace

# Verificar instalación
helm list -n dev
kubectl get pods -n dev
```

### 4.2 Verificar despliegue

```bash
# Ver servicios
kubectl get svc -n dev

# Ver ingress
kubectl get ingress -n dev

# Probar aplicación (si tienes ingress configurado)
curl -H "Host: nginx-dev.local" http://localhost
```

## 🔄 Paso 5: Integración con Argo CD

### 5.1 Crear aplicación Argo CD

**apps/base/nginx-app.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/tu-usuario/gitops-lab.git
    targetRevision: HEAD
    path: apps/charts/nginx-app
    helm:
      valueFiles:
        - ../../overlays/dev/nginx-values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 5.2 Aplicar configuración

```bash
# Aplicar aplicación Argo CD
kubectl apply -f apps/base/nginx-app.yaml

# Verificar aplicación
argocd app get nginx-app

# Sincronizar
argocd app sync nginx-app
```

## 📊 Paso 6: Crear Chart de API

### 6.1 Chart para API REST

**apps/charts/api-app/Chart.yaml:**
```yaml
apiVersion: v2
name: api-app
description: API REST para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - api
  - rest
  - nodejs
dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

**apps/charts/api-app/values.yaml:**
```yaml
# Configuración de la API
replicaCount: 2

image:
  repository: node
  pullPolicy: IfNotPresent
  tag: "18-alpine"

service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

ingress:
  enabled: false
  className: "nginx"
  hosts:
    - host: api.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Configuración de la aplicación
app:
  name: "GitOps Lab API"
  version: "1.0.0"
  port: 3000

# Base de datos PostgreSQL
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres"
    database: "gitops_lab"
  primary:
    persistence:
      enabled: true
      size: 8Gi
```

**apps/charts/api-app/templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "api-app.fullname" . }}
  labels:
    {{- include "api-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "api-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "api-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          env:
            - name: APP_NAME
              value: {{ .Values.app.name | quote }}
            - name: APP_VERSION
              value: {{ .Values.app.version | quote }}
            - name: PORT
              value: {{ .Values.app.port | quote }}
            - name: DATABASE_URL
              value: "postgresql://postgres:{{ .Values.postgresql.auth.postgresPassword }}@{{ include "api-app.fullname" . }}-postgresql:5432/{{ .Values.postgresql.auth.database }}"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: app-code
              mountPath: /app
      volumes:
        - name: app-code
          configMap:
            name: {{ include "api-app.fullname" . }}-code
```

**apps/charts/api-app/templates/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "api-app.fullname" . }}-code
  labels:
    {{- include "api-app.labels" . | nindent 4 }}
data:
  package.json: |
    {
      "name": "gitops-lab-api",
      "version": "1.0.0",
      "description": "API REST para GitOps Lab",
      "main": "server.js",
      "scripts": {
        "start": "node server.js",
        "dev": "nodemon server.js"
      },
      "dependencies": {
        "express": "^4.18.2",
        "pg": "^8.11.0",
        "cors": "^2.8.5"
      }
    }
  server.js: |
    const express = require('express');
    const { Pool } = require('pg');
    const cors = require('cors');
    
    const app = express();
    const port = process.env.PORT || 3000;
    
    app.use(cors());
    app.use(express.json());
    
    // Configuración de la base de datos
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
    
    // Rutas
    app.get('/health', (req, res) => {
      res.json({ status: 'OK', timestamp: new Date().toISOString() });
    });
    
    app.get('/ready', async (req, res) => {
      try {
        await pool.query('SELECT 1');
        res.json({ status: 'Ready', timestamp: new Date().toISOString() });
      } catch (error) {
        res.status(503).json({ status: 'Not Ready', error: error.message });
      }
    });
    
    app.get('/api/info', (req, res) => {
      res.json({
        app: process.env.APP_NAME,
        version: process.env.APP_VERSION,
        hostname: process.env.HOSTNAME,
        timestamp: new Date().toISOString()
      });
    });
    
    app.get('/api/data', async (req, res) => {
      try {
        const result = await pool.query('SELECT NOW() as current_time, version() as db_version');
        res.json({
          data: result.rows[0],
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    app.listen(port, () => {
      console.log(`🚀 ${process.env.APP_NAME} v${process.env.APP_VERSION} running on port ${port}`);
    });
```

## ✅ Verificación del Laboratorio

### Checklist de completitud:

- [ ] ✅ Charts personalizados creados
- [ ] ✅ Configuración por ambiente implementada
- [ ] ✅ Aplicaciones desplegadas con Helm
- [ ] ✅ Integración con Argo CD funcionando
- [ ] ✅ Charts con dependencias configuradas
- [ ] ✅ Aplicaciones accesibles y funcionando

### Comandos de verificación:

```bash
# Verificar charts
helm list -A

# Verificar aplicaciones Argo CD
argocd app list

# Verificar pods
kubectl get pods -A

# Probar aplicaciones
curl http://nginx-dev.local
curl http://api-dev.local/api/info
```

## 🎯 Conceptos Clave Aprendidos

1. **Helm Charts:** Empaquetado de aplicaciones Kubernetes
2. **Values Files:** Configuración específica por ambiente
3. **Templates:** Generación dinámica de manifiestos
4. **Dependencies:** Gestión de dependencias entre charts
5. **GitOps Integration:** Despliegue automático desde Git

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 4:** GitOps Avanzado con Argo CD
- **Laboratorio 5:** Casos de Uso Complejos
- **Laboratorio 6:** Monitoreo y Observabilidad

## 🆘 Solución de Problemas

### Problema: Chart no se instala
```bash
# Verificar sintaxis
helm lint .

# Verificar templates
helm template . --debug

# Instalar con debug
helm install --debug --dry-run .
```

### Problema: Aplicación no responde
```bash
# Verificar pods
kubectl get pods -n <namespace>

# Ver logs
kubectl logs -f deployment/<app-name> -n <namespace>

# Verificar servicios
kubectl get svc -n <namespace>
```

### Problema: Argo CD no sincroniza
```bash
# Verificar aplicación
argocd app get <app-name>

# Forzar sincronización
argocd app sync <app-name> --force

# Ver logs de Argo CD
kubectl logs -f deployment/argocd-application-controller -n argocd
```

---

**¡Excelente! Has completado el Laboratorio 3. Continúa con el Laboratorio 4 para aprender sobre GitOps avanzado.** 🎉
