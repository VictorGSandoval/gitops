# GitOps Laboratorio Práctico - Enfoque Simple

## 🎯 Objetivo

Aprender GitOps de forma **progresiva y simple**, empezando con lo básico y avanzando gradualmente:

1. **YAMLs básicos** → Argo CD los sincroniza
2. **Helm charts simples** → Argo CD maneja charts
3. **Casos prácticos** → Aplicaciones reales

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Laboratorios Simples](#laboratorios-simples)
3. [Configuración Local](#configuración-local)
4. [Casos de Uso Prácticos](#casos-de-uso-prácticos)

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

## Notas de seguridad (importante)

Este repositorio incluye un archivo `.gitignore` en la raíz. Asegúrate de NO subir archivos sensibles ni estados de Terraform al repositorio.

Elementos que deben mantenerse locales y fuera de Git:

- `terraform.tfstate`, `terraform.tfstate.backup`, `*.tfvars`, `secret.auto.tfvars`
- Claves privadas y certificados: `*.pem`, `*.key`, `*.crt`
- Directorios y archivos generados: `.terraform/`, `*.tfplan`
- Configuraciones locales de kubectl: `~/.kube/config`

Antes de commitear, revisa `git status` y usa `git diff` para confirmar que no estés subiendo secretos.


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

## 🧪 Laboratorios Simples

### Laboratorio 1: GitOps Básico
**Objetivo**: Empezar con YAMLs simples
- Deployment, Service, ConfigMap básicos
- Argo CD sincroniza automáticamente
- Cambios en Git se aplican automáticamente

### Laboratorio 2: GitOps con Helm Simple
**Objetivo**: Introducir Helm gradualmente
- Chart Helm básico
- Valores por ambiente
- Argo CD maneja charts desde Git

### Laboratorio 3: Casos Prácticos
**Objetivo**: Aplicaciones reales
- Aplicación web completa
- API con base de datos
- Monitoreo básico

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

- **Aplicación Simple**: YAMLs básicos con Argo CD
- **Helm Chart Básico**: Chart simple con valores por ambiente
- **Aplicación Web**: Nginx con configuración personalizada
- **API Básica**: Node.js con base de datos simple

## 🎓 Enfoque Simple y Progresivo

### Metodología Gradual
Este laboratorio está diseñado para **aprender paso a paso** sin complejidad innecesaria:

- **Empezar Simple**: YAMLs básicos que todos entienden
- **Progresar Gradualmente**: Introducir Helm cuando sea necesario
- **Casos Reales**: Aplicaciones que realmente funcionan
- **Sin Complejidad**: Sin scripts, sin configuraciones complejas

### Ventajas del Enfoque Simple
- ✅ **Fácil de Entender**: Conceptos básicos primero
- ✅ **Progresivo**: Cada paso construye sobre el anterior
- ✅ **Práctico**: Aplicaciones que realmente funcionan
- ✅ **Sin Confusión**: Sin herramientas innecesarias

## 🔗 Acceso a Aplicaciones

### Argo CD
- **Acceso**: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- **URL**: https://localhost:8080
- **Usuario**: `admin`
- **Contraseña**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Aplicaciones Desplegadas
- **Web App Dev**: `kubectl port-forward svc/web-app -n dev 8080:80`
- **API App**: `kubectl port-forward svc/api-app -n dev 3000:3000`
- **Monitoreo Grafana**: `kubectl port-forward svc/monitoring-grafana -n monitoring 3001:80`

### Comandos Útiles
```bash
# Ver todas las aplicaciones Argo CD
argocd app list

# Ver recursos por namespace
kubectl get all -n dev
kubectl get all -n prod
kubectl get all -n monitoring

# Ver logs de aplicaciones
kubectl logs -l app.kubernetes.io/name=web-app -n dev
kubectl logs -l app.kubernetes.io/name=api-app -n dev
```

## 🎯 Conceptos Clave Aprendidos

### GitOps
- **Definición**: Enfoque para gestión de infraestructura usando Git como fuente de verdad
- **Ventajas**: Automatización, auditabilidad, trazabilidad
- **Herramientas**: Argo CD, Flux, Jenkins X

### Kubernetes
- **Pods**: Unidad básica de despliegue
- **Services**: Exposición de aplicaciones
- **Deployments**: Gestión de réplicas y actualizaciones
- **ConfigMaps y Secrets**: Configuración y datos sensibles
- **Ingress**: Acceso externo a aplicaciones

### Helm
- **Charts**: Empaquetado de aplicaciones Kubernetes
- **Templates**: Generación dinámica de manifiestos
- **Values**: Configuración específica por ambiente
- **Dependencies**: Gestión de dependencias entre charts

### Argo CD
- **Aplicaciones**: Unidades de despliegue GitOps
- **Sincronización**: Mantenimiento automático del estado
- **Proyectos**: Organización y control de acceso
- **Multi-Ambiente**: Gestión de diferentes entornos

## 🚀 Próximos Pasos

1. **Seguir Laboratorios**: Ejecuta los laboratorios en orden secuencial
2. **Personalizar Configuraciones**: Modifica valores según tus necesidades
3. **Agregar Casos de Uso**: Implementa nuevos escenarios
4. **Integrar con CI/CD**: Configura pipelines automatizados
5. **Escalar Horizontalmente**: Agrega más ambientes y aplicaciones

## 📚 Documentación Detallada

- **[Laboratorio 1](docs/lab-01-simple-gitops.md)**: GitOps Básico - Empezando Simple
- **[Laboratorio 2](docs/lab-02-simple-helm.md)**: GitOps con Helm Simple
- **[Laboratorio 3](docs/lab-03-practical-cases.md)**: Casos Prácticos (próximamente)

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