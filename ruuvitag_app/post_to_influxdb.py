""" Receives data from Ruuvitag sensors and writes it to InfluxDB.

The following can be configured through environment variables:

# List of fields to write to DB
# Supported fields:
#
# humidity: Humidity in %
# temparature: Temperature in Celsius
# pressure: Athmospheric pressure in mbar
# acceleration: Acceleration in the 3D plane in mG
# acceleration_x: Acceleration in the X plane in mG
# acceleration_y: Acceleration in the Y plane in mG
# acceleration_z: Acceleration in the Z plane in mG
# tx_power: Transmission power in dBm
# battery: Battery voltage in mV
# movement_counter: Counter incremented by motion detection in accelerometer
# measurement_sequence_number: Measurement sequence number
RUUVIMON_FIELDS=temperature,pressure,humidity,battery

# How often to write a sample to the DB
# Depending on its setting Ruuvitag may send at different intervals
# varying from 1.2 to 6.4s. This option will skip intermediate data
# and only write the first data after the sample interval has passed.
# Set to 0 to write all data received.
RUUVIMON_SAMPLE_INTERVAL_SEC: 0

# Write only values that have changed to the DB in order to minimize data.
RUUVIMON_STORE_CHANGES_ONLY=true
"""

from influxdb import InfluxDBClient
from ruuvitag_sensor.ruuvi import RuuviTagSensor

import datetime
import logging
import os
import time
import urllib3

urllib3.disable_warnings()
logger = logging.getLogger(__name__)


class RuuviMon:
    """ Class for monitoring ruuvitags and writing their data to InfluxDB. """

    def __init__(self):
        opt_str = os.environ.get('RUUVIMON_STORE_CHANGES_ONLY', 'True')
        self._store_changes_only = opt_str.lower() in ['true', '1', 'y', 'yes']
        self._values_to_save = (os.environ.get(
            'RUUVIMON_FIELDS',
            'temperature,pressure,humidity,battery')
                                .split(','))
        self._last_values = {}

        self._sample_interval_sec = int(os.environ.get('RUUVIMON_SAMPLE_INTERVAL_SEC', '0'))
        self._last_sample_time = None

        self._db_name = 'tag_data'

        ssl_enabled_str = os.environ.get('INFLUXDB_HTTPS_ENABLED', 'True')
        ssl_enabled = ssl_enabled_str.lower() in ['true', '1', 'y', 'yes']
        influxdb_port = os.environ.get('INFLUXDB_HOST_PORT', 8086)
        influxdb_user = os.environ.get('INFLUXDB_USER', 'admin')

        logger.info('Connecting to InfluxDB: %s@localhost:%s, ssl=%s',
                    influxdb_user,
                    influxdb_port,
                    ssl_enabled)
        self._db_client = InfluxDBClient(host='localhost',
                                         port=influxdb_port,
                                         database=self._db_name,
                                         username=influxdb_user,
                                         password=os.environ.get('INFLUXDB_PASSWORD', ''),
                                         ssl=ssl_enabled,
                                         retries=0)

        databases = self._db_client.get_list_database()
        if self._db_name not in databases:
            logger.info('Initializing database: %s', self._db_name)
            self._db_client.create_database(self._db_name)
            self._db_client.switch_database(self._db_name)

        logger.info('RUUVIMON_FIELDS: %s', self._values_to_save)
        logger.info('RUUVIMON_SAMPLE_INTERVAL_SEC: %s', self._sample_interval_sec)
        logger.info('RUUVIMON_STORE_CHANGES_ONLY: %s', self._store_changes_only)

    def _write_to_influx(self, mac, fields):
        influx_data = [{
            'measurement': 'ruuvitag',
            'tags': {
                'mac': mac
            },
            'fields': fields
        }]

        logger.debug('Writing data to DB: %s', influx_data)
        self._db_client.write_points(influx_data)

    def _update_value(self, mac, field_name, field_value):
        if mac not in self._last_values:
            self._last_values[mac] = {}

        curr_value = self._last_values[mac].get(field_name)
        if not curr_value or curr_value != field_value:
            self._last_values[mac][field_name] = field_value
            logger.debug('Value changed: %s=%s', field_name, field_value)
            return True

        logger.debug('Value did not change: %s=%s', field_name, field_value)
        return False

    def _handle_new_data(self, mac, fields):
        values_to_db = {}

        for value in self._values_to_save:
            if self._update_value(mac, value, fields[value]) or not self._store_changes_only:
                values_to_db[value] = fields[value]

        if values_to_db:
            self._write_to_influx(mac, values_to_db)

    def monitor(self):
        logger.info('Starting monitoring...')
        while True:
            datas = RuuviTagSensor.get_data_for_sensors()
            logger.debug('New data from sensor: %s', datas)

            time_now = datetime.datetime.now()
            if self._last_sample_time:
                time_diff = time_now - self._last_sample_time
                if time_diff.total_seconds() < self._sample_interval_sec:
                    logger.debug('Sample interval %s secs not yet reached: %s',
                                 self._sample_interval_sec,
                                 time_diff.total_seconds())
                    continue

            for mac, fields in datas.items():
                self._handle_new_data(mac, fields)

            self._last_sample_time = time_now


if __name__ == '__main__':
    # Set up logging
    log_level = str(os.environ.get('RUUVIMON_APP_LOG_LEVEL', 'INFO'))
    handler = logging.StreamHandler()
    formatter = logging.Formatter(
        '%(asctime)s | %(name)s | %(levelname)s | %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(log_level)

    ruuvi_mon = RuuviMon()

    # Don't collect data in import mode
    if os.environ['RUUVIMON_MODE'] == 'import':
        while True:
            time.sleep(600)
    else:
        ruuvi_mon.monitor()
