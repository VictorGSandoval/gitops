# Laboratorio 4: GitOps Avanzado con Argo CD

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:
- Configurar proyectos y políticas de Argo CD
- Implementar sincronización automática avanzada
- Gestionar secretos de forma segura
- Configurar monitoreo y alertas
- Implementar rollbacks automáticos
- Crear aplicaciones multi-ambiente

## ⏱️ Tiempo Estimado

**90-120 minutos**

## 📋 Prerrequisitos

- Laboratorios 1-3 completados
- Conocimientos avanzados de Kubernetes
- Cluster funcionando con Argo CD

## 🏗️ Paso 1: Configuración de Proyectos Argo CD

### 1.1 Crear proyecto para desarrollo

**argocd/projects/dev-project.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: dev-project
  namespace: argocd
spec:
  description: Proyecto para ambiente de desarrollo
  
  sourceRepos:
    - 'https://github.com/tu-usuario/gitops-lab.git'
    - 'https://charts.helm.sh/stable'
    - 'https://argoproj.github.io/argo-helm'
  
  destinations:
    - namespace: 'dev-*'
      server: https://kubernetes.default.svc
    - namespace: 'dev'
      server: https://kubernetes.default.svc
  
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
    - group: 'apps'
      kind: Deployment
    - group: 'apps'
      kind: ReplicaSet
    - group: 'apps'
      kind: StatefulSet
    - group: 'apps'
      kind: DaemonSet
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
    - group: ''
      kind: Secret
    - group: 'networking.k8s.io'
      kind: Ingress
  
  namespaceResourceWhitelist:
    - group: ''
      kind: '*'
    - group: 'apps'
      kind: '*'
    - group: 'networking.k8s.io'
      kind: '*'
    - group: 'batch'
      kind: '*'
  
  roles:
    - name: dev-admin
      description: Administrador del ambiente de desarrollo
      policies:
        - p, proj:dev-project:dev-admin, applications, *, dev-project/*, allow
        - p, proj:dev-project:dev-admin, repositories, *, *, allow
        - p, proj:dev-project:dev-admin, certificates, *, *, allow
        - p, proj:dev-project:dev-admin, clusters, *, *, allow
      groups:
        - dev-team
  
    - name: dev-developer
      description: Desarrollador del ambiente de desarrollo
      policies:
        - p, proj:dev-project:dev-developer, applications, get, dev-project/*, allow
        - p, proj:dev-project:dev-developer, applications, sync, dev-project/*, allow
        - p, proj:dev-project:dev-developer, applications, action/*, dev-project/*, allow
      groups:
        - dev-developers
```

### 1.2 Crear proyecto para producción

**argocd/projects/prod-project.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: prod-project
  namespace: argocd
spec:
  description: Proyecto para ambiente de producción
  
  sourceRepos:
    - 'https://github.com/tu-usuario/gitops-lab.git'
    - 'https://charts.helm.sh/stable'
    - 'https://argoproj.github.io/argo-helm'
  
  destinations:
    - namespace: 'prod-*'
      server: https://kubernetes.default.svc
    - namespace: 'prod'
      server: https://kubernetes.default.svc
  
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
    - group: 'apps'
      kind: Deployment
    - group: 'apps'
      kind: ReplicaSet
    - group: 'apps'
      kind: StatefulSet
    - group: 'apps'
      kind: DaemonSet
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
    - group: ''
      kind: Secret
    - group: 'networking.k8s.io'
      kind: Ingress
  
  namespaceResourceWhitelist:
    - group: ''
      kind: '*'
    - group: 'apps'
      kind: '*'
    - group: 'networking.k8s.io'
      kind: '*'
    - group: 'batch'
      kind: '*'
  
  roles:
    - name: prod-admin
      description: Administrador del ambiente de producción
      policies:
        - p, proj:prod-project:prod-admin, applications, *, prod-project/*, allow
        - p, proj:prod-project:prod-admin, repositories, *, *, allow
        - p, proj:prod-project:prod-admin, certificates, *, *, allow
        - p, proj:prod-project:prod-admin, clusters, *, *, allow
      groups:
        - prod-team
  
    - name: prod-readonly
      description: Solo lectura para ambiente de producción
      policies:
        - p, proj:prod-project:prod-readonly, applications, get, prod-project/*, allow
      groups:
        - prod-readonly
```

## 🔄 Paso 2: Aplicaciones Multi-Ambiente

### 2.1 Aplicación de desarrollo

**argocd/applications/dev-nginx-app.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-nginx-app
  namespace: argocd
  labels:
    environment: dev
    app: nginx
spec:
  project: dev-project
  source:
    repoURL: https://github.com/tu-usuario/gitops-lab.git
    targetRevision: HEAD
    path: apps/charts/nginx-app
    helm:
      valueFiles:
        - ../../overlays/dev/nginx-values.yaml
      parameters:
        - name: image.tag
          value: "1.21"
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

### 2.2 Aplicación de producción

**argocd/applications/prod-nginx-app.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-nginx-app
  namespace: argocd
  labels:
    environment: prod
    app: nginx
spec:
  project: prod-project
  source:
    repoURL: https://github.com/tu-usuario/gitops-lab.git
    targetRevision: HEAD
    path: apps/charts/nginx-app
    helm:
      valueFiles:
        - ../../overlays/prod/nginx-values.yaml
      parameters:
        - name: image.tag
          value: "1.21"
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

## 🔐 Paso 3: Gestión de Secretos

### 3.1 Configurar External Secrets Operator

**argocd/applications/external-secrets.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-secrets
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://external-secrets.github.io/external-secrets/
    targetRevision: 0.9.11
    chart: external-secrets
    helm:
      values: |
        installCRDs: true
        webhook:
          port: 9443
        certController:
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 200m
              memory: 200Mi
  destination:
    server: https://kubernetes.default.svc
    namespace: external-secrets-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 3.2 Secret Store para AWS Secrets Manager

**apps/base/secret-store.yaml:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: dev
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        secretRef:
          accessKeyID:
            name: aws-credentials
            key: access-key-id
          secretAccessKey:
            name: aws-credentials
            key: secret-access-key
```

### 3.3 External Secret para base de datos

**apps/base/database-secret.yaml:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
  namespace: dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: gitops-lab/database
        property: username
    - secretKey: password
      remoteRef:
        key: gitops-lab/database
        property: password
```

## 📊 Paso 4: Monitoreo y Alertas

### 4.1 Instalar Prometheus y Grafana

**argocd/applications/monitoring-stack.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 45.7.1
    chart: kube-prometheus-stack
    helm:
      values: |
        prometheus:
          prometheusSpec:
            retention: 30d
            storageSpec:
              volumeClaimTemplate:
                spec:
                  storageClassName: standard
                  accessModes: ["ReadWriteOnce"]
                  resources:
                    requests:
                      storage: 50Gi
        grafana:
          enabled: true
          adminPassword: admin123
          service:
            type: LoadBalancer
          ingress:
            enabled: true
            hosts:
              - grafana.local
            annotations:
              kubernetes.io/ingress.class: nginx
        alertmanager:
          enabled: true
          alertmanagerSpec:
            storage:
              volumeClaimTemplate:
                spec:
                  storageClassName: standard
                  accessModes: ["ReadWriteOnce"]
                  resources:
                    requests:
                      storage: 10Gi
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 4.2 Configurar alertas para Argo CD

**apps/base/argocd-alerts.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-alerts
  namespace: monitoring
data:
  argocd-alerts.yaml: |
    groups:
    - name: argocd
      rules:
      - alert: ArgoCDApplicationOutOfSync
        expr: argocd_app_info{sync_status!="Synced"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD Application {{ $labels.name }} is out of sync"
          description: "Application {{ $labels.name }} in namespace {{ $labels.namespace }} has been out of sync for more than 5 minutes"
      
      - alert: ArgoCDApplicationSyncFailed
        expr: argocd_app_info{health_status="Degraded"} == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "ArgoCD Application {{ $labels.name }} sync failed"
          description: "Application {{ $labels.name }} in namespace {{ $labels.namespace }} has failed to sync"
      
      - alert: ArgoCDApplicationNotHealthy
        expr: argocd_app_info{health_status!="Healthy"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD Application {{ $labels.name }} is not healthy"
          description: "Application {{ $labels.name }} in namespace {{ $labels.namespace }} is not healthy"
```

## 🔄 Paso 5: Rollbacks Automáticos

### 5.1 Configurar Argo Rollouts

**argocd/applications/argo-rollouts.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-rollouts
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://argoproj.github.io/argo-helm
    targetRevision: 2.16.6
    chart: argo-rollouts
    helm:
      values: |
        controller:
          metrics:
            enabled: true
          serviceMonitor:
            enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argo-rollouts
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 5.2 Rollout con análisis automático

**apps/charts/nginx-app/templates/rollout.yaml:**
```yaml
{{- if .Values.rollout.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ include "nginx-app.fullname" . }}
  labels:
    {{- include "nginx-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 10s}
        - setWeight: 40
        - pause: {duration: 10s}
        - setWeight: 60
        - pause: {duration: 10s}
        - setWeight: 80
        - pause: {duration: 10s}
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: {{ include "nginx-app.fullname" . }}
        - name: error-rate
          value: "0.1"
      trafficRouting:
        nginx:
          stableIngress: {{ include "nginx-app.fullname" . }}-stable
          annotationPrefix: nginx.ingress.kubernetes.io
  selector:
    matchLabels:
      {{- include "nginx-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "nginx-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
{{- end }}
```

## 🚀 Paso 6: Aplicar Configuración

### 6.1 Aplicar proyectos

```bash
# Aplicar proyectos
kubectl apply -f argocd/projects/dev-project.yaml
kubectl apply -f argocd/projects/prod-project.yaml

# Verificar proyectos
argocd proj list
```

### 6.2 Aplicar aplicaciones

```bash
# Aplicar aplicaciones
kubectl apply -f argocd/applications/dev-nginx-app.yaml
kubectl apply -f argocd/applications/prod-nginx-app.yaml

# Verificar aplicaciones
argocd app list
```

### 6.3 Configurar monitoreo

```bash
# Aplicar stack de monitoreo
kubectl apply -f argocd/applications/monitoring-stack.yaml

# Verificar Prometheus
kubectl get pods -n monitoring

# Acceder a Grafana
kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80
```

## ✅ Verificación del Laboratorio

### Checklist de completitud:

- [ ] ✅ Proyectos Argo CD configurados
- [ ] ✅ Aplicaciones multi-ambiente desplegadas
- [ ] ✅ Gestión de secretos implementada
- [ ] ✅ Monitoreo y alertas configuradas
- [ ] ✅ Rollbacks automáticos funcionando
- [ ] ✅ Políticas de seguridad aplicadas

### Comandos de verificación:

```bash
# Verificar proyectos
argocd proj get dev-project
argocd proj get prod-project

# Verificar aplicaciones
argocd app list

# Verificar monitoreo
kubectl get pods -n monitoring

# Verificar secretos
kubectl get secrets -n dev
```

## 🎯 Conceptos Clave Aprendidos

1. **Proyectos Argo CD:** Organización y control de acceso
2. **Multi-Ambiente:** Gestión de diferentes entornos
3. **Gestión de Secretos:** Integración con sistemas externos
4. **Monitoreo:** Observabilidad completa del sistema
5. **Rollbacks:** Recuperación automática ante fallos

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 5:** Casos de Uso Complejos
- **Laboratorio 6:** CI/CD Integration
- **Laboratorio 7:** Troubleshooting Avanzado

## 🆘 Solución de Problemas

### Problema: Proyecto no se crea
```bash
# Verificar permisos
kubectl auth can-i create appprojects -n argocd

# Verificar configuración
kubectl get appprojects -n argocd
```

### Problema: Aplicación no sincroniza
```bash
# Verificar proyecto
argocd proj get <project-name>

# Verificar políticas
argocd proj get <project-name> --output yaml
```

### Problema: Alertas no funcionan
```bash
# Verificar Prometheus
kubectl get pods -n monitoring

# Verificar configuración de alertas
kubectl get configmap -n monitoring
```

---

**¡Excelente! Has completado el Laboratorio 4. Continúa con el Laboratorio 5 para casos de uso complejos.** 🎉
