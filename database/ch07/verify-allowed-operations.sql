\set ON_ERROR_STOP on
BEGIN;
DO $$
DECLARE test_id bigint; changed integer; observed_price numeric; observed_active boolean;
BEGIN
    INSERT INTO northstar.product (name, description, price)
    VALUES ('Database Verification Product', NULL, 1.2300)
    RETURNING product_id, price, active INTO test_id, observed_price, observed_active;
    IF observed_price <> 1.23 OR observed_active IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Price or active default differs from the contract';
    END IF;
    UPDATE northstar.product SET active = false WHERE product_id = test_id;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 THEN RAISE EXCEPTION 'Expected one updated row'; END IF;
    SELECT active INTO observed_active FROM northstar.product WHERE product_id = test_id;
    IF observed_active IS DISTINCT FROM false THEN RAISE EXCEPTION 'Update did not persist in transaction'; END IF;
    DELETE FROM northstar.product WHERE product_id = test_id;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 THEN RAISE EXCEPTION 'Expected one deleted row'; END IF;
    INSERT INTO northstar.product (name, description, price)
    VALUES (repeat(U&'\+01F600', 120), repeat('d', 1000), 0.01);
END $$;
ROLLBACK;
