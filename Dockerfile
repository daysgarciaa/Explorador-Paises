FROM python:3.11-slim
LABEL description="World Explorer: consulta geográfica y climática de países."
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV COUNTRY_NAME=Chile
ENV REQUEST_TIMEOUT=10
CMD ["python", "app.py"]
