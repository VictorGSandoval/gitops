# Laboratorio 1: Configuración Inicial y Primeros Pasos

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:
- Verificar que todos los requisitos están instalados
- Configurar un clúster Kubernetes local
- Instalar y configurar Argo CD
- Crear tu primera aplicación GitOps
- Entender el flujo básico de GitOps

## ⏱️ Tiempo Estimado

**45-60 minutos**

## 📋 Prerrequisitos

- Herramientas instaladas según `scripts/check-requirements.sh`
- Cuenta en GitHub/GitLab (para el repositorio Git)
- Conocimientos básicos de Kubernetes y Git

## 🚀 Paso 1: Verificación de Requisitos

### 1.1 Ejecutar verificación completa

```bash
# Desde el directorio raíz del proyecto
./scripts/check-requirements.sh
```

**Resultado esperado:**
```
🎉 ¡Todos los requisitos están cumplidos!
   Puedes proceder con el Laboratorio 1
```

### 1.2 Si hay herramientas faltantes

**Instalación en macOS (usando Homebrew):**
```bash
# Instalar herramientas faltantes
brew install kubectl helm terraform argocd docker git minikube

# Verificar instalación
./scripts/check-requirements.sh
```

**Instalación en Linux:**
```bash
# Consultar documentación específica para tu distribución
# https://kubernetes.io/docs/tasks/tools/
```

## 🏗️ Paso 2: Configuración del Clúster

### 2.1 Configurar clúster local

**Opción A: Minikube (Recomendado para principiantes)**
```bash
./scripts/setup-cluster.sh --minikube
```

**Opción B: Kind (Más ligero)**
```bash
./scripts/setup-cluster.sh --kind
```

### 2.2 Verificar configuración

```bash
# Verificar que el clúster está funcionando
kubectl get nodes

# Verificar que Argo CD está instalado
kubectl get pods -n argocd

# Verificar servicios
kubectl get svc -n argocd
```

**Resultado esperado:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.28.0

NAME                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0    1/1     Running   0          2m
argocd-dex-server-xxx              1/1     Running   0          2m
argocd-redis-xxx                   1/1     Running   0          2m
argocd-repo-server-xxx             1/1     Running   0          2m
argocd-server-xxx                  1/1     Running   0          2m
```

## 🌐 Paso 3: Acceso a Argo CD

### 3.1 Configurar acceso

**Para Minikube:**
```bash
# En una terminal separada (mantener abierta)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Acceder desde el navegador
# https://localhost:8080
```

**Para Kind:**
```bash
# Agregar a /etc/hosts
echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts

# Acceder desde el navegador
# http://argocd.local
```

### 3.2 Login inicial

**Credenciales:**
- **Usuario:** `admin`
- **Contraseña:** (se muestra en la salida del script de configuración)

```bash
# También puedes obtener la contraseña con:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3.3 Configurar CLI de Argo CD

```bash
# Login desde CLI
argocd login localhost:8080 --username admin --password <tu-password>

# O para Kind
argocd login argocd.local --username admin --password <tu-password>

# Verificar conexión
argocd version
```

## 📱 Paso 4: Primera Aplicación GitOps

### 4.1 Crear aplicación de ejemplo

Vamos a crear una aplicación simple usando el repositorio de este laboratorio.

```bash
# Crear aplicación desde CLI
argocd app create nginx-example \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated

# Verificar aplicación
argocd app get nginx-example
```

### 4.2 Sincronizar aplicación

```bash
# Sincronizar manualmente
argocd app sync nginx-example

# Verificar estado
argocd app get nginx-example
```

### 4.3 Verificar despliegue

```bash
# Ver pods desplegados
kubectl get pods

# Ver servicios
kubectl get svc

# Verificar aplicación en Argo CD UI
# Deberías ver la aplicación "nginx-example" con estado "Synced"
```

## 🔍 Paso 5: Explorar la Interfaz de Argo CD

### 5.1 Navegación básica

1. **Applications:** Lista de todas las aplicaciones
2. **App Details:** Detalles de cada aplicación
3. **Resource Tree:** Vista jerárquica de recursos
4. **Sync Status:** Estado de sincronización

### 5.2 Operaciones comunes

**Desde la UI:**
- **Sync:** Sincronizar aplicación
- **Refresh:** Actualizar estado
- **Delete:** Eliminar aplicación
- **Rollback:** Revertir a versión anterior

**Desde CLI:**
```bash
# Listar aplicaciones
argocd app list

# Obtener detalles
argocd app get <app-name>

# Sincronizar
argocd app sync <app-name>

# Eliminar
argocd app delete <app-name>
```

## 🧪 Paso 6: Experimentar con Cambios

### 6.1 Simular cambio en Git

```bash
# Crear una nueva aplicación con diferentes parámetros
argocd app create nginx-example-v2 \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --revision HEAD

# Verificar que ambas aplicaciones están desplegadas
kubectl get pods
```

### 6.2 Observar sincronización automática

1. Ve a la UI de Argo CD
2. Observa cómo Argo CD detecta y sincroniza cambios
3. Verifica el estado de sincronización

## ✅ Verificación del Laboratorio

### Checklist de completitud:

- [ ] ✅ Script de verificación ejecutado exitosamente
- [ ] ✅ Clúster Kubernetes configurado y funcionando
- [ ] ✅ Argo CD instalado y accesible
- [ ] ✅ Login exitoso en Argo CD (UI y CLI)
- [ ] ✅ Primera aplicación GitOps creada
- [ ] ✅ Aplicación sincronizada y desplegada
- [ ] ✅ Interfaz de Argo CD explorada
- [ ] ✅ Operaciones básicas probadas

### Comandos de verificación:

```bash
# Verificar estado general
kubectl get nodes
kubectl get pods -n argocd
argocd app list

# Verificar aplicación de ejemplo
kubectl get pods
kubectl get svc
```

## 🎯 Conceptos Clave Aprendidos

1. **GitOps:** Enfoque que usa Git como fuente de verdad
2. **Argo CD:** Herramienta de GitOps para Kubernetes
3. **Sincronización:** Proceso de mantener el clúster actualizado con Git
4. **Aplicaciones:** Unidades de despliegue en Argo CD
5. **Políticas de Sincronización:** Configuración de cómo sincronizar

## 🚀 Próximos Pasos

Una vez completado este laboratorio, puedes continuar con:

- **Laboratorio 2:** Infraestructura con Terraform
- **Laboratorio 3:** Aplicaciones con Helm
- **Laboratorio 4:** GitOps Avanzado
- **Laboratorio 5:** Casos de Uso Complejos

## 🆘 Solución de Problemas

### Problema: Argo CD no responde
```bash
# Verificar pods
kubectl get pods -n argocd

# Reiniciar si es necesario
kubectl rollout restart deployment/argocd-server -n argocd
```

### Problema: No se puede hacer login
```bash
# Verificar contraseña
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Resetear contraseña si es necesario
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVFOBqQyHibPVYEBbKjgBUXo.0jJAid1R2S",
    "admin.passwordMtime": "'$(date +%Y-%m-%dT%H:%M:%S)'"
  }}'
```

### Problema: Aplicación no se sincroniza
```bash
# Verificar logs
argocd app get <app-name> --show-params

# Forzar sincronización
argocd app sync <app-name> --force
```

---

**¡Felicidades! Has completado el Laboratorio 1. Continúa con el Laboratorio 2 para aprender sobre infraestructura con Terraform.** 🎉
