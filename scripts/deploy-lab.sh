#!/bin/bash

# Script de despliegue automático para GitOps Lab
# Despliega toda la infraestructura y aplicaciones de forma automatizada

set -e

echo "🚀 Despliegue automático del laboratorio GitOps..."
echo "================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
ENVIRONMENT=${1:-dev}
CLUSTER_TYPE=${2:-minikube}
DRY_RUN=${3:-false}

echo -e "${BLUE}Configuración:${NC}"
echo -e "  Ambiente: $ENVIRONMENT"
echo -e "  Tipo de cluster: $CLUSTER_TYPE"
echo -e "  Modo dry-run: $DRY_RUN"
echo ""

# Función para ejecutar comando con validación
run_command() {
    local description="$1"
    local command="$2"
    local required="$3"
    
    echo -e "${YELLOW}📋 $description${NC}"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${BLUE}  [DRY-RUN] $command${NC}"
        return 0
    fi
    
    if eval "$command"; then
        echo -e "${GREEN}  ✅ $description completado${NC}"
        return 0
    else
        echo -e "${RED}  ❌ $description falló${NC}"
        if [ "$required" = "true" ]; then
            echo -e "${RED}  ⚠️  Este paso es requerido. Abortando despliegue.${NC}"
            exit 1
        else
            echo -e "${YELLOW}  ⚠️  Continuando sin este paso...${NC}"
            return 1
        fi
    fi
}

# Función para esperar que un recurso esté listo
wait_for_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local namespace="$3"
    local timeout="${4:-300}"
    
    echo -e "${YELLOW}⏳ Esperando que $resource_type/$resource_name esté listo...${NC}"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${BLUE}  [DRY-RUN] kubectl wait --for=condition=available --timeout=${timeout}s $resource_type/$resource_name -n $namespace${NC}"
        return 0
    fi
    
    if kubectl wait --for=condition=available --timeout="${timeout}s" "$resource_type/$resource_name" -n "$namespace" &> /dev/null; then
        echo -e "${GREEN}  ✅ $resource_type/$resource_name está listo${NC}"
        return 0
    else
        echo -e "${RED}  ❌ $resource_type/$resource_name no está listo después de ${timeout}s${NC}"
        return 1
    fi
}

# Paso 1: Verificar requisitos
echo "🔍 Paso 1: Verificando requisitos..."
echo "===================================="

run_command "Verificando requisitos del sistema" "./scripts/check-requirements.sh" "true"

# Paso 2: Configurar cluster
echo ""
echo "🏗️  Paso 2: Configurando cluster..."
echo "==================================="

run_command "Configurando cluster $CLUSTER_TYPE" "./scripts/setup-cluster.sh --$CLUSTER_TYPE" "true"

# Paso 3: Desplegar infraestructura
echo ""
echo "🏢 Paso 3: Desplegando infraestructura..."
echo "========================================"

if [ -d "infra/environments/$ENVIRONMENT" ]; then
    run_command "Inicializando Terraform" "cd infra/environments/$ENVIRONMENT && terraform init" "true"
    run_command "Planificando infraestructura" "cd infra/environments/$ENVIRONMENT && terraform plan" "false"
    run_command "Aplicando infraestructura" "cd infra/environments/$ENVIRONMENT && terraform apply -auto-approve" "true"
else
    echo -e "${YELLOW}⚠️  No se encontró configuración de infraestructura para $ENVIRONMENT${NC}"
fi

# Paso 4: Configurar Argo CD
echo ""
echo "🔄 Paso 4: Configurando Argo CD..."
echo "=================================="

run_command "Aplicando proyectos Argo CD" "kubectl apply -f argocd/projects/" "true"
run_command "Aplicando aplicaciones Argo CD" "kubectl apply -f argocd/applications/" "true"

# Esperar a que Argo CD esté listo
wait_for_resource "deployment" "argocd-server" "argocd" 300
wait_for_resource "deployment" "argocd-application-controller" "argocd" 300

# Paso 5: Configurar monitoreo
echo ""
echo "📊 Paso 5: Configurando monitoreo..."
echo "===================================="

run_command "Creando namespace de monitoreo" "kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -" "true"
run_command "Aplicando stack de monitoreo" "kubectl apply -f argocd/applications/monitoring-stack.yaml" "false"

# Esperar a que Prometheus esté listo
wait_for_resource "deployment" "monitoring-stack-prometheus-operator" "monitoring" 600

# Paso 6: Configurar aplicaciones
echo ""
echo "📱 Paso 6: Configurando aplicaciones..."
echo "======================================"

run_command "Creando namespaces de aplicaciones" "kubectl create namespace $ENVIRONMENT --dry-run=client -o yaml | kubectl apply -f -" "true"
run_command "Aplicando aplicaciones base" "kubectl apply -f apps/base/" "true"

# Paso 7: Sincronizar aplicaciones
echo ""
echo "🔄 Paso 7: Sincronizando aplicaciones..."
echo "======================================"

if [ "$DRY_RUN" = "false" ]; then
    echo -e "${YELLOW}⏳ Esperando a que las aplicaciones se sincronicen...${NC}"
    
    # Obtener lista de aplicaciones
    apps=$(argocd app list --output name)
    
    for app in $apps; do
        echo -e "${BLUE}🔄 Sincronizando $app...${NC}"
        argocd app sync "$app" --force || echo -e "${YELLOW}⚠️  No se pudo sincronizar $app${NC}"
    done
    
    # Esperar a que las aplicaciones estén sincronizadas
    echo -e "${YELLOW}⏳ Esperando sincronización completa...${NC}"
    sleep 30
    
    # Verificar estado de las aplicaciones
    echo -e "${BLUE}📊 Estado de las aplicaciones:${NC}"
    argocd app list
fi

# Paso 8: Configurar ingress
echo ""
echo "🌐 Paso 8: Configurando ingress..."
echo "=================================="

run_command "Instalando NGINX Ingress Controller" "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml" "false"

if [ "$CLUSTER_TYPE" = "kind" ]; then
    run_command "Configurando hosts locales" "echo '127.0.0.1 argocd.local nginx-dev.local api-dev.local grafana.local' | sudo tee -a /etc/hosts" "false"
fi

# Paso 9: Validación final
echo ""
echo "✅ Paso 9: Validación final..."
echo "=============================="

run_command "Ejecutando validación completa" "./scripts/validate-lab.sh" "false"

# Paso 10: Mostrar información de acceso
echo ""
echo "🔗 Paso 10: Información de acceso..."
echo "===================================="

if [ "$DRY_RUN" = "false" ]; then
    echo -e "${GREEN}🎉 ¡Despliegue completado exitosamente!${NC}"
    echo ""
    echo -e "${BLUE}📋 Información de acceso:${NC}"
    echo ""
    
    # Argo CD
    echo -e "${YELLOW}🔄 Argo CD:${NC}"
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        echo -e "  URL: https://localhost:8080"
        echo -e "  Usuario: admin"
        echo -e "  Contraseña: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
        echo -e "  Comando para port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    else
        echo -e "  URL: http://argocd.local"
        echo -e "  Usuario: admin"
        echo -e "  Contraseña: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    fi
    echo ""
    
    # Aplicaciones
    echo -e "${YELLOW}📱 Aplicaciones:${NC}"
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        echo -e "  Nginx Dev: kubectl port-forward svc/nginx-app -n $ENVIRONMENT 8081:80"
        echo -e "  API Dev: kubectl port-forward svc/api-app -n $ENVIRONMENT 8082:3000"
    else
        echo -e "  Nginx Dev: http://nginx-dev.local"
        echo -e "  API Dev: http://api-dev.local"
    fi
    echo ""
    
    # Monitoreo
    echo -e "${YELLOW}📊 Monitoreo:${NC}"
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        echo -e "  Grafana: kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80"
        echo -e "  Prometheus: kubectl port-forward svc/monitoring-stack-prometheus -n monitoring 9090:9090"
    else
        echo -e "  Grafana: http://grafana.local"
        echo -e "  Prometheus: http://prometheus.local"
    fi
    echo ""
    
    # Comandos útiles
    echo -e "${YELLOW}🛠️  Comandos útiles:${NC}"
    echo -e "  Ver aplicaciones: argocd app list"
    echo -e "  Ver pods: kubectl get pods --all-namespaces"
    echo -e "  Ver servicios: kubectl get svc --all-namespaces"
    echo -e "  Ver ingress: kubectl get ingress --all-namespaces"
    echo ""
    
    # Próximos pasos
    echo -e "${YELLOW}🚀 Próximos pasos:${NC}"
    echo -e "  1. Accede a Argo CD y explora las aplicaciones"
    echo -e "  2. Prueba las aplicaciones desplegadas"
    echo -e "  3. Configura alertas en Grafana"
    echo -e "  4. Continúa con el siguiente laboratorio"
    echo ""
    
    # Generar reporte
    REPORT_FILE="deployment-report-$(date +%Y%m%d-%H%M%S).txt"
    cat > "$REPORT_FILE" << EOF
Reporte de Despliegue GitOps Lab
===============================
Fecha: $(date)
Ambiente: $ENVIRONMENT
Tipo de cluster: $CLUSTER_TYPE

Estado del cluster:
------------------
$(kubectl cluster-info)

Aplicaciones desplegadas:
------------------------
$(argocd app list)

Recursos del cluster:
-------------------
$(kubectl get all --all-namespaces)

EOF
    
    echo -e "${GREEN}📄 Reporte de despliegue guardado en: $REPORT_FILE${NC}"
else
    echo -e "${BLUE}🔍 Modo dry-run completado. Revisa los comandos antes de ejecutar el despliegue real.${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Despliegue del laboratorio GitOps completado${NC}"
