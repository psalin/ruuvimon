FROM arm32v7/influxdb:latest

RUN apt-get update && apt-get -y install cron && apt-get -y install rsync && apt-get -y install openssh-client && apt-get -y install sudo

# Install influxdb-incremental-restore
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN sudo apt-get install -y nodejs && sudo apt-get install -y build-essential
RUN npm install --unsafe-perm -g @motleyagency/influxdb-incremental-restore

ADD import_export.sh /home/

RUN ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

# Add crontab file in the cron directory
ADD crontab /etc/cron.d/import-export-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/import-export-cron

# Apply cron job
RUN crontab /etc/cron.d/import-export-cron

# Run the command on container startup
CMD printenv >> /etc/environment && cron && influxd


