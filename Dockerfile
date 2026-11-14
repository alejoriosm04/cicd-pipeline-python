# Dockerfile
# Usa una imagen base oficial de Python. Elige una versión específica para consistencia.
FROM python:3.13-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia el lockfile primero para aprovechar el cache de Docker
COPY requirements.lock .

# Instala solo wheels con versiones y hashes fijados (Flask, Gunicorn y transitivas)
# Usa --no-cache-dir para reducir el tamaño de la imagen
RUN pip install --no-cache-dir --require-hashes --only-binary :all: -r requirements.lock

# Copia el código de la aplicación (solo la carpeta app)
COPY app/ ./app/

# El proceso no corre como root
RUN groupadd --gid 1000 app \
    && useradd --uid 1000 --gid app --home-dir /app --no-create-home --shell /usr/sbin/nologin app \
    && chown -R app:app /app
USER app

# Expón el puerto en el que Gunicorn servirá la aplicación
# Gunicorn por defecto usa 8000, así que usaremos ese.
EXPOSE 8000

# Comando para ejecutar la aplicación usando Gunicorn cuando el contenedor inicie
# 'app.app:app' significa: del archivo app.py dentro del paquete app, usa la instancia 'app' de Flask.
# 'workers=4' es un ejemplo, ajusta según sea necesario.
# 'bind 0.0.0.0:8000' hace que Gunicorn escuche en todas las interfaces de red en el puerto 8000.
# '--preload' importa la app una sola vez, así el SECRET_KEY (y el token CSRF) es el mismo en cada worker.
CMD ["gunicorn", "--workers=4", "--preload", "--bind=0.0.0.0:8000", "app.app:app"]
