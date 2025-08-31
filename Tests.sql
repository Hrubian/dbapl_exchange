
-- create some products
BEGIN
	AdminPackage.CreateProduct('Zinc'); -- ID 1
	AdminPackage.CreateProduct('Wood'); -- ID 2
	AdminPackage.CreateProduct('Gold'); -- ID 3
	AdminPackage.CreateProduct('Wheat'); -- ID 4
	AdminPackage.CreateProduct('Oil'); -- ID 5
END;

-- how does the product table look now?
SELECT * FROM Products;

-- should fail, cannot create a product with existing name
BEGIN
	AdminPackage.CreateProduct('Zinc');
END;

-- create some contracts
BEGIN
	AdminPackage.CreateContract(1, systimestamp); -- ID 1
	AdminPackage.CreateContract(1, systimestamp + INTERVAL '10' MINUTE); -- ID 2 (yet inactive)
	AdminPackage.CreateContract(3, systimestamp); -- ID 3
END;

-- how does the contracts table look now
SELECT * FROM Contracts;

-- add some market participants
BEGIN
	AdminPackage.CreateUser('Luciano Pavarotti'); -- ID 1
	AdminPackage.CreateUser('Renee Fleming'); -- ID 2
	AdminPackage.CreateUser('Jessye Norman'); -- ID 3
	AdminPackage.CreateUser('Dmitri Hvorostovsky'); -- ID 4
	AdminPackage.CreateUser('Maria Callas'); -- ID 5
END;

-- how does the participants table look now
SELECT * FROM Participants;

-- now assign to some of them some limits
BEGIN
	AdminPackage.ChangeUserLimit(1, 1, 100, 50); -- Pavarotti can trade zinc now
	AdminPackage.ChangeUserLimit(4, 1, 100, 100); -- Dmitri can also trade zinc
	AdminPackage.ChangeUserLimit(2, 1, 100, 200); -- Renee can also trade zinc
END;

-- how does the participant allowed products table look now 
SELECT * FROM ParticipantAllowedProducts;

-- should fail because pavarotti cannot trade gold (does not have defined limits)
BEGIN
	OrdersPackage.NewOrder(
		pPrice => 35,
		pQuantity => 5,
		pSide => 'Sell',
		pOwner => 1,
		pContract => 3
	);
END;
-- should fail because Pavarotti has limits to sell only 50
BEGIN
	OrdersPackage.NewOrder(
		pPrice => 23,
		pQuantity => 75,
		pSide => 'Sell',
		pOwner => 1,
		pContract => 1
	);
END;

-- no order was created
SELECT * FROM Orders;

-- should fail because the contract ID 2 is not yet active
BEGIN
	OrdersPackage.NewOrder(
		pPrice => 35,
		pQuantity => 5,
		pSide => 'Sell',
		pOwner => 1,
		pContract => 2 -- inactive contract
	);
END;

-- now Pavarotti creates two orders with quantity 10 and 10, selling zinc 
-- and Dmitri creates matching opposite-side order with quantity 15, 
-- which will match fully with the first order and partially with the second order.
-- The remaining quantity 5 of the Pavarotti's order will be then matched by new Renee's order.
BEGIN
	OrdersPackage.NewOrder( -- FIRST Pavarotti's order
		pPrice => 35,
		pQuantity => 10,
		pSide => 'Sell',
		pOwner => 1,
		pContract => 1
	);
	OrdersPackage.NewOrder( -- SECOND Pavarotti's order
		pPrice => 30,
		pQuantity => 10,
		pSide => 'Sell',
		pOwner => 1,
		pContract => 1
	);

	OrdersPackage.NewOrder( -- Dmitri's order
		pPrice => 40,
		pQuantity => 15,
		pSide => 'Buy',
		pOwner => 4,
		pContract => 1
	);
	
	OrdersPackage.NewOrder( -- Renee's order
		pPrice => 45,
		pQuantity => 5,
		pSide => 'Buy',
		pOwner => 2,
		pContract => 1
	);
END;

-- there should be no active order (use the view for that), because all of them were fully filled
SELECT * FROM ActiveOrders;

-- there should be three trades:
-- quantity 10, price 35 between Pavarotti and Dmitri
-- quantity 5, price 30 between Pavarotti and Dmitri
-- quantity 5, price 30 between Pavarotti and Renee
SELECT * FROM TradesWithParticipants;

-- now Renne creates an order, Dmitri creates non-matching opposite-side order.
-- Then Renne modifies it's order so that it partially matches Dmitri's order.
-- The rest of Renne's order will be cancelled.
BEGIN
	OrdersPackage.NewOrder( -- Renee's ORDER (ID 5)
		pPrice => 200,
		pQuantity => 1,
		pSide => 'Buy',
		pOwner => 2,
		pContract => 1
	);

	OrdersPackage.NewOrder( -- Dmitri's order
		pPrice => 205,
		pQuantity => 5,
		pSide => 'Sell',
		pOwner => 4,
		pContract => 1
	);
	
	OrdersPackage.ModifyOrder( -- Renee's modification
		pPrice => 206,
		pQuantity => 8,
		pOwner => 2,
		pOrderID => 5
	);
	-- now trades happen
	OrdersPackage.CancelOrder( -- Renee's cancellation OF the rest OF the order
		pOwner => 2,
		pOrderID => 5
	);
END;
-- there should be no active orders left
SELECT * FROM ActiveOrders;

-- there should be one more trade
-- quantity 5, price 205 between Renee and Dmitri
SELECT * FROM TradesWithParticipants;


-- now let us examine the positions of the market participants on the contract ID 1
SELECT 
	TradingStatisticsPackage.GetPosition(pParticipantID => 1, pContract => 1) Pavarotti,
	TradingStatisticsPackage.GetPosition(pParticipantID => 2, pContract => 1) Renee,
	TradingStatisticsPackage.GetPosition(pParticipantID => 4, pContract => 1) Dmitri
FROM dual;

-- next we create an order on a contract and then close that contract. 
-- the order should be deactivated.
-- we should also be able to see the profit and loss (PNL) reports
-- for all the members that participated on some trades.
BEGIN
	OrdersPackage.NewOrder( -- Renee's ORDER
		pPrice => 200,
		pQuantity => 1,
		pSide => 'Buy',
		pOwner => 2,
		pContract => 1
	);
END;

-- there should be just one active order (the one we just created)
SELECT * FROM ActiveOrders;

BEGIN
	AdminPackage.CloseContract(pContract => 1, pSettlementPrice => 50);
END;

-- now there should be no active order at all
SELECT * FROM ActiveOrders;

-- take a look at the PNL reports
SELECT 
	TradingStatisticsPackage.GetPNL(pParticipantID => 1, pProduct => 1) Pavarotti,
	TradingStatisticsPackage.GetPNL(pParticipantID => 2, pProduct => 1) Renee,
	TradingStatisticsPackage.GetPNL(pParticipantID => 4, pProduct => 1) Dmitri
FROM dual;

-- should fail because we cannot create an order for already inactive (expired) contract (ID 1)
BEGIN
	OrdersPackage.NewOrder(
		pPrice => 23,
		pQuantity => 10,
		pSide => 'Buy',
		pOwner => 2,
		pContract => 1
	);
END;

-- now if we remove Renee, there will still be his trades (for audit purposes)
-- but they will have their ID set to null.
BEGIN
	AdminPackage.DeleteUser(2);
END;

-- there should be null for some trades in the OrderIDs
SELECT * FROM Trades;













