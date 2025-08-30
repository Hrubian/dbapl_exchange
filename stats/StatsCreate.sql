/* stats for the whole schema */
BEGIN
	dbms_stats.gather_schema_stats(USER);
END;

/* products stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'products', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'PRODUCTS';

/* contracts stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'contracts', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'CONTRACTS';

/* participants stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'participants', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'PARTICIPANTS';

/* participant allowed products stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'participantAllowedProducts', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'PARTICIPANTALLOWEDPRODUCTS';

/* orders stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'orders', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'ORDERS';

/* trades stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'trades', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'TRADES';

/* profit and loss stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'profitAndLoss', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'PROFITANDLOSS';

/* audit log stats */
BEGIN
	dbms_stats.gather_table_stats(USER, 'auditLog', cascade => TRUE);
END;

SELECT column_name, nullable, num_distinct, num_nulls, density, histogram
FROM ALL_TAB_COLUMNS
WHERE table_name = 'AUDITLOG';