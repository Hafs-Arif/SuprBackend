-- Update constraint to allow service_provider role with flexible authentication
ALTER TABLE users
DROP CONSTRAINT email_for_non_riders;

ALTER TABLE users
ADD CONSTRAINT email_for_non_riders CHECK (
    role IN ('rider', 'driver', 'service_provider') OR 
    (email IS NOT NULL AND password IS NOT NULL)
);
