-- Service Orders table for home service bookings
CREATE TABLE IF NOT EXISTS service_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Customer Information
    customer_id UUID NOT NULL,
    customer_info JSONB NOT NULL,
    
    -- Booking Information
    booking_info JSONB NOT NULL,
    
    -- Service Details
    category_slug VARCHAR(255) NOT NULL,
    selected_services JSONB NOT NULL,
    selected_addons JSONB,
    special_notes TEXT,
    
    -- Pricing
    services_total DECIMAL(10,2) NOT NULL,
    addons_total DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    platform_commission DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    
    -- Payment
    payment_info JSONB,
    wallet_hold_id UUID,
    
    -- Provider Assignment
    assigned_provider_id UUID,
    provider_accepted_at TIMESTAMP WITH TIME ZONE,
    provider_started_at TIMESTAMP WITH TIME ZONE,
    provider_completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Order Status
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    
    -- Cancellation
    cancellation_info JSONB,
    
    -- Ratings
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_review TEXT,
    customer_rated_at TIMESTAMP WITH TIME ZONE,
    
    provider_rating INTEGER CHECK (provider_rating >= 1 AND provider_rating <= 5),
    provider_review TEXT,
    provider_rated_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Foreign Keys
    CONSTRAINT fk_service_orders_customer 
        FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_service_orders_provider 
        FOREIGN KEY (assigned_provider_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_service_orders_customer_id ON service_orders(customer_id);
CREATE INDEX idx_service_orders_provider_id ON service_orders(assigned_provider_id);
CREATE INDEX idx_service_orders_status ON service_orders(status);
CREATE INDEX idx_service_orders_order_number ON service_orders(order_number);
CREATE INDEX idx_service_orders_category_slug ON service_orders(category_slug);
CREATE INDEX idx_service_orders_created_at ON service_orders(created_at DESC);
CREATE INDEX idx_service_orders_booking_date ON service_orders((booking_info->>'date'));

-- Composite index for provider order lookup
CREATE INDEX idx_service_orders_provider_status 
    ON service_orders(assigned_provider_id, status) 
    WHERE assigned_provider_id IS NOT NULL;

-- Index for pending orders in a category (for provider matching)
CREATE INDEX idx_service_orders_pending_category 
    ON service_orders(category_slug, created_at) 
    WHERE status IN ('pending', 'searching_provider');

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_service_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_service_orders_updated_at
    BEFORE UPDATE ON service_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_service_orders_updated_at();

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    year_part VARCHAR(4);
    sequence_num INTEGER;
BEGIN
    year_part := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    -- Get the next sequence number for this year
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(order_number FROM 'HS-' || year_part || '-(\d+)') AS INTEGER)
    ), 0) + 1
    INTO sequence_num
    FROM service_orders
    WHERE order_number LIKE 'HS-' || year_part || '-%';
    
    NEW.order_number := 'HS-' || year_part || '-' || LPAD(sequence_num::TEXT, 6, '0');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON service_orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION generate_order_number();