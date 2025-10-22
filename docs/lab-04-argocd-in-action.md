# Laboratorio 4: Argo CD en Acción

## 🎯 Objetivo

Implementar GitOps real usando Argo CD para sincronización automática. Al finalizar este laboratorio serás capaz de:

- Configurar aplicaciones Argo CD manualmente
- Implementar sincronización automática
- Gestionar proyectos y políticas
- Troubleshooting común de GitOps

## ⏱️ Tiempo Estimado

**120-150 minutos**

## 📋 Prerrequisitos

- Laboratorios 1-3 completados
- Argo CD funcionando
- Repositorio Git configurado
- Charts de Helm creados

## 🔄 Paso 1: Configuración de Repositorio Git

### 1.1 Preparar Repositorio Local

```bash
# Volver al directorio raíz del proyecto
cd /Users/geovani/Documents/LABFAPE/gitops

# Inicializar repositorio Git si no está inicializado
git init

# Agregar archivos al repositorio
git add .

# Hacer commit inicial
git commit -m "Initial commit: GitOps Lab setup"

# Configurar repositorio remoto
git remote add origin https://github.com/VictorGSandoval/gitops.git

# Subir cambios
git push -u origin main
```

### 1.2 Configurar Argo CD para el Repositorio

```bash
# Agregar repositorio a Argo CD
argocd repo add https://github.com/VictorGSandoval/gitops.git --name gitops-lab

# Verificar repositorio agregado
argocd repo list

# Verificar conectividad
argocd repo get https://github.com/VictorGSandoval/gitops.git
```

## 📱 Paso 2: Crear Primera Aplicación GitOps

### 2.1 Crear Aplicación desde CLI

```bash
# Crear aplicación usando nuestro chart
argocd app create mi-aplicacion-gitops \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --helm-set replicaCount=2 \
  --helm-set app.environment=gitops

# Verificar aplicación creada
argocd app list
argocd app get mi-aplicacion-gitops
```

### 2.2 Sincronizar Aplicación

```bash
# Sincronizar aplicación
argocd app sync mi-aplicacion-gitops

# Ver estado de sincronización
argocd app get mi-aplicacion-gitops

# Ver recursos desplegados
kubectl get all
```

### 2.3 Verificar en la Interfaz Web

1. Abre Argo CD: https://localhost:8080
2. Ve a **Applications**
3. Haz clic en **mi-aplicacion-gitops**
4. Explora la vista de recursos
5. Verifica el estado de sincronización

## 🏗️ Paso 3: Configuración de Proyectos

### 3.1 Crear Proyecto de Desarrollo

**Crear archivo `argocd/projects/dev-project.yaml`:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: dev-project
  namespace: argocd
spec:
  description: Proyecto para ambiente de desarrollo
  
  sourceRepos:
    - 'https://github.com/VictorGSandoval/gitops.git'
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
  
  roles:
    - name: dev-admin
      description: Administrador del ambiente de desarrollo
      policies:
        - p, proj:dev-project:dev-admin, applications, *, dev-project/*, allow
        - p, proj:dev-project:dev-admin, repositories, *, *, allow
      groups:
        - dev-team
```

**Aplicar proyecto:**
```bash
# Aplicar proyecto
kubectl apply -f argocd/projects/dev-project.yaml

# Verificar proyecto creado
argocd proj list
argocd proj get dev-project
```

### 3.2 Crear Aplicación con Proyecto

```bash
# Crear aplicación asignada al proyecto
argocd app create mi-aplicacion-dev \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --helm-set-file values=charts/mi-aplicacion/values-dev.yaml

# Verificar aplicación
argocd app list
argocd app get mi-aplicacion-dev
```

## 🔄 Paso 4: Sincronización Automática

### 4.1 Configurar Sincronización Automática

```bash
# Habilitar sincronización automática
argocd app set mi-aplicacion-dev --sync-policy automated

# Configurar auto-prune
argocd app set mi-aplicacion-dev --auto-prune

# Configurar self-heal
argocd app set mi-aplicacion-dev --self-heal

# Verificar configuración
argocd app get mi-aplicacion-dev
```

### 4.2 Probar Sincronización Automática

**Hacer cambios en el repositorio:**
```bash
# Editar values-dev.yaml
vim charts/mi-aplicacion/values-dev.yaml

# Cambiar replicaCount de 1 a 3
# Cambiar algún texto en customHtml

# Hacer commit y push
git add .
git commit -m "Update dev configuration: increase replicas to 3"
git push origin main
```

**Verificar sincronización automática:**
```bash
# Esperar unos segundos y verificar
argocd app get mi-aplicacion-dev

# Ver pods actualizados
kubectl get pods -n dev

# Verificar que los cambios se aplicaron
kubectl get deployment -n dev
```

## 🧪 Paso 5: Casos de Uso Prácticos

### 5.1 Aplicación Multi-Ambiente

**Crear aplicación de staging:**
```bash
# Crear namespace de staging
kubectl create namespace staging

# Crear aplicación de staging
argocd app create mi-aplicacion-staging \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace staging \
  --project dev-project \
  --helm-set replicaCount=2 \
  --helm-set app.environment=staging \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verificar aplicación
argocd app list
```

**Crear aplicación de producción:**
```bash
# Crear namespace de producción
kubectl create namespace prod

# Crear aplicación de producción
argocd app create mi-aplicacion-prod \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --project dev-project \
  --helm-set replicaCount=3 \
  --helm-set app.environment=production \
  --helm-set ingress.enabled=true \
  --helm-set ingress.hosts[0].host=mi-app.gitops-lab.com \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verificar aplicación
argocd app list
```

### 5.2 Aplicación con Base de Datos

**Crear aplicación de base de datos:**
```bash
# Crear aplicación de base de datos
argocd app create mi-database \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-database \
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

### 5.3 Aplicación de Monitoreo

**Crear aplicación de monitoreo:**
```bash
# Crear namespace de monitoreo
kubectl create namespace monitoring

# Crear aplicación de monitoreo
argocd app create monitoring-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --chart kube-prometheus-stack \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace monitoring \
  --project dev-project \
  --helm-set prometheus.prometheusSpec.retention=30d \
  --helm-set grafana.adminPassword=admin123 \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verificar aplicación
argocd app list
kubectl get pods -n monitoring
```

## 🔍 Paso 6: Monitoreo y Troubleshooting

### 6.1 Verificar Estado de Aplicaciones

```bash
# Ver estado general de todas las aplicaciones
argocd app list

# Ver detalles de una aplicación específica
argocd app get mi-aplicacion-dev

# Ver recursos de una aplicación
argocd app resources mi-aplicacion-dev

# Ver logs de una aplicación
argocd app logs mi-aplicacion-dev
```

### 6.2 Troubleshooting Común

**Aplicación fuera de sincronización:**
```bash
# Ver estado de sincronización
argocd app get mi-aplicacion-dev

# Forzar sincronización
argocd app sync mi-aplicacion-dev --force

# Ver diferencias
argocd app diff mi-aplicacion-dev
```

**Aplicación con errores:**
```bash
# Ver eventos de la aplicación
kubectl get events -n dev

# Ver logs de pods
kubectl logs -l app.kubernetes.io/name=mi-aplicacion -n dev

# Verificar recursos
kubectl get all -n dev
```

**Problemas de conectividad:**
```bash
# Verificar conectividad del repositorio
argocd repo get https://github.com/VictorGSandoval/gitops.git

# Verificar logs de Argo CD
kubectl logs -f deployment/argocd-application-controller -n argocd
```

### 6.3 Rollback y Recuperación

**Rollback de aplicación:**
```bash
# Ver historial de sincronización
argocd app history mi-aplicacion-dev

# Rollback a versión anterior
argocd app rollback mi-aplicacion-dev <revision-number>

# Verificar rollback
argocd app get mi-aplicacion-dev
```

**Recuperación de aplicación:**
```bash
# Eliminar aplicación
argocd app delete mi-aplicacion-dev

# Recrear aplicación
argocd app create mi-aplicacion-dev \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --sync-policy automated
```

## 📊 Paso 7: Casos de Uso Avanzados

### 7.1 Aplicación con Múltiples Charts

**Crear aplicación completa:**
```bash
# Crear aplicación que incluye múltiples charts
argocd app create aplicacion-completa \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts \
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

### 7.2 Aplicación con Valores Externos

**Crear archivo de valores externo:**
```yaml
# values-external.yaml
replicaCount: 2
image:
  tag: "1.22"
app:
  environment: "external"
ingress:
  enabled: true
  hosts:
    - host: mi-app-external.local
      paths:
        - path: /
          pathType: Prefix
```

**Aplicar valores externos:**
```bash
# Crear aplicación con valores externos
argocd app create mi-aplicacion-external \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --helm-set-file values=values-external.yaml \
  --sync-policy automated

# Verificar aplicación
argocd app get mi-aplicacion-external
```

### 7.3 Aplicación con Sincronización Programada

**Configurar sincronización programada:**
```bash
# Crear aplicación con sincronización programada
argocd app create mi-aplicacion-scheduled \
  --repo https://github.com/VictorGSandoval/gitops.git \
  --path charts/mi-aplicacion \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --project dev-project \
  --sync-policy automated \
  --sync-option CreateNamespace=true \
  --sync-option PrunePropagationPolicy=foreground

# Verificar configuración
argocd app get mi-aplicacion-scheduled
```

## ✅ Verificación del Laboratorio

### Checklist de Completitud

- [ ] ✅ Repositorio Git configurado
- [ ] ✅ Aplicaciones Argo CD creadas
- [ ] ✅ Proyectos configurados
- [ ] ✅ Sincronización automática funcionando
- [ ] ✅ Aplicaciones multi-ambiente desplegadas
- [ ] ✅ Monitoreo configurado
- [ ] ✅ Troubleshooting realizado

### Comandos de Verificación

```bash
# Ver aplicaciones
argocd app list

# Ver proyectos
argocd proj list

# Ver recursos
kubectl get all --all-namespaces

# Ver estado de sincronización
argocd app get mi-aplicacion-dev
```

## 🎯 Conceptos Clave Aprendidos

1. **GitOps**: Uso de Git como fuente de verdad
2. **Argo CD**: Herramienta de GitOps para Kubernetes
3. **Sincronización Automática**: Mantenimiento automático del estado
4. **Proyectos**: Organización y control de acceso
5. **Multi-Ambiente**: Gestión de diferentes entornos
6. **Troubleshooting**: Resolución de problemas comunes

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 5**: Casos de Uso GitOps
- **Laboratorio 6**: CI/CD Integration
- **Laboratorio 7**: Troubleshooting Avanzado

## 🆘 Solución de Problemas

### Problema: Aplicación no sincroniza
```bash
# Verificar estado
argocd app get <app-name>

# Forzar sincronización
argocd app sync <app-name> --force

# Ver logs
argocd app logs <app-name>
```

### Problema: Repositorio no accesible
```bash
# Verificar conectividad
argocd repo get <repo-url>

# Reagregar repositorio
argocd repo rm <repo-url>
argocd repo add <repo-url>
```

### Problema: Aplicación con errores
```bash
# Ver eventos
kubectl get events -n <namespace>

# Ver logs de pods
kubectl logs -l app.kubernetes.io/name=<app-name> -n <namespace>

# Verificar recursos
kubectl get all -n <namespace>
```

---

**¡Excelente! Has completado el Laboratorio 4. Continúa con el Laboratorio 5 para casos de uso GitOps.** 🎉
