MODEL (
  name s3depot.device_mithun.devices,
  grain id,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for devices',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    id STRING,
    device_id STRING,
    org_id STRING,
    serial_number STRING,
    model_type STRING,
    family STRING,
    manufacturer STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    is_active BOOLEAN,
    category STRING,
    model_name STRING,
    trust_anchor STRING,
    platform STRING,
    org_device_id STRING,
    subscription_id STRING,
    name STRING,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING,
    registration_type STRING
  ),
  column_descriptions (
    id = 'Unique device record identifier and model grain.',
    device_id = 'Business device identifier from the source system.',
    org_id = 'Organization identifier that owns the device.',
    serial_number = 'Manufacturer-issued serial number of the device.',
    model_type = 'Model type classification of the device.',
    family = 'Product family the device belongs to.',
    manufacturer = 'Manufacturer of the device.',
    created_at = 'Timestamp when the device record was created.',
    updated_at = 'Timestamp when the device record was last updated.',
    is_active = 'Flag indicating whether the device is currently active.',
    category = 'Normalized device category classification.',
    model_name = 'Display model name of the device.',
    trust_anchor = 'Trust anchor identifier used for device attestation.',
    platform = 'Platform identifier the device runs on.',
    org_device_id = 'Organization-scoped device identifier alias.',
    subscription_id = 'Subscription identifier associated with the device.',
    name = 'Display name of the device.',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.',
    registration_type = 'Registration type used to onboard the device.'
  ),
  column_tags (
    id = ('identifier', 'primary_key', 'grain', 'devices'),
    device_id = ('identifier', 'device', 'business-key'),
    org_id = ('identifier', 'organization', 'devices'),
    serial_number = ('identifier', 'device', 'serial-number'),
    model_type = ('classification', 'device', 'model-type'),
    family = ('classification', 'device', 'family'),
    manufacturer = ('dimension', 'device', 'manufacturer'),
    created_at = ('timestamp', 'devices', 'created_at'),
    updated_at = ('timestamp', 'devices', 'updated_at'),
    is_active = ('indicator', 'device', 'active'),
    category = ('classification', 'device', 'category'),
    model_name = ('dimension', 'device', 'model-name'),
    trust_anchor = ('identifier', 'device', 'trust-anchor'),
    platform = ('classification', 'device', 'platform'),
    org_device_id = ('identifier', 'device', 'org-device-id'),
    subscription_id = ('identifier', 'device', 'subscription'),
    name = ('dimension', 'device', 'display-name'),
    _nilus_load_id = ('metadata', 'ingestion', 'load_id'),
    _nilus_id = ('metadata', 'ingestion', 'record_id'),
    registration_type = ('classification', 'device', 'registration-type')
  ),
  column_terms (
    id = ('devices.record_id', 'identity.primary_key'),
    device_id = ('devices.device_id', 'device.identifier'),
    org_id = ('devices.organization_id', 'organization.identifier'),
    serial_number = ('devices.serial_number', 'identity.serial_number'),
    model_type = ('devices.model_type', 'device.model_type'),
    family = ('devices.family', 'device.family'),
    manufacturer = ('devices.manufacturer', 'device.manufacturer'),
    created_at = ('devices.created_at', 'record.created_at'),
    updated_at = ('devices.updated_at', 'record.updated_at'),
    is_active = ('devices.is_active', 'device.is_active'),
    category = ('devices.category', 'device.category'),
    model_name = ('devices.model_name', 'device.model_name'),
    trust_anchor = ('devices.trust_anchor', 'device.trust_anchor'),
    platform = ('devices.platform', 'device.platform'),
    org_device_id = ('devices.org_device_id', 'device.org_device_id'),
    subscription_id = ('devices.subscription_id', 'subscription.identifier'),
    name = ('devices.name', 'device.display_name'),
    _nilus_load_id = ('devices.load_id', 'ingestion.load_id'),
    _nilus_id = ('devices.nilus_id', 'ingestion.record_id'),
    registration_type = ('devices.registration_type', 'device.registration_type')
  )
);



SELECT
    id,
    device_id,
    org_id,
    serial_number,
    model_type,
    family,
    manufacturer,
    cast(created_at AS timestamp)                              AS created_at,
    cast(updated_at AS timestamp)                              AS updated_at,
    is_active,
    category,
    model_name,
    trust_anchor,
    platform,
    org_device_id,
    subscription_id,
    name,
    to_timestamp(from_unixtime(CAST(_nilus_load_id AS DOUBLE))) AS _nilus_load_id,
    _nilus_id,
    registration_type
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.devices
)
WHERE rn = 1;
