# Latest version 2.0+ doesn't support arm32v7
FROM influxdb:1.8

RUN \
    apt-get update && \
    apt-get -y -q install openssh-client rsync sudo

# Install influxdb-incremental-restore
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN sudo apt-get install -y nodejs && sudo apt-get install -y build-essential
RUN npm install --unsafe-perm -g @motleyagency/influxdb-incremental-restore

WORKDIR /home/ruuvimon

COPY entrypoint.sh ./
COPY import_export.sh ./

RUN ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

CMD ./entrypoint.sh
