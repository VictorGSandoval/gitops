# GitOps Laboratorio Práctico
## Infraestructura y Despliegues Auditables con Terraform, Argo CD y Helm

Este repositorio contiene un laboratorio **educativo y práctico** para aprender GitOps paso a paso usando las herramientas fundamentales: **Terraform**, **Argo CD** y **Helm** en un entorno **local**.

## 🎯 Objetivo del Laboratorio

Desarrollar el potencial de cada herramienta mediante **casos de uso prácticos** que demuestren:
- **GitOps** como metodología de despliegue
- **Kubernetes** como plataforma de orquestación
- **Helm** para gestión de aplicaciones
- **Terraform** para infraestructura como código
- **Argo CD** para sincronización automática

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Laboratorios Manuales](#laboratorios-manuales)
4. [Casos de Uso Prácticos](#casos-de-uso-prácticos)
5. [Configuración Local](#configuración-local)

## 🔧 Requisitos Previos

### Herramientas Necesarias (Entorno Local)
- **kubectl** (v1.24+) - Cliente de Kubernetes
- **helm** (v3.10+) - Gestor de paquetes para Kubernetes
- **terraform** (v1.5+) - Infraestructura como código
- **argocd CLI** (v2.7+) - Cliente de Argo CD
- **docker** (v20.10+) - Contenedores
- **git** (v2.30+) - Control de versiones

### Clúster Kubernetes Local
- **Minikube** (recomendado para aprendizaje)
- **Kind** (alternativa ligera)
- **Docker Desktop** (con Kubernetes habilitado)

### Verificación Manual
```bash
# Verificar herramientas instaladas
kubectl version --client
helm version
terraform version
argocd version --client
docker --version
git --version
```

## 📁 Estructura del Proyecto

```
gitops/
├── infra/                    # Infraestructura como código (Terraform)
│   ├── environments/         # Configuraciones por ambiente
│   ├── modules/             # Módulos reutilizables
│   └── providers/           # Configuración de proveedores
├── apps/                    # Aplicaciones y Helm charts
│   ├── base/               # Configuraciones base con Kustomize
│   ├── overlays/           # Configuraciones por ambiente
│   └── charts/             # Helm charts personalizados
├── argocd/                 # Configuración de Argo CD
│   ├── applications/       # Definiciones de aplicaciones
│   └── projects/          # Proyectos de Argo CD
├── scripts/               # Scripts de automatización
├── docs/                 # Documentación detallada
└── examples/             # Ejemplos y casos de uso
```

## 🧪 Laboratorios Manuales

### Laboratorio 1: Configuración Local
**Objetivo**: Configurar entorno local paso a paso
- Configuración manual de Minikube
- Instalación manual de Argo CD
- Configuración inicial de GitOps
- Primeros comandos de kubectl y helm

### Laboratorio 2: Fundamentos de Kubernetes
**Objetivo**: Entender Kubernetes desde cero
- Creación manual de pods y servicios
- ConfigMaps y Secrets
- Deployments y ReplicaSets
- Ingress y networking

### Laboratorio 3: Helm Charts Prácticos
**Objetivo**: Dominar Helm charts
- Creación manual de charts
- Templates y valores
- Dependencias entre charts
- Testing y debugging

### Laboratorio 4: Argo CD en Acción
**Objetivo**: Implementar GitOps real
- Configuración manual de aplicaciones
- Sincronización automática
- Gestión de proyectos
- Troubleshooting común

### Laboratorio 5: Casos de Uso GitOps
**Objetivo**: Aplicar GitOps en escenarios reales
- Aplicación web completa
- API con base de datos
- Monitoreo básico
- Gestión de secretos

## 🚀 Configuración Local Paso a Paso

### 1. Preparar el Entorno
```bash
# Clonar el repositorio
git clone https://github.com/VictorGSandoval/gitops.git
cd gitops

# Verificar herramientas instaladas
kubectl version --client
helm version
terraform version
argocd version --client
```

### 2. Configurar Minikube
```bash
# Iniciar Minikube
minikube start --memory=4096 --cpus=2

# Verificar cluster
kubectl get nodes
kubectl cluster-info
```

### 3. Instalar Argo CD Manualmente
```bash
# Crear namespace
kubectl create namespace argocd

# Instalar Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar que esté listo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 4. Acceder a Argo CD
```bash
# Port forward para acceso local
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Obtener contraseña inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 5. Comenzar con los Laboratorios
- Accede a Argo CD: https://localhost:8080
- Usuario: `admin`
- Contraseña: (obtenida en paso anterior)
- Sigue los laboratorios en orden secuencial

## 📚 Casos de Uso Prácticos

- **Aplicación Web Simple**: Nginx con configuración básica
- **API REST**: Aplicación Node.js con base de datos
- **Microservicios**: Arquitectura distribuida con múltiples servicios
- **Monitoreo**: Stack completo con Prometheus y Grafana
- **CI/CD Pipeline**: Integración con GitHub Actions

## 🛠️ Scripts de Automatización

### Scripts Disponibles
- **`check-requirements.sh`**: Verifica que todas las herramientas estén instaladas
- **`setup-cluster.sh`**: Configura el clúster Kubernetes local
- **`deploy-lab.sh`**: Despliega todo el laboratorio automáticamente
- **`validate-lab.sh`**: Valida que todo esté funcionando correctamente

### Uso de Scripts
```bash
# Verificar requisitos
./scripts/check-requirements.sh

# Configurar cluster
./scripts/setup-cluster.sh --minikube
# o
./scripts/setup-cluster.sh --kind

# Desplegar laboratorio
./scripts/deploy-lab.sh dev minikube
# o
./scripts/deploy-lab.sh prod kind

# Validar despliegue
./scripts/validate-lab.sh
```

## 🔗 Acceso a Aplicaciones

### Argo CD
- **Minikube**: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- **Kind**: `http://argocd.local`
- **Usuario**: `admin`
- **Contraseña**: (se muestra en la salida del script)

### Aplicaciones
- **Nginx Dev**: `kubectl port-forward svc/nginx-app -n dev 8081:80`
- **API Dev**: `kubectl port-forward svc/api-app -n dev 8082:3000`

### Monitoreo
- **Grafana**: `kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80`
- **Prometheus**: `kubectl port-forward svc/monitoring-stack-prometheus -n monitoring 9090:9090`

## 🎯 Conceptos Clave

### GitOps
- **Definición**: Enfoque para gestión de infraestructura usando Git como fuente de verdad
- **Ventajas**: Automatización, auditabilidad, trazabilidad
- **Herramientas**: Argo CD, Flux, Jenkins X

### Infraestructura como Código
- **Definición**: Gestión de infraestructura mediante archivos de configuración
- **Ventajas**: Versionado, reutilización, automatización
- **Herramientas**: Terraform, Pulumi, CloudFormation

### Helm
- **Definición**: Gestor de paquetes para Kubernetes
- **Ventajas**: Empaquetado, reutilización, gestión de dependencias
- **Conceptos**: Charts, Values, Templates

## 🚀 Próximos Pasos

1. **Explorar laboratorios**: Sigue los laboratorios en orden secuencial
2. **Personalizar configuraciones**: Modifica valores según tus necesidades
3. **Agregar casos de uso**: Implementa nuevos escenarios
4. **Integrar con CI/CD**: Configura pipelines automatizados
5. **Escalar horizontalmente**: Agrega más ambientes y aplicaciones

## 🤝 Contribuciones

Este laboratorio está diseñado para ser práctico y funcional. Si encuentras algún problema o tienes sugerencias de mejora, por favor:

1. Abre un issue describiendo el problema
2. Propón mejoras en la documentación
3. Contribuye con nuevos casos de uso

## 📞 Soporte

Para dudas específicas sobre el laboratorio, consulta:
- [Documentación detallada](./docs/)
- [Casos de uso prácticos](./examples/)
- [Scripts de automatización](./scripts/)

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

**¡Comienza tu journey en GitOps de manera práctica y escalable!** 🎯