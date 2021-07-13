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
import os
import time


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
        self._db_client = InfluxDBClient(host='localhost',
                                         port=os.environ.get('INFLUXDB_HOST_PORT', 8086),
                                         database=self._db_name,
                                         username=os.environ.get('INFLUXDB_USER', 'admin'),
                                         password=os.environ.get('INFLUXDB_PASSWORD', ''),
                                         retries=0)

        databases = self._db_client.get_list_database()
        if self._db_name not in databases:
            self._db_client.create_database(self._db_name)
            self._db_client.switch_database(self._db_name)

    def _write_to_influx(self, mac, fields):
        influx_data = [{
            'measurement': 'ruuvitag',
            'tags': {
                'mac': mac
            },
            'fields': fields
        }]

        print('Data to Influx: ', influx_data)
        self._db_client.write_points(influx_data)

    def _update_value(self, mac, field_name, field_value):
        if mac not in self._last_values:
            self._last_values[mac] = {}

        curr_value = self._last_values[mac].get(field_name)
        if not curr_value or curr_value != field_value:
            self._last_values[mac][field_name] = field_value
            print('Value changed: ', field_name, field_value)
            return True

        print('Value did not change: ', field_name, field_value)
        return False

    def _handle_new_data(self, mac, fields):
        values_to_db = {}

        for value in self._values_to_save:
            if self._update_value(mac, value, fields[value]) or not self._store_changes_only:
                values_to_db[value] = fields[value]

        if values_to_db:
            self._write_to_influx(mac, values_to_db)

    def monitor(self):
        while True:
            datas = RuuviTagSensor.get_data_for_sensors()
            print('New data: ', datas)

            time_now = datetime.datetime.now()
            if self._last_sample_time:
                time_diff = time_now - self._last_sample_time
                if time_diff.total_seconds() < self._sample_interval_sec:
                    print('Not yet time for a new sample: ', time_diff.total_seconds())
                    continue

            for mac, fields in datas.items():
                self._handle_new_data(mac, fields)

            self._last_sample_time = time_now


if __name__ == '__main__':
    ruuvi_mon = RuuviMon()

    # Don't collect data in import mode
    if os.environ['RUUVIMON_MODE'] == 'import':
        while True:
            time.sleep(600)
    else:
        ruuvi_mon.monitor()
