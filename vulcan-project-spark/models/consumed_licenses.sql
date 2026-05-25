MODEL (
  name s3depot.device_08.consumed_licenses,
  grain _id,
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for products consumed licenses',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    _id STRING,
    subscription_id STRING,
    license_type_id STRING,
    billing_subscription_id STRING,
    created_date TIMESTAMP,
    status STRING,
    start_date TIMESTAMP,
    commitment_end_date TIMESTAMP,
    order_date TIMESTAMP,
    part_number STRING,
    organization_id STRING,
    entity_id STRING,
    entity_type STRING,
    is_automatic_assignment_enabled BOOLEAN,
    _part_number_old STRING,
    subscription STRING,
    _is_part_number_missing_migration STRING,
    effective_start_date TIMESTAMP,
    _nilus_load_id STRING,
    _nilus_id STRING,
    device_org_id STRING
  ),
  column_descriptions (
    _id = 'Unique consumed license record identifier and model grain.',
    subscription_id = 'Subscription identifier associated with the license.',
    license_type_id = 'License type identifier from the source system.',
    billing_subscription_id = 'Billing subscription identifier linked to the license.',
    created_date = 'Timestamp when the license record was created.',
    status = 'License status (ASSIGNED, NEW, UNASSIGNED, EXPIRED).',
    start_date = 'Timestamp when license coverage starts.',
    commitment_end_date = 'Timestamp when license commitment ends.',
    order_date = 'Timestamp when the license order was placed.',
    part_number = 'Product part number associated with the license.',
    organization_id = 'Organization identifier that owns the license.',
    entity_id = 'Identifier of the entity the license is assigned to.',
    entity_type = 'Type of entity the license is assigned to (DEVICE, USER, etc.).',
    is_automatic_assignment_enabled = 'Flag indicating whether automatic license assignment is enabled.',
    _part_number_old = 'Legacy part number retained from prior assignments.',
    subscription = 'Subscription name or descriptor associated with the license record.',
    _is_part_number_missing_migration = 'Flag indicating whether the part number was missing during migration.',
    effective_start_date = 'Timestamp when the license became effectively active.',
    _nilus_load_id = 'Internal load batch identifier from the Nilus ingestion pipeline.',
    _nilus_id = 'Internal unique record identifier assigned by the Nilus ingestion pipeline.',
    device_org_id = 'Organization-scoped device identifier when entity_type is DEVICE.'
  ),
  column_tags (
    _id = ('identifier', 'primary_key', 'grain', 'licensing'),
    subscription_id = ('identifier', 'subscription', 'licensing'),
    license_type_id = ('identifier', 'licensing', 'license-type'),
    billing_subscription_id = ('identifier', 'billing', 'licensing'),
    created_date = ('timestamp', 'licensing', 'created_at'),
    status = ('status', 'licensing', 'lifecycle'),
    start_date = ('timestamp', 'licensing', 'start'),
    commitment_end_date = ('timestamp', 'licensing', 'commitment-end'),
    order_date = ('timestamp', 'licensing', 'order-date'),
    part_number = ('identifier', 'licensing', 'part-number'),
    organization_id = ('identifier', 'organization', 'licensing'),
    entity_id = ('identifier', 'licensing', 'entity'),
    entity_type = ('classification', 'licensing', 'entity-type'),
    is_automatic_assignment_enabled = ('indicator', 'licensing', 'auto-assignment'),
    _part_number_old = ('identifier', 'licensing', 'legacy-part-number'),
    subscription = ('descriptor', 'licensing', 'subscription'),
    _is_part_number_missing_migration = ('indicator', 'licensing', 'migration'),
    effective_start_date = ('timestamp', 'licensing', 'effective-start'),
    _nilus_load_id = ('identifier', 'ingestion', 'nilus'),
    _nilus_id = ('identifier', 'ingestion', 'nilus'),
    device_org_id = ('identifier', 'device', 'organization-key')
  ),
  column_terms (
    _id = ('consumed_licenses.record_id', 'identity.primary_key'),
    subscription_id = ('consumed_licenses.subscription_id', 'subscription.identifier'),
    license_type_id = ('consumed_licenses.license_type_id', 'license.type_id'),
    billing_subscription_id = ('consumed_licenses.billing_subscription_id', 'billing.subscription_id'),
    created_date = ('consumed_licenses.created_date', 'record.created_at'),
    status = ('consumed_licenses.status', 'license.status'),
    entity_id = ('consumed_licenses.entity_id', 'license.entity_id'),
    entity_type = ('consumed_licenses.entity_type', 'license.entity_type'),
    is_automatic_assignment_enabled = ('consumed_licenses.is_automatic_assignment_enabled', 'license.auto_assignment'),
    _part_number_old = ('consumed_licenses.part_number_old', 'license.legacy_part_number'),
    subscription = ('consumed_licenses.subscription', 'subscription.descriptor'),
    _is_part_number_missing_migration = ('consumed_licenses.is_part_number_missing_migration', 'license.migration_flag'),
    effective_start_date = ('consumed_licenses.effective_start_date', 'license.effective_start_date'),
    _nilus_load_id = ('consumed_licenses.nilus_load_id', 'ingestion.load_id'),
    _nilus_id = ('consumed_licenses.nilus_id', 'ingestion.record_id'),
    device_org_id = ('consumed_licenses.device_org_id', 'device.organization_device_id')
  ),
  profiles (
    _id,
    subscription_id,
    license_type_id,
    billing_subscription_id,
    created_date,
    status,
    start_date,
    commitment_end_date,
    order_date,
    part_number,
    organization_id,
    entity_id,
    entity_type,
    is_automatic_assignment_enabled,
    _part_number_old,
    subscription,
    _is_part_number_missing_migration,
    effective_start_date,
    _nilus_load_id,
    _nilus_id,
    device_org_id
  )
);


-- CREATE OR REPLACE TEMP VIEW _temp_view_consumed_licenses_cdc
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/consumed_licenses_cdc.json',
--   'multiline' 'true'
-- );


-- CREATE OR REPLACE TEMP VIEW _temp_view_consumed_licenses_full
-- USING json
-- OPTIONS (
--   'path' 's3a://warehouse/lenovo/01-14-2026-14-32-42_files_list/consumed_licenses_full.json',
--   'multiline' 'true'
-- );

SELECT
    _id,
    subscription_id,
    license_type_id,
    billing_subscription_id,
    CAST(created_date AS TIMESTAMP)                              AS created_date,
    status,
    CAST(start_date AS TIMESTAMP)                                AS start_date,
    CAST(commitment_end_date AS TIMESTAMP)                       AS commitment_end_date,
    CAST(order_date AS TIMESTAMP)                                AS order_date,
    part_number,
    organization_id,
    entity_id,
    entity_type,
    is_automatic_assignment_enabled,
    _part_number_old,
    subscription,
    _is_part_number_missing_migration,
    CAST(effective_start_date AS TIMESTAMP)                      AS effective_start_date,
    _nilus_load_id,
    _nilus_id,
    CASE WHEN entity_type = 'DEVICE' THEN entity_id ELSE NULL END AS device_org_id
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY _id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.consumed_licenses
)
WHERE rn = 1
