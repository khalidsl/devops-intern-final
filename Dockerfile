FROM python:3.11-slim

WORKDIR /app

# Copier le script principal
COPY hello.py /app/hello.py

# Exposer (pas strictement nécessaire pour ce script simple)
EXPOSE 8080

CMD ["python", "hello.py"]
