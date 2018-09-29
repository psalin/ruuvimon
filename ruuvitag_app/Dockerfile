FROM buildpack-deps:stretch-curl

RUN \
    apt-get update && apt-get install -qq -y python3-pip sudo bluetooth bluez blueman bluez-hcidump && \
    pip3 install ruuvitag_sensor influxdb

ADD post_to_influxdb.py /home/

WORKDIR /home

CMD python3 post_to_influxdb.py
