-- Rollback: revert to original constraint
ALTER TABLE users
DROP CONSTRAINT email_for_non_riders;

ALTER TABLE users
ADD CONSTRAINT email_for_non_riders CHECK (
    role IN ('rider', 'driver') OR 
    (email IS NOT NULL AND password IS NOT NULL)
);
