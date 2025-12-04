-- Order Status History - tracks all status changes for audit trail
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    
    -- Status change
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    
    -- Actor information
    changed_by UUID,
    changed_by_role VARCHAR(50),
    
    -- Additional context
    notes TEXT,
    metadata JSONB,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_order_status_history_order 
        FOREIGN KEY (order_id) REFERENCES service_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_status_history_user 
        FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_order_status_history_order ON order_status_history(order_id);
CREATE INDEX idx_order_status_history_timestamp ON order_status_history(created_at DESC);
CREATE INDEX idx_order_status_history_order_time ON order_status_history(order_id, created_at DESC);