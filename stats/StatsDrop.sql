BEGIN
	dbms_stats.delete_table_stats(USER, 'products');
	dbms_stats.delete_table_stats(USER, 'contracts');
	dbms_stats.delete_table_stats(USER, 'participants');
	dbms_stats.delete_table_stats(USER, 'participantAllowedProducts');
	dbms_stats.delete_table_stats(USER, 'orders');
	dbms_stats.delete_table_stats(USER, 'trades');
	dbms_stats.delete_table_stats(USER, 'profitAndLoss');
	dbms_stats.delete_table_stats(USER, 'auditLog');
END;