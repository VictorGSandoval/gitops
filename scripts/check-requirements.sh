#!/bin/bash

# Script de verificación de requisitos para GitOps Lab
# Verifica que todas las herramientas necesarias estén instaladas y configuradas

set -e

echo "🔍 Verificando requisitos para GitOps Lab..."
echo "=============================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar comando
check_command() {
    local cmd=$1
    local version_flag=$2
    local min_version=$3
    
    if command -v $cmd &> /dev/null; then
        if [ -n "$version_flag" ] && [ -n "$min_version" ]; then
            local version=$($cmd $version_flag 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
            if [ -n "$version" ]; then
                echo -e "${GREEN}✅ $cmd está instalado (versión: $version)${NC}"
            else
                echo -e "${YELLOW}⚠️  $cmd está instalado pero no se pudo obtener la versión${NC}"
            fi
        else
            echo -e "${GREEN}✅ $cmd está instalado${NC}"
        fi
    else
        echo -e "${RED}❌ $cmd NO está instalado${NC}"
        return 1
    fi
}

# Verificar herramientas obligatorias
echo ""
echo "📦 Verificando herramientas obligatorias:"
echo "----------------------------------------"

check_command "kubectl" "--version" "1.24"
check_command "helm" "version" "3.10"
check_command "terraform" "version" "1.5"
check_command "docker" "--version" "20.10"
check_command "git" "--version" "2.30"

# Verificar Argo CD CLI
echo ""
echo "🔧 Verificando Argo CD CLI:"
echo "---------------------------"
if command -v argocd &> /dev/null; then
    local argocd_version=$(argocd version --client --short 2>/dev/null | head -n1)
    echo -e "${GREEN}✅ Argo CD CLI está instalado (versión: $argocd_version)${NC}"
else
    echo -e "${RED}❌ Argo CD CLI NO está instalado${NC}"
    echo -e "${YELLOW}💡 Instala con: brew install argocd (macOS) o desde https://argo-cd.readthedocs.io/en/stable/cli_installation/${NC}"
fi

# Verificar clúster Kubernetes
echo ""
echo "☸️  Verificando clúster Kubernetes:"
echo "-----------------------------------"
if kubectl cluster-info &> /dev/null; then
    local cluster_info=$(kubectl cluster-info | head -n1)
    echo -e "${GREEN}✅ Clúster Kubernetes conectado${NC}"
    echo -e "${GREEN}   $cluster_info${NC}"
    
    # Verificar contexto actual
    local current_context=$(kubectl config current-context)
    echo -e "${GREEN}   Contexto actual: $current_context${NC}"
else
    echo -e "${RED}❌ No hay clúster Kubernetes conectado${NC}"
    echo -e "${YELLOW}💡 Inicia un clúster con: minikube start o kind create cluster${NC}"
fi

# Verificar Docker
echo ""
echo "🐳 Verificando Docker:"
echo "----------------------"
if docker info &> /dev/null; then
    echo -e "${GREEN}✅ Docker está ejecutándose${NC}"
else
    echo -e "${RED}❌ Docker NO está ejecutándose${NC}"
    echo -e "${YELLOW}💡 Inicia Docker Desktop o el daemon de Docker${NC}"
fi

# Verificar espacio en disco
echo ""
echo "💾 Verificando espacio en disco:"
echo "--------------------------------"
available_space=$(df -h . | awk 'NR==2 {print $4}')
echo -e "${GREEN}✅ Espacio disponible: $available_space${NC}"

# Verificar conectividad de red
echo ""
echo "🌐 Verificando conectividad:"
echo "----------------------------"
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✅ Conectividad a internet OK${NC}"
else
    echo -e "${RED}❌ Sin conectividad a internet${NC}"
fi

# Resumen final
echo ""
echo "📋 Resumen de verificación:"
echo "=========================="

# Contar herramientas instaladas
tools_installed=0
tools_total=6

[ -x "$(command -v kubectl)" ] && tools_installed=$((tools_installed + 1))
[ -x "$(command -v helm)" ] && tools_installed=$((tools_installed + 1))
[ -x "$(command -v terraform)" ] && tools_installed=$((tools_installed + 1))
[ -x "$(command -v argocd)" ] && tools_installed=$((tools_installed + 1))
[ -x "$(command -v docker)" ] && tools_installed=$((tools_installed + 1))
[ -x "$(command -v git)" ] && tools_installed=$((tools_installed + 1))

if [ $tools_installed -eq $tools_total ]; then
    echo -e "${GREEN}🎉 ¡Todos los requisitos están cumplidos!${NC}"
    echo -e "${GREEN}   Puedes proceder con el Laboratorio 1${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Faltan $((tools_total - tools_installed)) herramientas${NC}"
    echo -e "${YELLOW}   Instala las herramientas faltantes antes de continuar${NC}"
    exit 1
fi
