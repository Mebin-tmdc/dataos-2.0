MODEL (
  name s3depot.device_08.battery,
  grain battery_id,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for devices',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    battery_id STRING,
    device_id STRING,
    battery_condition STRING,
    battery_cycle_count STRING,
    battery_design_capacity STRING,
    battery_firstused_date TIMESTAMP,
    battery_fullcharge_capacity STRING,
    battery_manufacture_date TIMESTAMP,
    battery_manufacture_name STRING,
    battery_remaining_capacity STRING,
    battery_serial_number STRING,
    battery_warranty_date TIMESTAMP,
    battery_warranty_status STRING,
    current_battery_capacity DOUBLE,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING
  ),
  column_descriptions (
    battery_id = 'Unique battery record identifier and model grain.',
    device_id = 'Business device identifier associated with the battery.',
    battery_condition = 'Current health condition of the battery (good, degraded, replace, etc.).',
    battery_cycle_count = 'Number of charge cycles the battery has completed.',
    battery_design_capacity = 'Design capacity of the battery in source units.',
    battery_firstused_date = 'Timestamp when the battery was first used.',
    battery_fullcharge_capacity = 'Full charge capacity of the battery in source units.',
    battery_manufacture_date = 'Timestamp when the battery was manufactured.',
    battery_manufacture_name = 'Manufacturer name of the battery.',
    battery_remaining_capacity = 'Remaining capacity of the battery in source units.',
    battery_serial_number = 'Serial number of the battery.',
    battery_warranty_date = 'Timestamp when battery warranty coverage ends.',
    battery_warranty_status = 'Warranty status of the battery.',
    current_battery_capacity = 'Derived ratio of full charge capacity to design capacity as a percentage.',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.'
  ),
  column_tags (
    battery_id = ('identifier', 'primary_key', 'grain', 'battery'),
    device_id = ('identifier', 'device', 'battery'),
    battery_condition = ('status', 'battery', 'health'),
    battery_cycle_count = ('measure', 'battery', 'cycle-count'),
    battery_design_capacity = ('measure', 'battery', 'design-capacity'),
    battery_firstused_date = ('timestamp', 'battery', 'first-used'),
    battery_fullcharge_capacity = ('measure', 'battery', 'fullcharge-capacity'),
    battery_manufacture_date = ('timestamp', 'battery', 'manufacture-date'),
    battery_manufacture_name = ('dimension', 'battery', 'manufacturer'),
    battery_remaining_capacity = ('measure', 'battery', 'remaining-capacity'),
    battery_serial_number = ('identifier', 'battery', 'serial-number'),
    battery_warranty_date = ('timestamp', 'battery', 'warranty-date'),
    battery_warranty_status = ('status', 'battery', 'warranty'),
    current_battery_capacity = ('measure', 'battery', 'current-capacity'),
    _nilus_load_id = ('metadata', 'ingestion', 'load_id'),
    _nilus_id = ('metadata', 'ingestion', 'record_id')
  ),
  column_terms (
    battery_id = ('battery.record_id', 'identity.primary_key'),
    device_id = ('battery.device_id', 'device.identifier'),
    battery_condition = ('battery.battery_condition', 'device_health.battery_state'),
    battery_cycle_count = ('battery.battery_cycle_count', 'battery.cycle_count'),
    battery_design_capacity = ('battery.battery_design_capacity', 'battery.design_capacity'),
    battery_firstused_date = ('battery.battery_firstused_date', 'battery.first_used_date'),
    battery_fullcharge_capacity = ('battery.battery_fullcharge_capacity', 'battery.fullcharge_capacity'),
    battery_manufacture_date = ('battery.battery_manufacture_date', 'battery.manufacture_date'),
    battery_manufacture_name = ('battery.battery_manufacture_name', 'battery.manufacturer'),
    battery_remaining_capacity = ('battery.battery_remaining_capacity', 'battery.remaining_capacity'),
    battery_serial_number = ('battery.battery_serial_number', 'identity.serial_number'),
    battery_warranty_date = ('battery.battery_warranty_date', 'battery.warranty_date'),
    battery_warranty_status = ('battery.battery_warranty_status', 'battery.warranty_status'),
    current_battery_capacity = ('battery.current_battery_capacity', 'battery.current_capacity'),
    _nilus_load_id = ('battery.load_id', 'ingestion.load_id'),
    _nilus_id = ('battery.nilus_id', 'ingestion.record_id')
  ),
  profiles (
    battery_id,
    device_id,
    battery_condition,
    battery_cycle_count,
    battery_design_capacity,
    battery_firstused_date,
    battery_fullcharge_capacity,
    battery_manufacture_date,
    battery_manufacture_name,
    battery_remaining_capacity,
    battery_serial_number,
    battery_warranty_date,
    battery_warranty_status,
    current_battery_capacity,
    _nilus_load_id,
    _nilus_id
  )
);


SELECT 
    battery_id,
    device_id,
    battery_condition,
    battery_cycle_count,
    battery_design_capacity,
    to_timestamp(from_unixtime(cast(battery_firstused_date AS bigint) / 100000)) as battery_firstused_date,
    battery_fullcharge_capacity,
    to_timestamp(from_unixtime(cast(battery_manufacture_date AS bigint) / 100000)) as battery_manufacture_date,
    battery_manufacture_name,
    battery_remaining_capacity,
    battery_serial_number,
    to_timestamp(from_unixtime(cast(battery_warranty_date AS bigint) / 100000)) as battery_warranty_date,
    battery_warranty_status,
    (battery_fullcharge_capacity * 100.0) / battery_design_capacity as current_battery_capacity,
    to_timestamp(from_unixtime(CAST(_nilus_load_id AS DOUBLE))) AS _nilus_load_id,
    _nilus_id
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY battery_id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.battery
)
WHERE rn = 1;

