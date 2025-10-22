# Laboratorio 3: Helm Charts Prácticos

## 🎯 Objetivo

Dominar Helm charts mediante la creación manual de charts personalizados. Al finalizar este laboratorio serás capaz de:

- Crear charts de Helm desde cero
- Entender templates y valores
- Gestionar dependencias entre charts
- Testing y debugging de charts

## ⏱️ Tiempo Estimado

**120-150 minutos**

## 📋 Prerrequisitos

- Laboratorios 1-2 completados
- Helm instalado y funcionando
- Conocimientos básicos de Kubernetes
- Conocimientos básicos de YAML

## 📦 Paso 1: Fundamentos de Helm

### 1.1 Explorar Helm

```bash
# Ver versión de Helm
helm version

# Ver repositorios disponibles
helm repo list

# Agregar repositorio oficial
helm repo add stable https://charts.helm.sh/stable

# Actualizar repositorios
helm repo update

# Buscar charts disponibles
helm search repo nginx
helm search repo postgresql
```

### 1.2 Instalar Chart Básico

```bash
# Instalar nginx usando Helm
helm install mi-nginx stable/nginx-ingress --namespace default

# Ver releases instalados
helm list

# Ver recursos creados
kubectl get all

# Ver valores del chart
helm get values mi-nginx
```

### 1.3 Explorar Chart Instalado

```bash
# Ver manifiestos generados
helm get manifest mi-nginx

# Ver historial de releases
helm history mi-nginx

# Ver información del release
helm status mi-nginx

# Desinstalar chart
helm uninstall mi-nginx
```

## 🏗️ Paso 2: Crear Chart Personalizado

### 2.1 Generar Estructura de Chart

```bash
# Crear directorio para nuestro chart
mkdir -p charts/mi-aplicacion
cd charts/mi-aplicacion

# Generar estructura básica de chart
helm create mi-aplicacion

# Ver estructura creada
tree mi-aplicacion
```

**Estructura generada:**
```
mi-aplicacion/
├── Chart.yaml          # Metadatos del chart
├── values.yaml         # Valores por defecto
├── templates/          # Templates de Kubernetes
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl    # Funciones auxiliares
│   └── NOTES.txt       # Notas de instalación
└── charts/             # Dependencias
```

### 2.2 Personalizar Chart.yaml

**Editar `Chart.yaml`:**
```yaml
apiVersion: v2
name: mi-aplicacion
description: Aplicación web personalizada para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - web
  - nginx
  - gitops
home: https://github.com/VictorGSandoval/gitops
sources:
  - https://github.com/VictorGSandoval/gitops
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

### 2.3 Personalizar values.yaml

**Editar `values.yaml`:**
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
    - host: mi-app.local
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
app:
  name: "Mi Aplicación"
  version: "1.0.0"
  environment: "development"

config:
  customHtml: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitOps Lab - Mi Aplicación</title>
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
                <h1>🚀 {{ .Values.app.name }}</h1>
                <p>Versión: {{ .Values.app.version }}</p>
            </div>
            <div class="content">
                <h2>Información del Pod</h2>
                <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                <p><strong>Environment:</strong> {{ .Values.app.environment }}</p>
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

## 🎨 Paso 3: Personalizar Templates

### 3.1 Modificar Deployment Template

**Editar `templates/deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mi-aplicacion.fullname" . }}
  labels:
    {{- include "mi-aplicacion.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "mi-aplicacion.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "mi-aplicacion.selectorLabels" . | nindent 8 }}
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
          env:
            - name: APP_NAME
              value: {{ .Values.app.name | quote }}
            - name: APP_VERSION
              value: {{ .Values.app.version | quote }}
            - name: ENVIRONMENT
              value: {{ .Values.app.environment | quote }}
          volumeMounts:
            - name: custom-html
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html
      volumes:
        - name: custom-html
          configMap:
            name: {{ include "mi-aplicacion.fullname" . }}-config
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

### 3.2 Crear ConfigMap Template

**Crear `templates/configmap.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mi-aplicacion.fullname" . }}-config
  labels:
    {{- include "mi-aplicacion.labels" . | nindent 4 }}
data:
  index.html: |
{{ .Values.config.customHtml | indent 4 }}
  app.properties: |
    app.name={{ .Values.app.name }}
    app.version={{ .Values.app.version }}
    app.environment={{ .Values.app.environment }}
```

### 3.3 Modificar Service Template

**Editar `templates/service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "mi-aplicacion.fullname" . }}
  labels:
    {{- include "mi-aplicacion.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- include "mi-aplicacion.selectorLabels" . | nindent 4 }}
```

### 3.4 Modificar Ingress Template

**Editar `templates/ingress.yaml`:**
```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mi-aplicacion.fullname" . }}
  labels:
    {{- include "mi-aplicacion.labels" . | nindent 4 }}
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
                name: {{ include "mi-aplicacion.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

## 🧪 Paso 4: Testing y Debugging

### 4.1 Validar Chart

```bash
# Volver al directorio del chart
cd charts/mi-aplicacion

# Validar sintaxis del chart
helm lint mi-aplicacion

# Ver templates generados (dry-run)
helm template mi-aplicacion mi-aplicacion

# Ver templates con valores específicos
helm template mi-aplicacion mi-aplicacion --set replicaCount=3
```

### 4.2 Instalar Chart

```bash
# Instalar chart en modo dry-run
helm install mi-aplicacion mi-aplicacion --dry-run --debug

# Instalar chart real
helm install mi-aplicacion mi-aplicacion --namespace default

# Verificar instalación
helm list
kubectl get all
```

### 4.3 Probar Aplicación

```bash
# Ver pods
kubectl get pods

# Ver logs
kubectl logs -l app.kubernetes.io/name=mi-aplicacion

# Port forward para probar
kubectl port-forward svc/mi-aplicacion 8080:80

# En otra terminal, probar aplicación
curl http://localhost:8080
```

## 🔄 Paso 5: Gestión de Valores

### 5.1 Crear Valores por Ambiente

**Crear `values-dev.yaml`:**
```yaml
# Valores para desarrollo
replicaCount: 1

image:
  tag: "1.21"

app:
  environment: "development"

ingress:
  enabled: true
  hosts:
    - host: mi-app-dev.local
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
        <title>GitOps Lab - DEV</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #e8f5e8; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #27ae60; color: white; padding: 20px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 Mi Aplicación - DEV</h1>
                <p>Ambiente de Desarrollo</p>
            </div>
            <div>
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

**Crear `values-prod.yaml`:**
```yaml
# Valores para producción
replicaCount: 3

image:
  tag: "1.21"

app:
  environment: "production"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: mi-app.gitops-lab.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: mi-app-tls
      hosts:
        - mi-app.gitops-lab.com

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
        <title>GitOps Lab - PRODUCTION</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f8f9fa; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 Mi Aplicación - PRODUCTION</h1>
                <p>Ambiente de Producción</p>
            </div>
            <div>
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

### 5.2 Instalar con Diferentes Valores

```bash
# Instalar versión de desarrollo
helm install mi-aplicacion-dev mi-aplicacion -f values-dev.yaml --namespace dev --create-namespace

# Instalar versión de producción
helm install mi-aplicacion-prod mi-aplicacion -f values-prod.yaml --namespace prod --create-namespace

# Ver releases
helm list --all-namespaces

# Ver recursos en cada namespace
kubectl get all -n dev
kubectl get all -n prod
```

## 🔗 Paso 6: Dependencias entre Charts

### 6.1 Crear Chart de Base de Datos

```bash
# Crear chart para base de datos
cd charts
helm create mi-database

# Editar Chart.yaml para base de datos
```

**Editar `mi-database/Chart.yaml`:**
```yaml
apiVersion: v2
name: mi-database
description: Base de datos PostgreSQL para GitOps Lab
type: application
version: 0.1.0
appVersion: "13.0"
dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

**Editar `mi-database/values.yaml`:**
```yaml
# Configuración de PostgreSQL
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres123"
    database: "mi_aplicacion"
  primary:
    persistence:
      enabled: true
      size: 8Gi
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi

# Configuración de la aplicación
app:
  name: "Mi Aplicación"
  version: "1.0.0"
  environment: "development"
```

### 6.2 Agregar Dependencia al Chart Principal

**Editar `mi-aplicacion/Chart.yaml`:**
```yaml
apiVersion: v2
name: mi-aplicacion
description: Aplicación web personalizada para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: mi-database
    version: "0.1.0"
    repository: "file://../mi-database"
    condition: database.enabled
keywords:
  - web
  - nginx
  - gitops
home: https://github.com/VictorGSandoval/gitops
sources:
  - https://github.com/VictorGSandoval/gitops
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

**Agregar a `mi-aplicacion/values.yaml`:**
```yaml
# ... configuración existente ...

# Configuración de base de datos
database:
  enabled: true
  postgresql:
    auth:
      postgresPassword: "postgres123"
      database: "mi_aplicacion"
```

### 6.3 Instalar con Dependencias

```bash
# Actualizar dependencias
helm dependency update mi-aplicacion

# Ver dependencias
helm dependency list mi-aplicacion

# Instalar con dependencias
helm install mi-aplicacion-completa mi-aplicacion --set database.enabled=true

# Verificar instalación
kubectl get all
```

## ✅ Verificación del Laboratorio

### Checklist de Completitud

- [ ] ✅ Chart personalizado creado
- [ ] ✅ Templates modificados
- [ ] ✅ Valores por ambiente configurados
- [ ] ✅ Chart instalado y funcionando
- [ ] ✅ Dependencias configuradas
- [ ] ✅ Testing realizado

### Comandos de Verificación

```bash
# Ver charts instalados
helm list --all-namespaces

# Ver recursos
kubectl get all --all-namespaces

# Ver dependencias
helm dependency list mi-aplicacion

# Probar aplicaciones
kubectl port-forward svc/mi-aplicacion 8080:80
```

## 🎯 Conceptos Clave Aprendidos

1. **Helm Charts**: Empaquetado de aplicaciones Kubernetes
2. **Templates**: Generación dinámica de manifiestos
3. **Values**: Configuración específica por ambiente
4. **Dependencies**: Gestión de dependencias entre charts
5. **Testing**: Validación y debugging de charts
6. **Multi-Environment**: Configuración por ambiente

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 4**: Argo CD en Acción
- **Laboratorio 5**: Casos de Uso GitOps

## 🆘 Solución de Problemas

### Problema: Chart no se instala
```bash
# Verificar sintaxis
helm lint mi-aplicacion

# Ver templates generados
helm template mi-aplicacion mi-aplicacion --debug

# Ver logs de instalación
helm install mi-aplicacion mi-aplicacion --debug --dry-run
```

### Problema: Templates no funcionan
```bash
# Verificar sintaxis de templates
helm template mi-aplicacion mi-aplicacion

# Verificar valores
helm get values mi-aplicacion

# Ver manifiestos generados
helm get manifest mi-aplicacion
```

### Problema: Dependencias no se instalan
```bash
# Actualizar dependencias
helm dependency update mi-aplicacion

# Ver dependencias
helm dependency list mi-aplicacion

# Instalar dependencias manualmente
helm install mi-database ../mi-database
```

---

**¡Excelente! Has completado el Laboratorio 3. Continúa con el Laboratorio 4 para aprender Argo CD.** 🎉
