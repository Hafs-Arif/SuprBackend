ALTER TABLE wallet_holds
    ALTER COLUMN reference_id TYPE varchar(50);

ALTER TABLE wallet_transactions
    ALTER COLUMN reference_id TYPE varchar(50);
