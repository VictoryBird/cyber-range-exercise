FROM python:3.11-slim

WORKDIR /opt/plc-simulator

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/plc_simulator.py .
COPY .env.example .env

EXPOSE 5000

CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "2", \
     "--threads", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "plc_simulator:app"]
