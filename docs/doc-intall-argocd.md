# Guía Rápida: Argo CD en Kubernetes

## Instalación con Helm

```
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=30080 \
  --set configs.params.server\.insecure=true
```

## Verificar instalación

```
kubectl get pods -n argocd
kubectl get svc -n argocd
```

## Instalación con YAML

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

## Obtener contraseña

```
kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.admin\.password}" | base64 -d
```

## Acceder

http://localhost:30080
Usuario: admin
Contraseña: [resultado del comando anterior]

## Limpieza con Helm

```
helm uninstall argocd -n argocd
kubectl delete namespace argocd
```

## Limpieza con YAML

```
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## Comandos útiles

```
kubectl get all -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
```