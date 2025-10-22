# GitOps Laboratorio Práctico
## Infraestructura y Despliegues Auditables con Terraform, Argo CD y Helm

Este repositorio contiene un laboratorio completo y práctico para implementar GitOps usando las herramientas más populares del ecosistema: **Terraform**, **Argo CD** y **Helm**.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Laboratorios Disponibles](#laboratorios-disponibles)
4. [Guía de Inicio Rápido](#guía-de-inicio-rápido)
5. [Casos de Uso Prácticos](#casos-de-uso-prácticos)
6. [Scripts de Automatización](#scripts-de-automatización)

## 🔧 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado y configurado:

### Herramientas Obligatorias
- **kubectl** (v1.24+)
- **helm** (v3.10+)
- **terraform** (v1.5+)
- **argocd CLI** (v2.7+)
- **docker** (v20.10+)
- **git** (v2.30+)

### Clúster Kubernetes
- **Minikube** (recomendado para desarrollo local)
- **Kind** (alternativa ligera)
- **Clúster en la nube** (EKS, GKE, AKS)

### Verificación de Requisitos
```bash
# Ejecuta el script de verificación
./scripts/check-requirements.sh
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

## 🧪 Laboratorios Disponibles

### Laboratorio 1: Configuración Inicial
- [ ] Verificación de requisitos
- [ ] Configuración del clúster Kubernetes
- [ ] Instalación de Argo CD
- [ ] Configuración inicial de GitOps

### Laboratorio 2: Infraestructura con Terraform
- [ ] Creación de recursos básicos
- [ ] Configuración de módulos
- [ ] Gestión de estados
- [ ] Integración con Kubernetes

### Laboratorio 3: Aplicaciones con Helm
- [ ] Creación de Helm charts
- [ ] Configuración de valores
- [ ] Gestión de dependencias
- [ ] Testing de charts

### Laboratorio 4: GitOps con Argo CD
- [ ] Configuración de aplicaciones
- [ ] Sincronización automática
- [ ] Gestión de proyectos
- [ ] Monitoreo y alertas

### Laboratorio 5: Casos de Uso Avanzados
- [ ] Multi-ambiente (dev/staging/prod)
- [ ] Gestión de secretos
- [ ] Rollbacks automáticos
- [ ] CI/CD integration

## 🚀 Guía de Inicio Rápido

1. **Clona y configura el repositorio:**
   ```bash
   git clone <tu-repositorio>
   cd gitops
   ```

2. **Verifica los requisitos:**
   ```bash
   ./scripts/check-requirements.sh
   ```

3. **Inicia el clúster local:**
   ```bash
   ./scripts/setup-cluster.sh
   ```

4. **Despliega todo el laboratorio:**
   ```bash
   ./scripts/deploy-lab.sh dev minikube
   ```

5. **Valida el despliegue:**
   ```bash
   ./scripts/validate-lab.sh
   ```

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