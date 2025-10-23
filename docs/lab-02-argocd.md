# Laboratorio 2: Despliegue Progresivo con Argo CD

Este laboratorio te guiará en el uso de Argo CD para desplegar aplicaciones usando manifiestos YAML básicos.

## Preparación del Repositorio

1. Clonar el repositorio:
```bash
git clone https://github.com/VictorGSandoval/gitops.git
cd gitops
```

## Parte 1: Configuración de Argo CD

1. Verificar que Argo CD está funcionando:
```bash
kubectl get pods -n argocd
```

2. Obtener la contraseña de admin:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. Acceder a la UI de Argo CD:
   - URL: http://localhost:8080
   - Usuario: admin
   - Contraseña: [la obtenida en el paso anterior]

## Parte 2: Desplegar la Aplicación Demo

1. Revisar los manifiestos en el directorio `manifests/basic/`:
   - `deployment.yaml`: Nginx con 2 réplicas
   - `service.yaml`: Expone Nginx en el puerto 30081
   - `application.yaml`: Configuración de Argo CD

2. Aplicar la configuración:
```bash
kubectl apply -f manifests/basic/application.yaml
```

3. Verificar el despliegue:
```bash
# Verificar que la aplicación se ha creado en Argo CD
kubectl get applications -n argocd

# Verificar los pods
kubectl get pods -n demo

# Verificar el servicio
kubectl get svc -n demo
```

4. Acceder a la aplicación:
```bash
# La aplicación estará disponible en:
http://localhost:30081
```

## Parte 3: Prueba de GitOps

1. Modificar el número de réplicas en GitHub:
   - Ir a https://github.com/VictorGSandoval/gitops
   - Editar `manifests/basic/deployment.yaml`
   - Cambiar `replicas: 2` a `replicas: 3`
   - Commit y push

2. Observar en Argo CD:
   - La UI mostrará que hay cambios
   - Argo CD sincronizará automáticamente
   - Se creará un nuevo pod

3. Verificar el cambio:
```bash
kubectl get pods -n demo
```

## Parte 2: Kustomize (Próximamente)

Evolucionar a Kustomize para manejar variaciones de ambiente.

## Parte 3: Helm Charts (Próximamente)

Finalizar con Helm Charts para despliegues más complejos.

## Verificación

```bash
# Verificar el estado de la aplicación
kubectl get applications -n argocd

# Verificar los pods desplegados
kubectl get pods -n demo
```