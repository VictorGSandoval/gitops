# Laboratorio 2: Despliegue Progresivo con Argo CD

Este laboratorio te guiará en el uso de Argo CD para desplegar aplicaciones, progresando desde manifiestos YAML simples hasta Helm Charts.

## Parte 1: Manifiestos YAML Básicos

### 1. Crear un Manifiesto Básico

Crear `manifests/basic/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: demo
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
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### 2. Crear la Aplicación en Argo CD

Crear `manifests/basic/application.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-basic
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/[tu-usuario]/gitops.git
    targetRevision: HEAD
    path: manifests/basic
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 3. Aplicar la Configuración

```bash
kubectl create namespace demo
kubectl apply -f manifests/basic/application.yaml
```

## Parte 2: Kustomize (Próximamente)

Evolucionar a Kustomize para manejar variaciones de ambiente.

## Parte 3: Helm Charts (Próximamente)

Finalizar con Helm Charts para despliegues más complejos.

## Verificación

```bash
# Verificar el estado de la aplicación
kubectl get applications -n argocd

# Verificar los pods desplegados
kubectl get pods -n demo
```