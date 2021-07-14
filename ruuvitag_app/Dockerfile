FROM python:slim

RUN \
    apt-get update && \
    apt-get -q -y install bluez bluez-hcidump sudo && \
    pip install --no-cache-dir influxdb ruuvitag_sensor

WORKDIR /home/ruuvimon
COPY ruuvimon.py ./

CMD python3 ruuvimon.py
