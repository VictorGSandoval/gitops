# Laboratorio 4: Helm Charts con Argo CD

Este laboratorio te guiará en el uso de Helm Charts para despliegues más sofisticados usando Argo CD.

## Estructura del Chart

```
manifests/helm/nginx-chart/
├── Chart.yaml          # Metadata del chart
├── values.yaml         # Valores por defecto
└── templates/          # Plantillas
    ├── configmap.yaml  # Configuración de Nginx
    ├── deployment.yaml # Deployment parametrizado
    └── service.yaml    # Service parametrizado
```

## Parte 1: Entender la Estructura del Chart

1. **Chart.yaml**: Define la versión y metadata
2. **values.yaml**: Valores configurables
   - Número de réplicas
   - Imagen y tag
   - Configuración del service
   - Recursos
   - Configuración de Nginx

3. **Templates**: Plantillas parametrizadas
   - Uso de variables
   - Condicionales
   - Helpers

## Parte 2: Desplegar con Argo CD

1. Revisar la configuración de la aplicación:
```bash
cat manifests/application-helm.yaml
```

2. Desplegar la aplicación:
```bash
kubectl apply -f manifests/application-helm.yaml
```

```
# Sin Argo CD - instalación directa con Helm
helm install mi-nginx ./nginx-chart --version 0.1.0
```

3. Verificar el despliegue:
```bash
# Verificar pods
kubectl get pods -n demo-helm

# Verificar service
kubectl get svc -n demo-helm

# Verificar configmap
kubectl get configmap -n demo-helm
```

## Parte 3: Personalización

1. Probar la aplicación:
```bash
# La aplicación estará disponible en:
http://localhost:30082
```

2. Verificar el health check:
```bash
curl http://localhost:30082/health
# Debería retornar: healthy
```

## Parte 4: Modificaciones

1. Modificar valores en GitHub:
   - Editar `values.yaml`
   - Cambiar número de réplicas
   - Actualizar configuración de recursos
   - Observar la sincronización automática

2. Usar diferentes valores para ambientes:
   - Crear `values-prod.yaml`
   - Modificar la aplicación para usar diferentes valores
   - Comparar configuraciones

## Ventajas de Helm

1. **Parametrización**: Valores configurables
2. **Reutilización**: Templates reutilizables
3. **Versionamiento**: Control de versiones de charts
4. **Rollbacks**: Facilidad para volver a versiones anteriores

## Ejercicios Sugeridos

1. Agregar un Ingress al chart
2. Implementar health checks personalizados
3. Crear valores para diferentes ambientes
4. Agregar variables de entorno configurables