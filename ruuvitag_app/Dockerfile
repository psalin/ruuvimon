FROM python:slim

RUN \
    apt-get update && \
    apt-get -q -y install bluez bluez-hcidump sudo && \
    pip install --no-cache-dir influxdb ruuvitag_sensor

WORKDIR /home/ruuvimon
COPY post_to_influxdb.py ./

CMD python3 post_to_influxdb.py
