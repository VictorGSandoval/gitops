# Laboratorio 1: Configuración Local y Primeros Pasos

## 🎯 Objetivo

Configurar un entorno local completo para aprender GitOps paso a paso, sin depender de scripts automatizados. Al finalizar este laboratorio tendrás:

- Un clúster Kubernetes local funcionando
- Argo CD instalado y configurado
- Conocimiento práctico de kubectl y helm
- Entendimiento básico de GitOps

## ⏱️ Tiempo Estimado

**60-90 minutos**

## 📋 Prerrequisitos

- macOS, Linux o Windows con WSL2
- Docker instalado y funcionando
- Git instalado
- Conexión a internet

## 🚀 Paso 1: Instalación de Herramientas

### 1.1 Instalar kubectl

**En macOS (con Homebrew):**
```bash
brew install kubectl
```

**En Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Verificar instalación:**
```bash
kubectl version --client
```

### 1.2 Instalar Helm

**En macOS:**
```bash
brew install helm
```

**En Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Verificar instalación:**
```bash
helm version
```

### 1.3 Instalar Minikube

**En macOS:**
```bash
brew install minikube
```

**En Linux:**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Verificar instalación:**
```bash
minikube version
```

### 1.4 Instalar Argo CD CLI

**En macOS:**
```bash
brew install argocd
```

**En Linux:**
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

**Verificar instalación:**
```bash
argocd version --client
```

## 🏗️ Paso 2: Configuración del Clúster Local

### 2.1 Iniciar Minikube

```bash
# Iniciar Minikube con recursos suficientes
minikube start --memory=4096 --cpus=2 --disk-size=20g

# Verificar que el cluster esté funcionando
kubectl get nodes
kubectl cluster-info
```

**Resultado esperado:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.28.0
```

### 2.2 Verificar Configuración de kubectl

```bash
# Verificar contexto actual
kubectl config current-context

# Verificar configuración
kubectl config view

# Probar conectividad
kubectl get pods --all-namespaces
```

### 2.3 Habilitar Addons Útiles

```bash
# Habilitar dashboard (opcional)
minikube addons enable dashboard

# Habilitar ingress
minikube addons enable ingress

# Ver addons habilitados
minikube addons list
```

## 🔄 Paso 3: Instalación Manual de Argo CD

### 3.1 Crear Namespace

```bash
# Crear namespace para Argo CD
kubectl create namespace argocd

# Verificar namespace creado
kubectl get namespaces | grep argocd
```

### 3.2 Instalar Argo CD

```bash
# Descargar e instalar manifiestos de Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verificar que los pods se están creando
kubectl get pods -n argocd -w
```

**Esperar a que todos los pods estén en estado "Running":**
```bash
# En otra terminal, monitorear el estado
kubectl get pods -n argocd
```

### 3.3 Verificar Instalación

```bash
# Verificar deployments
kubectl get deployments -n argocd

# Verificar servicios
kubectl get svc -n argocd

# Verificar que Argo CD esté listo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## 🌐 Paso 4: Acceso a Argo CD

### 4.1 Configurar Port Forward

```bash
# En una terminal separada (mantener abierta)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 4.2 Obtener Credenciales Iniciales

```bash
# Obtener contraseña del usuario admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Guarda esta contraseña, la necesitarás para el login.**

### 4.3 Acceder a la Interfaz Web

1. Abre tu navegador
2. Ve a: `https://localhost:8080`
3. Acepta el certificado SSL (es autofirmado)
4. Login con:
   - **Usuario**: `admin`
   - **Contraseña**: (la que obtuviste en el paso anterior)

## 🔧 Paso 5: Configuración Inicial de Argo CD

### 5.1 Login desde CLI

```bash
# Login desde línea de comandos
argocd login localhost:8080 --username admin --password <tu-password>

# Verificar conexión
argocd version
```

### 5.2 Explorar la Interfaz

**En la interfaz web de Argo CD:**
1. **Applications**: Lista de aplicaciones (vacía inicialmente)
2. **Repositories**: Repositorios Git configurados
3. **Projects**: Proyectos de Argo CD
4. **Settings**: Configuraciones del sistema

### 5.3 Configurar Repositorio Git

```bash
# Agregar repositorio Git (usando el repositorio actual)
argocd repo add https://github.com/VictorGSandoval/gitops.git --name gitops-lab

# Verificar repositorio agregado
argocd repo list
```

## 📱 Paso 6: Primera Aplicación GitOps

### 6.1 Crear Aplicación de Ejemplo

```bash
# Crear aplicación usando el repositorio de ejemplo de Argo CD
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Verificar aplicación creada
argocd app list
```

### 6.2 Sincronizar Aplicación

```bash
# Sincronizar la aplicación
argocd app sync guestbook

# Ver estado de la aplicación
argocd app get guestbook
```

### 6.3 Verificar Despliegue

```bash
# Ver pods desplegados
kubectl get pods

# Ver servicios
kubectl get svc

# Ver la aplicación en Argo CD UI
# Deberías ver la aplicación "guestbook" con estado "Synced"
```

## 🧪 Paso 7: Experimentar con Helm

### 7.1 Agregar Repositorio Helm

```bash
# Agregar repositorio oficial de Helm
helm repo add stable https://charts.helm.sh/stable

# Actualizar repositorios
helm repo update

# Ver repositorios disponibles
helm repo list
```

### 7.2 Instalar Aplicación con Helm

```bash
# Buscar charts disponibles
helm search repo nginx

# Instalar nginx usando Helm
helm install my-nginx stable/nginx-ingress --namespace default

# Ver releases de Helm
helm list

# Ver recursos creados
kubectl get all
```

### 7.3 Explorar Helm Chart

```bash
# Ver valores del chart instalado
helm get values my-nginx

# Ver manifiestos generados
helm get manifest my-nginx

# Actualizar release
helm upgrade my-nginx stable/nginx-ingress --set controller.replicaCount=2
```

## ✅ Verificación del Laboratorio

### Checklist de Completitud

- [ ] ✅ Herramientas instaladas (kubectl, helm, minikube, argocd)
- [ ] ✅ Minikube funcionando
- [ ] ✅ Argo CD instalado y accesible
- [ ] ✅ Login exitoso en Argo CD (web y CLI)
- [ ] ✅ Repositorio Git configurado
- [ ] ✅ Primera aplicación GitOps creada
- [ ] ✅ Helm funcionando con charts básicos

### Comandos de Verificación

```bash
# Verificar estado general
kubectl get nodes
kubectl get pods -n argocd
argocd app list
helm list

# Verificar aplicaciones
kubectl get pods
kubectl get svc
```

## 🎯 Conceptos Clave Aprendidos

1. **Kubernetes Local**: Configuración de clúster local con Minikube
2. **Argo CD**: Instalación y configuración básica
3. **GitOps**: Concepto de usar Git como fuente de verdad
4. **Helm**: Gestión de aplicaciones con charts
5. **kubectl**: Comandos básicos de Kubernetes
6. **Port Forward**: Acceso a servicios desde localhost

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 2**: Fundamentos de Kubernetes
- **Laboratorio 3**: Helm Charts Prácticos
- **Laboratorio 4**: Argo CD en Acción
- **Laboratorio 5**: Casos de Uso GitOps

## 🆘 Solución de Problemas

### Problema: Minikube no inicia
```bash
# Verificar Docker
docker --version
docker ps

# Reiniciar Minikube
minikube delete
minikube start --memory=4096 --cpus=2
```

### Problema: Argo CD no responde
```bash
# Verificar pods
kubectl get pods -n argocd

# Ver logs
kubectl logs -f deployment/argocd-server -n argocd

# Reiniciar si es necesario
kubectl rollout restart deployment/argocd-server -n argocd
```

### Problema: No se puede hacer login
```bash
# Verificar contraseña
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Verificar port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

**¡Felicidades! Has completado el Laboratorio 1. Continúa con el Laboratorio 2 para aprender fundamentos de Kubernetes.** 🎉
