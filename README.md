# RuuviMon

RuuviMon is a simple application for monitoring [RuuviTag](https://ruuvi.com/ruuvitag/) sensors.

It collects data from the sensors, stores it into InfluxDB and provides visualization of the data through Grafana. It also includes Telegraf for monitoring host resources.

## Requirements

- Linux (amd64, arm32v7 or arm64v8 architectures)
- Docker
- Docker Compose

### Grafana container requirements for HTTPS

Alpine 3.13, which is used inside the Grafana container has some [requirements](https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0#time64_requirements) which can affect the use of HTTPS for Grafana.

This affects Raspberry Pi OS Buster which does not currently fulfil the requirements. The issue can be solved by manually installing a newer version of libseccomp2:

```sh
wget http://raspbian.raspberrypi.org/raspbian/pool/main/libs/libseccomp/libseccomp2_2.5.1-1+rpi1_armhf.deb
sudo dpkg -i libseccomp2_2.5.1-1+rpi1_armhf.deb
```

## Installation and usage

1. Clone the repo into an environment that fulfils the [requirements](#Requirements)

    ```sh
    git clone https://github.com/psalin/ruuvimon
    ```

2. If needed, make changes to the configuration in .env

    The default configuration works out of the box and collects temperature, pressure, humidity and battery. To change which fields are collected you can update the RUUVIMON_FIELDS parameter. There are also several other parameters that can be changed if needed.

3. Start RuuviMon

    ```sh
    ./start.sh
    ```

    This will use docker-compose to download and build the services that are part of the applicaiton. After starting, the application consists of four running containers: ruuvitag_app, grafana, influxdb and telegraf.

4. Monitor collected data in Grafana

    To start monitoring the collected data, connect to Grafana at your host. By default:

    `https://localhost:3000/`

    RuuviMon provisions Grafana with dashboards Ruuvitag and Telegraf. The Ruuvitag dashboard can show all data collected from the RuuviTags and the Telegraf dashboard can be used for monitoring host resources.

### Stopping
In order to stop the RuuviMon application run:

```sh
./stop.sh
```

## Import/export mode

In addition to the normal standalone mode, RuuviMon also supports import/export modes. The collecting RuuviMon app can export data to another RuuviMon app running in import mode. This enables running RuuviMon in a remote location with data restricted Internet access. The RuuviMon application running in import mode provides the user with access to view collected data without affecting the data rates at the software collecting data remotely.

RuuviMon provides configuration parameters that can be adjusted to keep the collected data and export intervals down in order to decrease the amount of data sent.

## Security

The ruuvitag_app container uses the [ruuvitag-sensor](https://github.com/ttu/ruuvitag-sensor) library. Because of requirements imposed by ruuvitag-sensor, the ruuvitag_app container runs with privileged rights and network_mode: host. The other containers do not have these, but InfluxDB needs to expose its port so that ruuvitag_app can connect to it.

There are two exposed ports by the RuuviMon app, the port of the Grafana UI and the port of the InfluxDB interface. The user only needs to connect to the Grafana port, the InfluxDB port is exposed solely for the reason described above. Direct user access to it is not needed, RuuviMon auto-generates a password for the InfluxDB user by default that is used internally.

RuuviMon provides simple mechanisms for protecting the exposed ports at the host of Grafana and InfluxDB. The provided mechanisms are authentication and encrypted communication over HTTPS. HTTPS support is currently based on self-signed certificates automatically generated upon container startup. It provides encryption but does not provide protection against man-in-the-middle attacks, it is up to the user to verify that the certificate matches the self-signed one. Possibility to specify the certificates to use might be added later.

Beyond what is the described above on protecting exposed ports, no other security is provided. It is up to each user to protect anything else, including the host at which the software runs.
