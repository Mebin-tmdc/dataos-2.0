MODEL (
  name s3depot.device_08.audit_events,
  grain _id,
  cron '*/5 * * * *',
  kind FULL,
  description 'Cleaned CDC data with deduplication logic for devices',
  physical_properties (
    format = 'iceberg'
  ),
  columns (
    _id STRING,
    org_id STRING,
    subscription_id STRING,
    action STRING,
    entity_id STRING,
    entity_type STRING,
    description STRING,
    entity_name STRING,
    initiator_org_id STRING,
    initiator_id STRING,
    timestamp TIMESTAMP,
    initiator_type STRING,
    _nilus_load_id TIMESTAMP,
    _nilus_id STRING
  ),
  column_descriptions (
    _id = 'Unique audit event record identifier and model grain.',
    org_id = 'Organization identifier associated with the audit event.',
    subscription_id = 'Subscription identifier associated with the audit event.',
    action = 'Type of action performed (create, update, delete, etc.).',
    entity_id = 'Identifier of the entity affected by the action.',
    entity_type = 'Type of entity affected (DEVICE, USER, etc.).',
    description = 'Human-readable description of the audit event.',
    entity_name = 'Display name of the affected entity.',
    initiator_org_id = 'Organization identifier of the action initiator.',
    initiator_id = 'Identifier of the user or system that initiated the action.',
    timestamp = 'Timestamp when the audit event occurred.',
    initiator_type = 'Type of initiator (user, system, service, etc.).',
    _nilus_load_id = 'Ingestion load identifier assigned by Nilus.',
    _nilus_id = 'Ingestion record identifier assigned by Nilus.'
  ),
  column_tags (
    _id = ('identifier', 'primary_key', 'grain', 'audit'),
    org_id = ('identifier', 'organization', 'audit'),
    subscription_id = ('identifier', 'subscription', 'audit'),
    action = ('classification', 'audit', 'action'),
    entity_id = ('identifier', 'audit', 'entity'),
    entity_type = ('classification', 'audit', 'entity-type'),
    description = ('dimension', 'audit', 'description'),
    entity_name = ('dimension', 'audit', 'entity-name'),
    initiator_org_id = ('identifier', 'organization', 'initiator'),
    initiator_id = ('identifier', 'audit', 'initiator'),
    timestamp = ('timestamp', 'audit', 'event-time'),
    initiator_type = ('classification', 'audit', 'initiator-type'),
    _nilus_load_id = ('metadata', 'ingestion', 'load_id'),
    _nilus_id = ('metadata', 'ingestion', 'record_id')
  ),
  column_terms (
    _id = ('audit_events.record_id', 'identity.primary_key'),
    org_id = ('audit_events.organization_id', 'organization.identifier'),
    subscription_id = ('audit_events.subscription_id', 'subscription.identifier'),
    action = ('audit_events.action', 'audit.action_type'),
    entity_id = ('audit_events.entity_id', 'audit.entity_id'),
    entity_type = ('audit_events.entity_type', 'audit.entity_type'),
    description = ('audit_events.description', 'audit.description'),
    entity_name = ('audit_events.entity_name', 'audit.entity_name'),
    initiator_org_id = ('audit_events.initiator_org_id', 'audit.initiator_org_id'),
    initiator_id = ('audit_events.initiator_id', 'audit.initiator_id'),
    timestamp = ('audit_events.timestamp', 'audit.event_timestamp'),
    initiator_type = ('audit_events.initiator_type', 'audit.initiator_type'),
    _nilus_load_id = ('audit_events.load_id', 'ingestion.load_id'),
    _nilus_id = ('audit_events.nilus_id', 'ingestion.record_id')
  )
);



SELECT 
  _id,
  org_id,
  subscription_id,
  action,
  entity_id,
  entity_type,
  description,
  entity_name,
  initiator_org_id,
  initiator_id,
  to_timestamp(from_unixtime(cast(timestamp AS bigint) / 1000)) as timestamp,
  initiator_type,
  to_timestamp(from_unixtime(CAST(_nilus_load_id AS DOUBLE))) AS _nilus_load_id,
  _nilus_id
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY _id
            ORDER BY CAST(_nilus_load_id AS BIGINT) DESC
        ) AS rn
    FROM s3depot.demolake04.audit_event
)
WHERE rn = 1;
