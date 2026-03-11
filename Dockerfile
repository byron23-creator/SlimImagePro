# Usamos node:18-alpine porque es mucho mas liviana que node:18 normal
# Alpine es una distro de Linux super pequeña, perfecta para contenedores

# --- ETAPA 1: builder ---
# Aqui instalamos todo lo que necesitamos para preparar la app
FROM node:18-alpine AS builder

# Definimos donde va a vivir nuestra app dentro del contenedor
WORKDIR /app

# Primero copiamos solo el package.json
# Esto es un truco para que Docker use el cache si no cambiaron las dependencias
COPY app/package.json ./

# Instalamos solo las dependencias de produccion (sin las de desarrollo)
# --ignore-scripts evita que se ejecuten scripts raros durante la instalacion
RUN npm install --omit=dev --ignore-scripts && \
    npm cache clean --force

# Ahora si copiamos el codigo de la app
COPY app/server.js ./


# --- ETAPA 2: runtime ---
# Esta es la imagen final que vamos a usar en produccion
# Solo tiene lo minimo necesario para correr la app
FROM node:18-alpine AS runtime

# Actualizamos los paquetes del sistema para corregir vulnerabilidades conocidas
# Esto es importante para que la imagen pase los escaneos de seguridad
RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*

# Borramos npm y yarn porque no los necesitamos para correr la app
# Esto tambien elimina algunas vulnerabilidades que vienen con ellos
RUN npm uninstall -g npm && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn-v* \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg

# Creamos un usuario sin privilegios para correr la app
# No es buena idea correr cosas como root en produccion
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiamos solo los archivos que necesitamos desde la etapa anterior (builder)
# El --chown hace que el usuario appuser sea el dueño de esos archivos
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

# Comando para arrancar la app
CMD ["node", "server.js"]
