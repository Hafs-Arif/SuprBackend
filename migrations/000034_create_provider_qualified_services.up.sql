-- Create provider_qualified_services junction table
CREATE TABLE IF NOT EXISTS provider_qualified_services (
    provider_id UUID NOT NULL,
    service_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    CONSTRAINT fk_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT pk_provider_service PRIMARY KEY (provider_id, service_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_pqs_provider ON provider_qualified_services(provider_id);
CREATE INDEX IF NOT EXISTS idx_pqs_service ON provider_qualified_services(service_id);
