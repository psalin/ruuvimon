# Latest version 2.0+ doesn't support arm32v7
FROM influxdb:1.8

RUN \
    apt-get update && \
    apt-get -y -q install openssh-client openssh-server rsync sshpass sudo

# Install influxdb-incremental-restore
RUN curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo apt-get install -y build-essential nodejs
RUN npm install --unsafe-perm -g @motleyagency/influxdb-incremental-restore

WORKDIR /home/ruuvimon

COPY entrypoint.sh ./
COPY import_export.sh ./

CMD ./entrypoint.sh
