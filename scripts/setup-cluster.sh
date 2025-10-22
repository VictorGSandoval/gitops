#!/bin/bash

# Script de configuración inicial del clúster para GitOps Lab
# Configura Minikube/Kind y instala Argo CD

set -e

echo "🚀 Configurando clúster para GitOps Lab..."
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPTIONS]"
    echo ""
    echo "Opciones:"
    echo "  --minikube    Usar Minikube (por defecto)"
    echo "  --kind        Usar Kind"
    echo "  --help        Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 --minikube"
    echo "  $0 --kind"
}

# Detectar tipo de clúster
CLUSTER_TYPE="minikube"

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --minikube)
            CLUSTER_TYPE="minikube"
            shift
            ;;
        --kind)
            CLUSTER_TYPE="kind"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}Usando: $CLUSTER_TYPE${NC}"

# Función para configurar Minikube
setup_minikube() {
    echo ""
    echo "🔧 Configurando Minikube..."
    echo "----------------------------"
    
    # Verificar si Minikube está instalado
    if ! command -v minikube &> /dev/null; then
        echo -e "${RED}❌ Minikube no está instalado${NC}"
        echo -e "${YELLOW}💡 Instala con: brew install minikube (macOS)${NC}"
        exit 1
    fi
    
    # Iniciar Minikube si no está corriendo
    if ! minikube status &> /dev/null; then
        echo -e "${YELLOW}Iniciando Minikube...${NC}"
        minikube start --memory=4096 --cpus=2 --disk-size=20g
    else
        echo -e "${GREEN}✅ Minikube ya está ejecutándose${NC}"
    fi
    
    # Configurar kubectl
    minikube kubectl -- get nodes
    echo -e "${GREEN}✅ Minikube configurado correctamente${NC}"
}

# Función para configurar Kind
setup_kind() {
    echo ""
    echo "🔧 Configurando Kind..."
    echo "-----------------------"
    
    # Verificar si Kind está instalado
    if ! command -v kind &> /dev/null; then
        echo -e "${RED}❌ Kind no está instalado${NC}"
        echo -e "${YELLOW}💡 Instala con: brew install kind (macOS)${NC}"
        exit 1
    fi
    
    # Crear clúster Kind si no existe
    if ! kind get clusters | grep -q "gitops-lab"; then
        echo -e "${YELLOW}Creando clúster Kind 'gitops-lab'...${NC}"
        cat <<EOF | kind create cluster --name gitops-lab --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
    else
        echo -e "${GREEN}✅ Clúster Kind 'gitops-lab' ya existe${NC}"
    fi
    
    # Configurar kubectl
    kubectl config use-context kind-gitops-lab
    kubectl get nodes
    echo -e "${GREEN}✅ Kind configurado correctamente${NC}"
}

# Configurar clúster según el tipo
case $CLUSTER_TYPE in
    minikube)
        setup_minikube
        ;;
    kind)
        setup_kind
        ;;
esac

# Instalar Argo CD
echo ""
echo "📦 Instalando Argo CD..."
echo "------------------------"

# Crear namespace para Argo CD
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Instalar Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que Argo CD esté listo
echo -e "${YELLOW}Esperando a que Argo CD esté listo...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Obtener contraseña inicial
echo ""
echo "🔐 Configuración de Argo CD:"
echo "----------------------------"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}Usuario: admin${NC}"
echo -e "${GREEN}Contraseña: $ARGOCD_PASSWORD${NC}"

# Configurar acceso al servidor Argo CD
if [ "$CLUSTER_TYPE" = "minikube" ]; then
    # Para Minikube, usar port-forward
    echo -e "${YELLOW}Para acceder a Argo CD, ejecuta:${NC}"
    echo -e "${BLUE}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
    echo -e "${BLUE}Luego visita: https://localhost:8080${NC}"
elif [ "$CLUSTER_TYPE" = "kind" ]; then
    # Para Kind, configurar ingress
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
    echo -e "${YELLOW}Para acceder a Argo CD, agrega a tu /etc/hosts:${NC}"
    echo -e "${BLUE}127.0.0.1 argocd.local${NC}"
    echo -e "${BLUE}Luego visita: http://argocd.local${NC}"
fi

# Instalar herramientas adicionales
echo ""
echo "🛠️  Instalando herramientas adicionales..."
echo "----------------------------------------"

# Instalar NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager

echo ""
echo "🎉 ¡Configuración completada!"
echo "============================="
echo -e "${GREEN}✅ Clúster Kubernetes configurado${NC}"
echo -e "${GREEN}✅ Argo CD instalado${NC}"
echo -e "${GREEN}✅ NGINX Ingress Controller instalado${NC}"
echo -e "${GREEN}✅ cert-manager instalado${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo -e "${BLUE}1. Accede a Argo CD usando las credenciales mostradas arriba${NC}"
echo -e "${BLUE}2. Continúa con el Laboratorio 1: docs/lab-01-setup.md${NC}"
echo -e "${BLUE}3. Configura tu repositorio Git para GitOps${NC}"
