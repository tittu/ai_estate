```sql
CREATE TABLE tenant (
    tenant_id       UUID PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    status          VARCHAR(50) NOT NULL,
    created_at      TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP NOT NULL
);
```

### `business_unit`

```sql
CREATE TABLE business_unit (
    business_unit_id UUID PRIMARY KEY,
    tenant_id        UUID NOT NULL REFERENCES tenant(tenant_id),
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    created_at       TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP NOT NULL
);
```

### `team`

```sql
CREATE TABLE team (
    team_id          UUID PRIMARY KEY,
    business_unit_id UUID REFERENCES business_unit(business_unit_id),
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    created_at       TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP NOT NULL
);
```

CREATE TABLE application (
    application_id   UUID PRIMARY KEY,
    tenant_id        UUID NOT NULL REFERENCES tenant(tenant_id),
    team_id          UUID REFERENCES team(team_id),

    name             VARCHAR(255) NOT NULL,
    description      TEXT,

    application_type VARCHAR(100),
    criticality      VARCHAR(50),

    lifecycle_status VARCHAR(50),

    repository_url   TEXT,

    created_at       TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP NOT NULL
);
```
CREATE TABLE environment (
    environment_id UUID PRIMARY KEY,
    application_id UUID NOT NULL REFERENCES application(application_id),

    name           VARCHAR(50) NOT NULL,
    -- DEV / QA / STAGING / PROD

    cluster_name   VARCHAR(255),
    namespace      VARCHAR(255),

    created_at     TIMESTAMP NOT NULL,
    updated_at     TIMESTAMP NOT NULL
);

CREATE TABLE asset (
    asset_id        UUID PRIMARY KEY,

    tenant_id       UUID NOT NULL REFERENCES tenant(tenant_id),

    asset_type      VARCHAR(50) NOT NULL,
    -- AGENT
    -- WORKFLOW
    -- TOOL
    -- MCP_SERVER
    -- MCP_TOOL
    -- MODEL
    -- VECTOR_STORE
    -- KNOWLEDGE_SOURCE
    -- PROMPT
    -- RERANKER

    name            VARCHAR(255) NOT NULL,
    description     TEXT,

    provider        VARCHAR(255),

    lifecycle_status VARCHAR(50),

    environment_id  UUID REFERENCES environment(environment_id),

    owner_team_id   UUID REFERENCES team(team_id),

    metadata        JSONB,

    created_at      TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP NOT NULL
);

CREATE TABLE model (
    model_id             UUID PRIMARY KEY,
    asset_id             UUID UNIQUE NOT NULL REFERENCES asset(asset_id),

    model_type           VARCHAR(50) NOT NULL,
    -- LLM
    -- EMBEDDING
    -- RERANKER
    -- VISION
    -- MULTIMODAL

    provider             VARCHAR(255),

    model_name           VARCHAR(255),

    model_version        VARCHAR(100),

    context_window       INTEGER,

    input_price          NUMERIC(18,8),
    output_price         NUMERIC(18,8),

    currency             VARCHAR(10),

    release_date         DATE,
    deprecation_date     DATE,
    retirement_date      DATE,

    status               VARCHAR(50),

    metadata             JSONB,

    created_at           TIMESTAMP NOT NULL,
    updated_at           TIMESTAMP NOT NULL
);

CREATE TABLE technology (
    technology_id    UUID PRIMARY KEY,

    name             VARCHAR(255) NOT NULL,
    category         VARCHAR(100),
    -- FRAMEWORK
    -- DATABASE
    -- LANGUAGE
    -- LIBRARY
    -- INFRASTRUCTURE

    vendor           VARCHAR(255),

    description      TEXT,

    created_at       TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP NOT NULL
);

CREATE TABLE technology_version (
    technology_version_id UUID PRIMARY KEY,

    technology_id         UUID NOT NULL
                           REFERENCES technology(technology_id),

    version               VARCHAR(100),

    release_date          DATE,
    end_of_support        DATE,
    end_of_life           DATE,

    risk_level            VARCHAR(50),

    created_at            TIMESTAMP NOT NULL,
    updated_at            TIMESTAMP NOT NULL
);

CREATE TABLE asset_relationship (
    relationship_id UUID PRIMARY KEY,

    source_asset_id UUID NOT NULL REFERENCES asset(asset_id),
    target_asset_id UUID NOT NULL REFERENCES asset(asset_id),

    relationship_type VARCHAR(100) NOT NULL,

    environment_id UUID REFERENCES environment(environment_id),

    valid_from TIMESTAMP,
    valid_to   TIMESTAMP,

    metadata JSONB,

    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE ai_request (
    request_id       UUID PRIMARY KEY,

    tenant_id        UUID NOT NULL,

    application_id   UUID,
    environment_id   UUID,

    external_request_id VARCHAR(255),

    request_type     VARCHAR(100),

    user_id_hash     VARCHAR(255),

    started_at       TIMESTAMP NOT NULL,
    completed_at     TIMESTAMP,

    status           VARCHAR(50),

    total_latency_ms BIGINT,

    total_cost       NUMERIC(18,8),

    trace_id         UUID,

    metadata         JSONB
);

CREATE TABLE ai_trace (
    trace_id        UUID PRIMARY KEY,

    request_id      UUID NOT NULL,

    root_span_id    UUID,

    started_at      TIMESTAMP NOT NULL,
    completed_at    TIMESTAMP,

    status          VARCHAR(50),

    metadata        JSONB
);

CREATE TABLE ai_span (
    span_id          UUID PRIMARY KEY,

    trace_id         UUID NOT NULL,

    parent_span_id   UUID,

    application_id   UUID,

    asset_id         UUID,

    span_type        VARCHAR(50),

    -- AGENT
    -- LLM
    -- EMBEDDING
    -- RERANKER
    -- TOOL
    -- MCP
    -- RETRIEVAL

    started_at       TIMESTAMP NOT NULL,
    completed_at     TIMESTAMP,

    latency_ms       BIGINT,

    status           VARCHAR(50),

    metadata         JSONB
);

CREATE TABLE llm_invocation (
    span_id              UUID PRIMARY KEY REFERENCES ai_span(span_id),

    model_id              UUID NOT NULL REFERENCES model(model_id),

    provider_request_id   VARCHAR(255),

    input_tokens          INTEGER,
    output_tokens         INTEGER,
    total_tokens          INTEGER,

    cached_tokens         INTEGER,

    temperature           NUMERIC(5,4),

    input_cost            NUMERIC(18,8),
    output_cost           NUMERIC(18,8),
    total_cost            NUMERIC(18,8),

    finish_reason         VARCHAR(100),

    metadata              JSONB
);

CREATE TABLE embedding_invocation (
    span_id          UUID PRIMARY KEY REFERENCES ai_span(span_id),

    model_id         UUID NOT NULL REFERENCES model(model_id),

    input_count      INTEGER,

    input_tokens     INTEGER,

    dimensions       INTEGER,

    total_cost       NUMERIC(18,8),

    metadata         JSONB
);


CREATE TABLE tool_invocation (
    span_id          UUID PRIMARY KEY REFERENCES ai_span(span_id),

    tool_asset_id    UUID NOT NULL REFERENCES asset(asset_id),

    operation_name   VARCHAR(255),

    request_size     INTEGER,
    response_size    INTEGER,

    status_code      INTEGER,

    total_cost       NUMERIC(18,8),

    metadata         JSONB
);

CREATE TABLE retrieval_invocation (
    span_id              UUID PRIMARY KEY REFERENCES ai_span(span_id),

    vector_store_asset_id UUID REFERENCES asset(asset_id),

    query_count           INTEGER,

    top_k                 INTEGER,

    result_count          INTEGER,

    retrieval_latency_ms  BIGINT,

    metadata              JSONB
);

CREATE TABLE policy (
    policy_id       UUID PRIMARY KEY,

    tenant_id       UUID NOT NULL,

    name            VARCHAR(255),

    policy_type     VARCHAR(100),

    description     TEXT,

    severity        VARCHAR(50),

    rule_definition JSONB,

    status          VARCHAR(50),

    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);

CREATE TABLE policy_violation (
    violation_id    UUID PRIMARY KEY,

    policy_id       UUID REFERENCES policy(policy_id),

    asset_id        UUID REFERENCES asset(asset_id),

    request_id      UUID REFERENCES ai_request(request_id),

    detected_at     TIMESTAMP,

    severity        VARCHAR(50),

    status          VARCHAR(50),

    details         JSONB
);

CREATE TABLE asset_risk (
    risk_id         UUID PRIMARY KEY,

    asset_id        UUID NOT NULL REFERENCES asset(asset_id),

    risk_type       VARCHAR(100),

    severity        VARCHAR(50),

    score            NUMERIC(10,4),

    reason           TEXT,

    detected_at      TIMESTAMP,

    resolved_at      TIMESTAMP,

    metadata         JSONB
);

CREATE TABLE asset_owner (
    asset_id        UUID REFERENCES asset(asset_id),

    team_id         UUID REFERENCES team(team_id),

    owner_type      VARCHAR(50),

    is_primary      BOOLEAN,

    assigned_at     TIMESTAMP,

    PRIMARY KEY(asset_id, team_id)
);

CREATE TABLE asset_snapshot (
    snapshot_id     UUID PRIMARY KEY,

    asset_id        UUID NOT NULL REFERENCES asset(asset_id),

    version         BIGINT NOT NULL,

    snapshot_time   TIMESTAMP NOT NULL,

    status          VARCHAR(50),

    configuration   JSONB,

    metadata        JSONB
);

CREATE TABLE collector (
    collector_id       UUID PRIMARY KEY,
    tenant_id          UUID NOT NULL,
    name               VARCHAR(255) NOT NULL,

    collector_type     VARCHAR(100),
    version            VARCHAR(50),

    environment        VARCHAR(100),

    status             VARCHAR(50),

    last_heartbeat_at  TIMESTAMP,

    created_at         TIMESTAMP NOT NULL,
    updated_at         TIMESTAMP NOT NULL
);

CREATE TABLE asset_evidence (
    evidence_id        UUID PRIMARY KEY,

    asset_id           UUID NOT NULL,

    collector_id       UUID REFERENCES collector(collector_id),

    evidence_type      VARCHAR(100),

    source             VARCHAR(255),

    source_identifier  VARCHAR(500),

    observed_at        TIMESTAMP NOT NULL,

    confidence          NUMERIC(5,4),

    evidence_data      JSONB
);