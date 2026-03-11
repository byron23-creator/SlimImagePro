# Slim Node.js Docker Image — Optimización y Seguridad

## Descripción

Aplicación Node.js (Express) con un Dockerfile multi-stage optimizado para producción:

- **Imagen base ligera**: `node:18-alpine` (no `node:latest` ni `ubuntu`)
- **Multi-stage build**: etapa `builder` (instala dependencias) + etapa `runtime` (solo lo necesario)
- **Sin vulnerabilidades CRITICAL ni HIGH** verificado con Trivy
- **Usuario no-root** en tiempo de ejecución
- **npm/yarn eliminados** del runtime (no se necesitan en producción)

---

## Estructura del proyecto

```
.
├── app/
│   ├── package.json      # Dependencias de la aplicación
│   └── server.js         # Servidor Express
├── Dockerfile            # Dockerfile optimizado (multi-stage, Alpine)
├── Dockerfile.standard   # Dockerfile estándar (para comparación de tamaño)
├── .dockerignore
└── README.md
```

---

## Comparación de tamaño de imagen

| Imagen                    | Base          | Tamaño  |
|---------------------------|---------------|---------|
| `slim-node-app:standard`  | `node:18`     | 1.57 GB |
| `slim-node-app:optimized` | `node:18-alpine` | 195 MB |

**Reducción: ~88% menos espacio**

---

## Resultado del escaneo de seguridad (Trivy)

```
trivy image --severity HIGH,CRITICAL --scanners vuln slim-node-app:optimized
```

**Resultado: 0 vulnerabilidades CRITICAL, 0 vulnerabilidades HIGH**

Todas las entradas del reporte muestran `0` vulnerabilidades.

---

## Cómo construir y ejecutar

```bash
# Imagen optimizada
docker build -f Dockerfile -t slim-node-app:optimized .

# Imagen estándar (para comparación)
docker build -f Dockerfile.standard -t slim-node-app:standard .

# Ejecutar
docker run -p 3000:3000 slim-node-app:optimized

# Comparar tamaños
docker images slim-node-app

# Escanear vulnerabilidades
trivy image --severity HIGH,CRITICAL --scanners vuln slim-node-app:optimized
```

---

## Técnicas de optimización aplicadas

1. **Multi-stage build**: La etapa `builder` instala dependencias; la etapa `runtime` solo copia los artefactos necesarios.
2. **Imagen base Alpine**: `node:18-alpine` (~50 MB) vs `node:18` (~1.1 GB base).
3. **Solo dependencias de producción**: `npm install --omit=dev`.
4. **npm/yarn eliminados del runtime**: Reduce superficie de ataque y elimina CVEs de sus dependencias internas.
5. **`apk upgrade`**: Actualiza todos los paquetes del SO para parchear CVEs de OpenSSL y otros.
6. **Usuario no-root**: `appuser` en lugar de `root`.
7. **Caché de npm limpiada**: `npm cache clean --force`.
8. **`.dockerignore`**: Excluye archivos innecesarios del contexto de build.
9. **HEALTHCHECK**: Monitoreo integrado del contenedor.
