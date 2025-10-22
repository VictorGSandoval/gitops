#!/bin/bash

# Script de validación completa del laboratorio GitOps
# Verifica que todos los componentes estén funcionando correctamente

set -e

echo "🔍 Validación completa del laboratorio GitOps..."
echo "=============================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para ejecutar test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}🧪 Ejecutando: $test_name${NC}"
    
    if eval "$test_command" &> /dev/null; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Función para mostrar resumen
show_summary() {
    echo ""
    echo "📊 Resumen de validación:"
    echo "========================"
    echo -e "Total de tests: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Tests exitosos: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Tests fallidos: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ¡Todos los tests pasaron! El laboratorio está funcionando correctamente.${NC}"
        return 0
    else
        echo -e "${RED}⚠️  Hay $FAILED_TESTS test(s) fallido(s). Revisa la configuración.${NC}"
        return 1
    fi
}

# Tests de infraestructura
echo ""
echo "🏗️  Validando infraestructura..."
echo "================================"

run_test "Cluster Kubernetes funcionando" "kubectl cluster-info"
run_test "Nodos del cluster disponibles" "kubectl get nodes --no-headers | wc -l | grep -q '[1-9]'"
run_test "Namespaces del sistema creados" "kubectl get namespace kube-system"

# Tests de Argo CD
echo ""
echo "🔄 Validando Argo CD..."
echo "======================="

run_test "Argo CD instalado" "kubectl get pods -n argocd --no-headers | wc -l | grep -q '[1-9]'"
run_test "Argo CD server funcionando" "kubectl get deployment argocd-server -n argocd"
run_test "Argo CD application controller funcionando" "kubectl get deployment argocd-application-controller -n argocd"

# Tests de aplicaciones
echo ""
echo "📱 Validando aplicaciones..."
echo "============================"

run_test "Aplicaciones Argo CD configuradas" "argocd app list --output name | wc -l | grep -q '[1-9]'"
run_test "Aplicaciones sincronizadas" "argocd app list --output json | jq -r '.[] | select(.status.sync.status == \"Synced\")' | wc -l | grep -q '[1-9]'"

# Tests de Helm
echo ""
echo "📦 Validando Helm..."
echo "===================="

run_test "Helm instalado" "helm version"
run_test "Repositorios Helm configurados" "helm repo list | wc -l | grep -q '[1-9]'"

# Tests de monitoreo
echo ""
echo "📊 Validando monitoreo..."
echo "=========================="

run_test "Prometheus instalado" "kubectl get pods -n monitoring --no-headers | grep prometheus"
run_test "Grafana instalado" "kubectl get pods -n monitoring --no-headers | grep grafana"

# Tests de conectividad
echo ""
echo "🌐 Validando conectividad..."
echo "============================"

run_test "Servicios expuestos" "kubectl get svc --all-namespaces | wc -l | grep -q '[1-9]'"
run_test "Ingress configurado" "kubectl get ingress --all-namespaces | wc -l | grep -q '[1-9]'"

# Tests de seguridad
echo ""
echo "🔐 Validando seguridad..."
echo "========================="

run_test "Secretos configurados" "kubectl get secrets --all-namespaces | wc -l | grep -q '[1-9]'"
run_test "RBAC configurado" "kubectl get roles --all-namespaces | wc -l | grep -q '[1-9]'"

# Tests de GitOps
echo ""
echo "🔄 Validando GitOps..."
echo "======================"

run_test "Repositorio Git configurado" "argocd repo list | wc -l | grep -q '[1-9]'"
run_test "Proyectos Argo CD creados" "argocd proj list | wc -l | grep -q '[1-9]'"

# Tests de rendimiento
echo ""
echo "⚡ Validando rendimiento..."
echo "==========================="

run_test "Pods con recursos limitados" "kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[0].resources.limits)' | wc -l | grep -q '[1-9]'"
run_test "HPA configurado" "kubectl get hpa --all-namespaces | wc -l | grep -q '[1-9]'"

# Mostrar resumen final
show_summary

# Generar reporte detallado
echo ""
echo "📋 Generando reporte detallado..."
echo "================================="

REPORT_FILE="gitops-validation-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
Reporte de Validación GitOps Lab
===============================
Fecha: $(date)
Usuario: $(whoami)
Sistema: $(uname -a)

Resumen:
--------
Total de tests: $TOTAL_TESTS
Tests exitosos: $PASSED_TESTS
Tests fallidos: $FAILED_TESTS

Detalles del cluster:
-------------------
$(kubectl cluster-info)

Estado de Argo CD:
-----------------
$(argocd app list)

Estado de aplicaciones:
----------------------
$(kubectl get pods --all-namespaces)

Estado de servicios:
-------------------
$(kubectl get svc --all-namespaces)

Estado de ingress:
-----------------
$(kubectl get ingress --all-namespaces)

Estado de secretos:
------------------
$(kubectl get secrets --all-namespaces)

EOF

echo -e "${GREEN}📄 Reporte guardado en: $REPORT_FILE${NC}"

# Limpiar archivos temporales
cleanup() {
    echo ""
    echo "🧹 Limpiando archivos temporales..."
    rm -f /tmp/gitops-validation-*
}

trap cleanup EXIT

# Mostrar próximos pasos
echo ""
echo "🚀 Próximos pasos:"
echo "=================="
echo -e "${BLUE}1. Revisa el reporte generado: $REPORT_FILE${NC}"
echo -e "${BLUE}2. Si hay tests fallidos, consulta la documentación de troubleshooting${NC}"
echo -e "${BLUE}3. Continúa con el siguiente laboratorio${NC}"
echo -e "${BLUE}4. Configura alertas para monitoreo continuo${NC}"

exit $([ $FAILED_TESTS -eq 0 ] && echo 0 || echo 1)
