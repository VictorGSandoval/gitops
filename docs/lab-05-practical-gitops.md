# Laboratorio 5: Casos de Uso GitOps Prácticos

## 🎯 Objetivo

Aplicar GitOps en escenarios reales mediante casos de uso prácticos. Al finalizar este laboratorio serás capaz de:

- Implementar una aplicación web completa con GitOps
- Configurar API con base de datos usando GitOps
- Gestionar secretos de forma segura
- Implementar monitoreo básico
- Manejar rollbacks y recuperación

## ⏱️ Tiempo Estimado

**150-180 minutos**

## 📋 Prerrequisitos

- Laboratorios 1-4 completados
- Argo CD funcionando
- Repositorio Git configurado
- Charts de Helm creados

## 🌐 Caso de Uso 1: Aplicación Web Completa

### 1.1 Crear Chart de Aplicación Web

**Crear estructura del chart:**
```bash
# Crear directorio para aplicación web
mkdir -p charts/web-app
cd charts/web-app

# Generar estructura básica
helm create web-app
```

**Personalizar `Chart.yaml`:**
```yaml
apiVersion: v2
name: web-app
description: Aplicación web completa para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - web
  - nginx
  - frontend
home: https://github.com/VictorGSandoval/gitops
sources:
  - https://github.com/VictorGSandoval/gitops
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

**Personalizar `values.yaml`:**
```yaml
# Configuración por defecto
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

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
    - host: web-app.local
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

# Configuración de la aplicación
app:
  name: "Web App"
  version: "1.0.0"
  environment: "development"
  description: "Aplicación web completa con GitOps"

# Configuración del contenido
content:
  title: "GitOps Lab - Web App"
  subtitle: "Aplicación web desplegada con GitOps"
  features:
    - "Despliegue automático"
    - "Sincronización continua"
    - "Rollback automático"
    - "Monitoreo integrado"
```

### 1.2 Crear Template de Deployment

**Editar `templates/deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "web-app.fullname" . }}
  labels:
    {{- include "web-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "web-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "web-app.selectorLabels" . | nindent 8 }}
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
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          env:
            - name: APP_NAME
              value: {{ .Values.app.name | quote }}
            - name: APP_VERSION
              value: {{ .Values.app.version | quote }}
            - name: APP_ENVIRONMENT
              value: {{ .Values.app.environment | quote }}
            - name: APP_DESCRIPTION
              value: {{ .Values.app.description | quote }}
          volumeMounts:
            - name: web-content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web-content
          configMap:
            name: {{ include "web-app.fullname" . }}-content
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

### 1.3 Crear Template de ConfigMap

**Crear `templates/configmap.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "web-app.fullname" . }}-content
  labels:
    {{- include "web-app.labels" . | nindent 4 }}
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ .Values.content.title }}</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                line-height: 1.6; 
                color: #333; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
            }
            .container { 
                max-width: 1200px; 
                margin: 0 auto; 
                padding: 20px; 
            }
            .header { 
                background: rgba(255, 255, 255, 0.95); 
                padding: 30px; 
                border-radius: 15px; 
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                margin-bottom: 30px;
                text-align: center;
            }
            .header h1 { 
                color: #2c3e50; 
                margin-bottom: 10px; 
                font-size: 2.5em;
            }
            .header p { 
                color: #7f8c8d; 
                font-size: 1.2em; 
            }
            .content { 
                background: rgba(255, 255, 255, 0.95); 
                padding: 30px; 
                border-radius: 15px; 
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                margin-bottom: 30px;
            }
            .info-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); 
                gap: 20px; 
                margin-bottom: 30px;
            }
            .info-card { 
                background: #f8f9fa; 
                padding: 20px; 
                border-radius: 10px; 
                border-left: 4px solid #3498db;
            }
            .info-card h3 { 
                color: #2c3e50; 
                margin-bottom: 10px; 
            }
            .features { 
                margin-top: 30px; 
            }
            .features h3 { 
                color: #2c3e50; 
                margin-bottom: 20px; 
            }
            .features ul { 
                list-style: none; 
            }
            .features li { 
                background: #e8f5e8; 
                margin: 10px 0; 
                padding: 15px; 
                border-radius: 8px; 
                border-left: 4px solid #27ae60;
            }
            .status { 
                background: #d4edda; 
                color: #155724; 
                padding: 15px; 
                border-radius: 8px; 
                margin-top: 20px; 
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 {{ .Values.content.title }}</h1>
                <p>{{ .Values.content.subtitle }}</p>
            </div>
            
            <div class="content">
                <div class="info-grid">
                    <div class="info-card">
                        <h3>📱 Información de la Aplicación</h3>
                        <p><strong>Nombre:</strong> {{ .Values.app.name }}</p>
                        <p><strong>Versión:</strong> {{ .Values.app.version }}</p>
                        <p><strong>Ambiente:</strong> {{ .Values.app.environment }}</p>
                    </div>
                    
                    <div class="info-card">
                        <h3>🖥️ Información del Pod</h3>
                        <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                        <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
                        <p><strong>User Agent:</strong> <span id="userAgent"></span></p>
                    </div>
                    
                    <div class="info-card">
                        <h3>⚙️ Configuración</h3>
                        <p><strong>Réplicas:</strong> {{ .Values.replicaCount }}</p>
                        <p><strong>Imagen:</strong> {{ .Values.image.repository }}:{{ .Values.image.tag }}</p>
                        <p><strong>Recursos:</strong> {{ .Values.resources.requests.cpu }} CPU, {{ .Values.resources.requests.memory }} RAM</p>
                    </div>
                </div>
                
                <div class="features">
                    <h3>✨ Características de GitOps</h3>
                    <ul>
                        {{- range .Values.content.features }}
                        <li>{{ . }}</li>
                        {{- end }}
                    </ul>
                </div>
                
                <div class="status">
                    <h3>✅ Estado del Sistema</h3>
                    <p>Aplicación funcionando correctamente con GitOps</p>
                </div>
            </div>
        </div>
        
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
            document.getElementById('userAgent').textContent = navigator.userAgent;
        </script>
    </body>
    </html>
```

### 1.4 Crear Valores por Ambiente

**Crear `values-dev.yaml`:**
```yaml
# Valores para desarrollo
replicaCount: 1

image:
  tag: "1.21"

app:
  environment: "development"
  description: "Aplicación web en ambiente de desarrollo"

ingress:
  enabled: true
  hosts:
    - host: web-app-dev.local
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

content:
  title: "GitOps Lab - Web App (DEV)"
  subtitle: "Ambiente de Desarrollo"
  features:
    - "Despliegue automático"
    - "Sincronización continua"
    - "Rollback automático"
    - "Monitoreo integrado"
    - "Desarrollo activo"
```

**Crear `values-prod.yaml`:**
```yaml
# Valores para producción
replicaCount: 3

image:
  tag: "1.21"

app:
  environment: "production"
  description: "Aplicación web en ambiente de producción"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: web-app.gitops-lab.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: web-app-tls
      hosts:
        - web-app.gitops-lab.com

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

content:
  title: "GitOps Lab - Web App (PRODUCTION)"
  subtitle: "Ambiente de Producción"
  features:
    - "Despliegue automático"
    - "Sincronización continua"
    - "Rollback automático"
    - "Monitoreo integrado"
    - "Alta disponibilidad"
    - "Escalabilidad automática"
```

## 🔌 Caso de Uso 2: API con Base de Datos

### 2.1 Crear Chart de API

**Crear estructura del chart:**
```bash
# Crear directorio para API
mkdir -p charts/api-app
cd charts/api-app

# Generar estructura básica
helm create api-app
```

**Personalizar `Chart.yaml`:**
```yaml
apiVersion: v2
name: api-app
description: API REST con base de datos para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
keywords:
  - api
  - rest
  - nodejs
  - postgresql
home: https://github.com/VictorGSandoval/gitops
sources:
  - https://github.com/VictorGSandoval/gitops
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

**Personalizar `values.yaml`:**
```yaml
# Configuración de la API
replicaCount: 2

image:
  repository: node
  pullPolicy: IfNotPresent
  tag: "18-alpine"

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

ingress:
  enabled: false
  className: "nginx"
  annotations: {}
  hosts:
    - host: api-app.local
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

# Configuración de la aplicación
app:
  name: "API App"
  version: "1.0.0"
  environment: "development"
  description: "API REST con base de datos PostgreSQL"

# Configuración de la base de datos
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres123"
    database: "api_app"
    username: "api_user"
    password: "api_password"
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
```

### 2.2 Crear Template de Deployment para API

**Editar `templates/deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "api-app.fullname" . }}
  labels:
    {{- include "api-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "api-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "api-app.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
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
          env:
            - name: APP_NAME
              value: {{ .Values.app.name | quote }}
            - name: APP_VERSION
              value: {{ .Values.app.version | quote }}
            - name: APP_ENVIRONMENT
              value: {{ .Values.app.environment | quote }}
            - name: PORT
              value: {{ .Values.service.targetPort | quote }}
            - name: DATABASE_URL
              value: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "api-app.fullname" . }}-postgresql:5432/{{ .Values.postgresql.auth.database }}"
          volumeMounts:
            - name: app-code
              mountPath: /app
      volumes:
        - name: app-code
          configMap:
            name: {{ include "api-app.fullname" . }}-code
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

### 2.3 Crear Template de ConfigMap para API

**Crear `templates/configmap.yaml`:**
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
        "cors": "^2.8.5",
        "helmet": "^7.0.0"
      }
    }
  server.js: |
    const express = require('express');
    const { Pool } = require('pg');
    const cors = require('cors');
    const helmet = require('helmet');
    
    const app = express();
    const port = process.env.PORT || 3000;
    
    // Middleware
    app.use(helmet());
    app.use(cors());
    app.use(express.json());
    
    // Configuración de la base de datos
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
    
    // Rutas de salud
    app.get('/health', (req, res) => {
      res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        app: process.env.APP_NAME,
        version: process.env.APP_VERSION,
        environment: process.env.APP_ENVIRONMENT
      });
    });
    
    app.get('/ready', async (req, res) => {
      try {
        await pool.query('SELECT 1');
        res.json({ 
          status: 'Ready', 
          timestamp: new Date().toISOString(),
          database: 'Connected'
        });
      } catch (error) {
        res.status(503).json({ 
          status: 'Not Ready', 
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });
    
    // Rutas de la API
    app.get('/api/info', (req, res) => {
      res.json({
        app: process.env.APP_NAME,
        version: process.env.APP_VERSION,
        environment: process.env.APP_ENVIRONMENT,
        hostname: process.env.HOSTNAME,
        timestamp: new Date().toISOString()
      });
    });
    
    app.get('/api/data', async (req, res) => {
      try {
        const result = await pool.query('SELECT NOW() as current_time, version() as db_version');
        res.json({
          data: result.rows[0],
          timestamp: new Date().toISOString(),
          app: process.env.APP_NAME
        });
      } catch (error) {
        res.status(500).json({ 
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });
    
    app.get('/api/users', async (req, res) => {
      try {
        const result = await pool.query('SELECT * FROM users ORDER BY id');
        res.json({
          users: result.rows,
          count: result.rows.length,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        res.status(500).json({ 
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });
    
    app.post('/api/users', async (req, res) => {
      try {
        const { name, email } = req.body;
        const result = await pool.query(
          'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
          [name, email]
        );
        res.status(201).json({
          user: result.rows[0],
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        res.status(500).json({ 
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });
    
    // Inicializar base de datos
    async function initDatabase() {
      try {
        await pool.query(`
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
        console.log('✅ Base de datos inicializada');
      } catch (error) {
        console.error('❌ Error inicializando base de datos:', error);
      }
    }
    
    // Iniciar servidor
    app.listen(port, async () => {
      await initDatabase();
      console.log(`🚀 ${process.env.APP_NAME} v${process.env.APP_VERSION} running on port ${port}`);
      console.log(`📊 Environment: ${process.env.APP_ENVIRONMENT}`);
    });
```

## 🔐 Caso de Uso 3: Gestión de Secretos

### 3.1 Crear Secret para Base de Datos

**Crear archivo `secrets/database-secret.yaml`:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
  namespace: dev
type: Opaque
data:
  username: YXBpX3VzZXI=  # api_user en base64
  password: YXBpX3Bhc3N3b3Jk  # api_password en base64
  database: YXBpX2FwcA==  # api_app en base64
```

### 3.2 Modificar API para Usar Secret

**Actualizar `templates/deployment.yaml` de API:**
```yaml
# ... configuración existente ...
          env:
            - name: APP_NAME
              value: {{ .Values.app.name | quote }}
            - name: APP_VERSION
              value: {{ .Values.app.version | quote }}
            - name: APP_ENVIRONMENT
              value: {{ .Values.app.environment | quote }}
            - name: PORT
              value: {{ .Values.service.targetPort | quote }}
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: database_url
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: password
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: database
# ... resto de la configuración ...
```

## 📊 Caso de Uso 4: Monitoreo Básico

### 4.1 Crear Chart de Monitoreo

**Crear estructura del chart:**
```bash
# Crear directorio para monitoreo
mkdir -p charts/monitoring
cd charts/monitoring

# Generar estructura básica
helm create monitoring
```

**Personalizar `Chart.yaml`:**
```yaml
apiVersion: v2
name: monitoring
description: Stack de monitoreo básico para GitOps Lab
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: prometheus
    version: "19.6.1"
    repository: "https://prometheus-community.github.io/helm-charts"
    condition: prometheus.enabled
  - name: grafana
    version: "6.57.4"
    repository: "https://grafana.github.io/helm-charts"
    condition: grafana.enabled
keywords:
  - monitoring
  - prometheus
  - grafana
home: https://github.com/VictorGSandoval/gitops
sources:
  - https://github.com/VictorGSandoval/gitops
maintainers:
  - name: GitOps Lab Team
    email: team@gitops-lab.com
```

**Personalizar `values.yaml`:**
```yaml
# Configuración de Prometheus
prometheus:
  enabled: true
  server:
    persistentVolume:
      enabled: true
      size: 10Gi
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi

# Configuración de Grafana
grafana:
  enabled: true
  adminPassword: admin123
  service:
    type: ClusterIP
  persistence:
    enabled: true
    size: 5Gi
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

## 🚀 Paso 5: Desplegar Casos de Uso

### 5.1 Desplegar Aplicación Web

```bash
# Volver al directorio raíz
cd /Users/geovani/Documents/LABFAPE/gitops

# Crear aplicación web de desarrollo
argocd app create web-app-dev \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/web-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --helm-set-file values=charts/web-app/values-dev.yaml \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Crear aplicación web de producción
argocd app create web-app-prod \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/web-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --project dev-project \
  --helm-set-file values=charts/web-app/values-prod.yaml \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### 5.2 Desplegar API con Base de Datos

```bash
# Crear aplicación API
argocd app create api-app \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/api-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verificar aplicación
argocd app list
kubectl get all -n dev
```

### 5.3 Desplegar Monitoreo

```bash
# Crear aplicación de monitoreo
argocd app create monitoring-stack \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/monitoring \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace monitoring \
  --project dev-project \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verificar aplicación
argocd app list
kubectl get pods -n monitoring
```

## ✅ Verificación del Laboratorio

### Checklist de Completitud

- [ ] ✅ Aplicación web completa desplegada
- [ ] ✅ API con base de datos funcionando
- [ ] ✅ Secretos configurados y funcionando
- [ ] ✅ Monitoreo básico implementado
- [ ] ✅ Aplicaciones multi-ambiente funcionando
- [ ] ✅ Sincronización automática verificada

### Comandos de Verificación

```bash
# Ver todas las aplicaciones
argocd app list

# Ver recursos por namespace
kubectl get all -n dev
kubectl get all -n prod
kubectl get all -n monitoring

# Probar aplicaciones
kubectl port-forward svc/web-app 8080:80 -n dev
kubectl port-forward svc/api-app 3000:3000 -n dev
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring
```

## 🎯 Conceptos Clave Aprendidos

1. **Aplicaciones Completas**: Despliegue de aplicaciones web completas
2. **API con Base de Datos**: Integración de aplicaciones con bases de datos
3. **Gestión de Secretos**: Manejo seguro de información sensible
4. **Monitoreo**: Implementación de observabilidad básica
5. **Multi-Ambiente**: Gestión de diferentes entornos
6. **GitOps Real**: Implementación práctica de GitOps

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 6**: CI/CD Integration
- **Laboratorio 7**: Troubleshooting Avanzado
- **Laboratorio 8**: Optimización de Rendimiento

## 🆘 Solución de Problemas

### Problema: Aplicación web no carga
```bash
# Verificar pods
kubectl get pods -n dev

# Ver logs
kubectl logs -l app.kubernetes.io/name=web-app -n dev

# Verificar servicio
kubectl get svc -n dev
```

### Problema: API no conecta a base de datos
```bash
# Verificar pods de API
kubectl get pods -n dev

# Ver logs de API
kubectl logs -l app.kubernetes.io/name=api-app -n dev

# Verificar pods de PostgreSQL
kubectl get pods -n dev | grep postgresql
```

### Problema: Monitoreo no funciona
```bash
# Verificar pods de monitoreo
kubectl get pods -n monitoring

# Ver logs de Prometheus
kubectl logs -l app.kubernetes.io/name=prometheus -n monitoring

# Ver logs de Grafana
kubectl logs -l app.kubernetes.io/name=grafana -n monitoring
```

---

**¡Excelente! Has completado el Laboratorio 5. Has implementado casos de uso prácticos completos de GitOps.** 🎉
