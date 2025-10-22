# Laboratorio 5: Casos de Uso Prácticos

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:
- Implementar un stack completo de microservicios
- Configurar CI/CD con GitHub Actions
- Gestionar secretos de forma segura
- Implementar monitoreo y observabilidad
- Configurar backup y recuperación
- Manejar escalabilidad automática

## ⏱️ Tiempo Estimado

**120-150 minutos**

## 📋 Prerrequisitos

- Laboratorios 1-4 completados
- Cuenta en GitHub con repositorio configurado
- Conocimientos de CI/CD y microservicios

## 🏗️ Caso de Uso 1: Stack de Microservicios

### 1.1 Arquitectura del sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Auth Service  │
│   (React)       │◄───┤   (Kong)        │◄───┤   (Node.js)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Service  │    │   Order Service │    │   Payment Svc   │
│   (Node.js)     │    │   (Python)      │    │   (Java)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │   Database      │
                        │   (PostgreSQL)  │
                        └─────────────────┘
```

### 1.2 Configuración del API Gateway

**apps/charts/kong-gateway/Chart.yaml:**
```yaml
apiVersion: v2
name: kong-gateway
description: API Gateway con Kong para microservicios
type: application
version: 0.1.0
appVersion: "3.4"
dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

**apps/charts/kong-gateway/values.yaml:**
```yaml
replicaCount: 2

image:
  repository: kong
  tag: "3.4"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: api.gitops-lab.com
      paths:
        - path: /
          pathType: Prefix

kong:
  env:
    database: "postgres"
    pg_host: "kong-gateway-postgresql"
    pg_port: "5432"
    pg_database: "kong"
    pg_user: "kong"
    pg_password: "kong"

postgresql:
  enabled: true
  auth:
    postgresPassword: "kong"
    database: "kong"
    username: "kong"
    password: "kong"
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

### 1.3 Servicio de Autenticación

**apps/charts/auth-service/Chart.yaml:**
```yaml
apiVersion: v2
name: auth-service
description: Servicio de autenticación JWT
type: application
version: 0.1.0
appVersion: "1.0.0"
```

**apps/charts/auth-service/values.yaml:**
```yaml
replicaCount: 2

image:
  repository: node
  tag: "18-alpine"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: auth.gitops-lab.com
      paths:
        - path: /
          pathType: Prefix

env:
  NODE_ENV: "production"
  JWT_SECRET: "your-jwt-secret"
  JWT_EXPIRES_IN: "24h"
  DATABASE_URL: "postgresql://user:password@postgresql:5432/authdb"

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## 🔄 Caso de Uso 2: CI/CD con GitHub Actions

### 2.1 Workflow de CI/CD

**.github/workflows/ci-cd.yml:**
```yaml
name: GitOps CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Run linting
      run: npm run lint
    
    - name: Build application
      run: npm run build

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-push:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Argo CD CLI
      uses: argoproj/argo-cd-cli@v1
      with:
        version: '2.7.0'
    
    - name: Login to Argo CD
      run: |
        argocd login ${{ secrets.ARGOCD_SERVER }} \
          --username ${{ secrets.ARGOCD_USERNAME }} \
          --password ${{ secrets.ARGOCD_PASSWORD }} \
          --insecure
    
    - name: Update image tag in values
      run: |
        sed -i "s|image: .*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest|g" \
          apps/overlays/prod/values.yaml
    
    - name: Commit and push changes
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add apps/overlays/prod/values.yaml
        git commit -m "Update image tag to latest [skip ci]"
        git push
    
    - name: Sync Argo CD application
      run: |
        argocd app sync ${{ secrets.ARGOCD_APP_NAME }} \
          --server ${{ secrets.ARGOCD_SERVER }} \
          --auth-token ${{ secrets.ARGOCD_TOKEN }}
```

### 2.2 Configuración de secretos

**Configurar en GitHub Secrets:**
```bash
ARGOCD_SERVER=https://argocd.gitops-lab.com
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=your-argocd-password
ARGOCD_APP_NAME=prod-nginx-app
ARGOCD_TOKEN=your-argocd-token
```

## 🔐 Caso de Uso 3: Gestión de Secretos

### 3.1 Configuración de External Secrets

**apps/base/external-secrets.yaml:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.gitops-lab.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "gitops-lab"
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets-system
```

### 3.2 Secretos para base de datos

**apps/base/database-secrets.yaml:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secrets
  namespace: dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: database
        property: username
    - secretKey: password
      remoteRef:
        key: database
        property: password
    - secretKey: host
      remoteRef:
        key: database
        property: host
    - secretKey: port
      remoteRef:
        key: database
        property: port
```

## 📊 Caso de Uso 4: Monitoreo y Observabilidad

### 4.1 Stack completo de monitoreo

**argocd/applications/observability-stack.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: observability-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://grafana.github.io/helm-charts
    targetRevision: 6.57.4
    chart: loki-stack
    helm:
      values: |
        loki:
          enabled: true
          persistence:
            enabled: true
            size: 10Gi
          config:
            auth_enabled: false
            server:
              http_listen_port: 3100
            ingester:
              lifecycler:
                address: 127.0.0.1
                ring:
                  kvstore:
                    store: inmemory
                  replication_factor: 1
                final_sleep: 0s
              chunk_idle_period: 5m
              chunk_retain_period: 30s
            schema_config:
              configs:
                - from: 2020-10-24
                  store: boltdb-shipper
                  object_store: filesystem
                  schema: v11
                  index:
                    prefix: index_
                    period: 24h
        
        promtail:
          enabled: true
          config:
            clients:
              - url: http://loki:3100/loki/api/v1/push
        
        grafana:
          enabled: true
          adminPassword: admin123
          service:
            type: LoadBalancer
          ingress:
            enabled: true
            hosts:
              - grafana.gitops-lab.com
            annotations:
              kubernetes.io/ingress.class: nginx
          persistence:
            enabled: true
            size: 10Gi
          dashboardProviders:
            dashboardproviders.yaml:
              apiVersion: 1
              providers:
                - name: 'default'
                  orgId: 1
                  folder: ''
                  type: file
                  disableDeletion: false
                  editable: true
                  options:
                    path: /var/lib/grafana/dashboards/default
          dashboards:
            default:
              kubernetes-cluster:
                gnetId: 7249
                revision: 1
                datasource: Prometheus
              kubernetes-pods:
                gnetId: 6336
                revision: 1
                datasource: Prometheus
              argocd:
                gnetId: 14584
                revision: 1
                datasource: Prometheus
  destination:
    server: https://kubernetes.default.svc
    namespace: observability
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 4.2 Alertas personalizadas

**apps/base/alerting-rules.yaml:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: gitops-lab-alerts
  namespace: observability
spec:
  groups:
  - name: gitops-lab
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} errors per second"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is crash looping"
    
    - alert: ArgoCDAppOutOfSync
      expr: argocd_app_info{sync_status!="Synced"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "ArgoCD application out of sync"
        description: "Application {{ $labels.name }} is out of sync"
    
    - alert: HighCPUUsage
      expr: (100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage"
        description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
    
    - alert: HighMemoryUsage
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage"
        description: "Memory usage is {{ $value }}% on {{ $labels.instance }}"
```

## 🔄 Caso de Uso 5: Backup y Recuperación

### 5.1 Configuración de Velero

**argocd/applications/velero.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: velero
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://vmware-tanzu.github.io/helm-charts
    targetRevision: 3.0.1
    chart: velero
    helm:
      values: |
        configuration:
          provider: aws
          backupStorageLocation:
            bucket: gitops-lab-backups
            config:
              region: us-west-2
          volumeSnapshotLocation:
            config:
              region: us-west-2
        
        credentials:
          useSecret: true
          secretContents:
            cloud: |
              [default]
              aws_access_key_id=your-access-key
              aws_secret_access_key=your-secret-key
        
        initContainers:
          - name: velero-plugin-for-aws
            image: velero/velero-plugin-for-aws:v1.7.0
            volumeMounts:
              - mountPath: /target
                name: plugins
        
        serviceAccount:
          server:
            create: true
            annotations:
              eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT-ID:role/velero-backup-role
        
        rbac:
          server:
            create: true
            serviceAccount:
              name: velero
              annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT-ID:role/velero-backup-role
  destination:
    server: https://kubernetes.default.svc
    namespace: velero
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 5.2 Políticas de backup

**apps/base/backup-schedule.yaml:**
```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  template:
    includedNamespaces:
      - dev
      - prod
      - monitoring
      - observability
    excludedResources:
      - events
      - events.events.k8s.io
    ttl: "168h"  # 7 days
    storageLocation: default
    volumeSnapshotLocations:
      - default
---
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: weekly-backup
  namespace: velero
spec:
  schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
  template:
    includedNamespaces:
      - dev
      - prod
      - monitoring
      - observability
    excludedResources:
      - events
      - events.events.k8s.io
    ttl: "720h"  # 30 days
    storageLocation: default
    volumeSnapshotLocations:
      - default
```

## 🚀 Caso de Uso 6: Escalabilidad Automática

### 6.1 Configuración de HPA

**apps/base/hpa-config.yaml:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
        - type: Pods
          value: 2
          periodSeconds: 60
      selectPolicy: Max
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "100"
```

### 6.2 Configuración de VPA

**argocd/applications/vpa.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vpa
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.fairwinds.com/stable
    targetRevision: 1.4.0
    chart: vpa
    helm:
      values: |
        recommender:
          enabled: true
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
        
        updater:
          enabled: true
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
        
        admissionController:
          enabled: true
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
  destination:
    server: https://kubernetes.default.svc
    namespace: vpa-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## ✅ Verificación del Laboratorio

### Checklist de completitud:

- [ ] ✅ Stack de microservicios desplegado
- [ ] ✅ CI/CD pipeline funcionando
- [ ] ✅ Gestión de secretos implementada
- [ ] ✅ Monitoreo y observabilidad configurada
- [ ] ✅ Backup y recuperación funcionando
- [ ] ✅ Escalabilidad automática configurada

### Comandos de verificación:

```bash
# Verificar microservicios
kubectl get pods -n dev
kubectl get svc -n dev

# Verificar CI/CD
gh workflow list

# Verificar secretos
kubectl get secrets -n dev

# Verificar monitoreo
kubectl get pods -n observability

# Verificar backup
velero backup get

# Verificar escalabilidad
kubectl get hpa -n dev
kubectl get vpa -n dev
```

## 🎯 Conceptos Clave Aprendidos

1. **Microservicios:** Arquitectura distribuida con API Gateway
2. **CI/CD:** Automatización completa del ciclo de vida
3. **Gestión de Secretos:** Integración con sistemas externos
4. **Observabilidad:** Monitoreo completo del sistema
5. **Backup:** Recuperación ante desastres
6. **Escalabilidad:** Adaptación automática a la carga

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 6:** Troubleshooting Avanzado
- **Laboratorio 7:** Optimización de Rendimiento
- **Laboratorio 8:** Seguridad Avanzada

## 🆘 Solución de Problemas

### Problema: Microservicios no se comunican
```bash
# Verificar servicios
kubectl get svc -n dev

# Verificar endpoints
kubectl get endpoints -n dev

# Verificar conectividad
kubectl exec -it <pod-name> -n dev -- curl <service-name>
```

### Problema: CI/CD no funciona
```bash
# Verificar secretos de GitHub
gh secret list

# Verificar logs de GitHub Actions
gh run list

# Verificar conectividad con Argo CD
argocd app list
```

### Problema: Monitoreo no funciona
```bash
# Verificar Prometheus
kubectl get pods -n observability

# Verificar Grafana
kubectl get svc -n observability

# Verificar alertas
kubectl get prometheusrules -n observability
```

---

**¡Excelente! Has completado el Laboratorio 5. Continúa con el Laboratorio 6 para troubleshooting avanzado.** 🎉
