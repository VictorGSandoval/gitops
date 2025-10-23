# Laboratorio 3: Kustomize con Argo CD

Este laboratorio te guiará en el uso de Kustomize para manejar diferentes ambientes (dev/prod) usando Argo CD.

## Estructura de Kustomize

```
manifests/kustomize/
├── base/                  # Configuración base
│   ├── deployment.yaml    # Deployment base
│   ├── service.yaml       # Service base
│   └── kustomization.yaml # Kustomization base
└── overlays/             # Variaciones por ambiente
    ├── dev/              # Ambiente de desarrollo
    │   ├── kustomization.yaml
    │   └── replicas-patch.yaml
    └── prod/             # Ambiente de producción
        ├── kustomization.yaml
        ├── replicas-patch.yaml
        └── resources-patch.yaml
```

## Parte 1: Entender la Estructura

1. **Base**: Contiene la configuración común
   - Deployment básico de nginx
   - Service NodePort
   - Labels comunes

2. **Overlays**: Personalizaciones por ambiente
   - **Dev**: 1 réplica, recursos mínimos
   - **Prod**: 3 réplicas, más recursos, versión Alpine

## Parte 2: Desplegar con Argo CD

1. Revisar el manifiesto de la aplicación:
```bash
cat manifests/application-kustomize-dev.yaml
```

2. Aplicar la configuración de desarrollo:
```bash
kubectl apply -f manifests/application-kustomize-dev.yaml
```

3. Verificar el despliegue:
```bash
# Verificar pods en dev
kubectl get pods -n demo-dev

# Verificar configuración
kubectl describe deployment nginx-deployment -n demo-dev
```

## Parte 3: Explorar Kustomize

1. Previsualizar cambios de Kustomize:
```bash
# Ver configuración de dev
kubectl kustomize manifests/kustomize/overlays/dev

# Ver configuración de prod
kubectl kustomize manifests/kustomize/overlays/prod
```

2. Entender las diferencias:
   - Diferentes namespaces
   - Diferentes números de réplicas
   - Diferentes recursos asignados
   - Labels específicos por ambiente

## Parte 4: Modificaciones

1. Modificar recursos en dev:
   - Editar `overlays/dev/kustomization.yaml`
   - Agregar parches de recursos
   - Observar la sincronización automática

2. Desplegar versión de producción:
   - Crear nuevo archivo de aplicación para prod
   - Aplicar y comparar con dev

## Ventajas de Kustomize

1. **Reutilización**: Base común para todos los ambientes
2. **Mantenibilidad**: Cambios específicos por ambiente
3. **Claridad**: Estructura clara y separación de configuraciones
4. **GitOps**: Perfecto para el flujo de trabajo con Argo CD