// Importamos express, que es el framework que usamos para crear el servidor
const express = require('express');

// Creamos la app de express
const app = express();

// El puerto donde va a escuchar el servidor
// Usamos una variable de entorno por si acaso, y si no existe usamos 3000
const PORT = process.env.PORT || 3000;

// Ruta principal - cuando alguien entra a "/" le mandamos un saludo
app.get('/', (req, res) => {
  res.json({
    message: 'Hola! El servidor esta funcionando correctamente',
    version: '1.0.0'
  });
});

// Ruta de health check - Docker la usa para saber si la app esta viva
// Si responde 200 significa que todo esta bien
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Arrancamos el servidor y lo ponemos a escuchar en el puerto definido
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
