
# --- ETAPA 1 ---
# Aqui instalamos todo lo que necesitamos para preparar la app
FROM node:18-alpine AS builder
WORKDIR /app

# Primero copiamos solo el package.json
COPY app/package.json ./

# Instalamos solo las dependencias de produccion (sin las de desarrollo)
RUN npm install --omit=dev --ignore-scripts && \
    npm cache clean --force

COPY app/server.js ./


# --- ETAPA 2 ---
# Esta es la imagen final que vamos a usar en produccion
FROM node:18-alpine AS runtime

# Actualizamos los paquetes del sistema para corregir vulnerabilidades conocidas
RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*

RUN npm uninstall -g npm && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn-v* \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg

# Creamos un usuario sin privilegios para correr la app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiamos solo los archivos que necesitamos desde la etapa anterior (builder)
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/server.js ./
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Cambiamos al usuario sin privilegios
USER appuser

# Le decimos a Docker que la app usa el puerto 3000
EXPOSE 3000

# Esto le dice a Docker como verificar que la app esta funcionando bien
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
