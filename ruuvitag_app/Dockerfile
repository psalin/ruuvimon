FROM python:slim

RUN \
    apt update && \
    apt install -qq -y sudo bluez bluez-hcidump && \
    pip install --no-cache-dir ruuvitag_sensor influxdb

WORKDIR /home/ruuvimon
COPY post_to_influxdb.py ./

CMD python3 post_to_influxdb.py
