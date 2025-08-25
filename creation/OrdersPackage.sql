
/* Order actions package */
CREATE OR replace package OrdersPackage
AS
	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pSide Orders.Side%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pContract Orders.ContractID%TYPE		
	);

	PROCEDURE ModifyOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
	
	PROCEDURE CancelOrder(
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
END OrdersPackage;

CREATE OR replace package body OrdersPackage
AS
	/* Private function, only in the body */
	PROCEDURE MatchOrders(
		pContract Orders.ContractID%TYPE
	) AS
		CURSOR vBuyOrderCursor IS 
			SELECT * FROM Orders 
			WHERE Side = 'Buy' AND ContractID = pContract AND Active = 'Y' 
			ORDER BY Price DESC, CreationTs ASC
			FOR UPDATE;
		CURSOR vSellOrderCursor IS 
			SELECT * FROM Orders 
			WHERE Side = 'Sell' AND ContractID = pContract AND Active = 'Y' 
			ORDER BY Price ASC, CreationTs ASC
			FOR UPDATE;
	
		vBuyOrder Orders%ROWTYPE;
		vSellOrder Orders%ROWTYPE;
	BEGIN
		OPEN vBuyOrderCursor;
		OPEN vSellOrderCursor;
		FETCH vBuyOrderCursor INTO vBuyOrder;
		FETCH vSellOrderCursor INTO vSellOrder;
		
		LOOP
			EXIT WHEN vBuyOrderCursor%NOTFOUND;
			EXIT WHEN vSellOrderCursor%NOTFOUND;
		
			IF vBuyOrder.Price < vSellOrder.Price THEN
				EXIT;
			END IF;
			
			IF vBuyOrder.Quantity = vSellOrder.Quantity THEN
				/* Exact match, eat both of them */
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vBuyOrderCursor;
			
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vSellOrderCursor;
				
				INSERT INTO Trades(Price, Quantity, BuyOrderID, SellOrderId, ExecutionTs)
				VALUES (vBuyOrder.Price, vBuyOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3))); /* TODO get the correct price from passive order */
				
				FETCH vBuyOrderCursor INTO vBuyOrder;
				FETCH vSellOrderCursor INTO vSellOrder;
			ELSIF vBuyOrder.Quantity < vSellOrder.Quantity THEN 
				/* Eat the buy order fully */
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vBuyOrderCursor;
			
				UPDATE Orders
				SET Quantity = Quantity - vBuyOrder.Quantity
				WHERE CURRENT OF vSellOrderCursor;
				
				INSERT INTO Trades(Price, Quantity, BuyOrderID, SellOrderId, ExecutionTs)
				VALUES (vBuyOrder.Price, vBuyOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3))); /* TODO get the correct price from passive order */
				
				FETCH vBuyOrderCursor INTO vBuyOrder;
			ELSE /* vBuyOrder.Quantity > vSellOrder.Quantity */
				/* Eat the sell order fully */
				UPDATE Orders
				SET Quantity = Quantity - vSellOrder.Quantity
				WHERE CURRENT OF vBuyOrderCursor;
			
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vSellOrderCursor;
				
				INSERT INTO Trades(Price, Quantity, BuyOrderID, SellOrderId, ExecutionTs)
				VALUES (vBuyOrder.Price, vSellOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3))); /* TODO get the correct price from passive order */

				FETCH vSellOrderCursor INTO vSellOrder;
			END IF;
		END LOOP;
		
		CLOSE vBuyOrderCursor;
		CLOSE vSellOrderCursor;
	END MatchOrders;

	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pSide Orders.Side%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pContract Orders.ContractID%TYPE		
	) AS 
	BEGIN
		/* TODO check user existence */
		/* TODO check contract existance and activity expiration and trading start */
		INSERT INTO Orders(Price, Quantity, Side, Active, CreationTs, OwnerID, ContractID)
		VALUES (pPrice, pQuantity, pSide, 'Y', CAST(systimestamp AS timestamp(3)), pOwner, pContract);
		
		MatchOrders(pContract);
	END NewOrder;

	PROCEDURE ModifyOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	) AS 
		vContractID Orders.ContractID%TYPE;
	BEGIN
		BEGIN 
			SELECT ContractID
			INTO vContractID
			FROM Orders
			WHERE ID = pOrderID AND OwnerID = pOwner AND active = 'Y'
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20011, 'No active order with the given orderID found for the user specified');
		END;

		UPDATE Orders
		SET Price = pPrice, Quantity = pQuantity
		WHERE ID = pOrderID;
	
		MatchOrders(vContractID);
	END ModifyOrder;
	
	PROCEDURE CancelOrder(
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	) AS
		vContractID Orders.ContractID%TYPE;
	BEGIN
		BEGIN 
			SELECT ContractID
			INTO vContractID
			FROM Orders
			WHERE ID = pOrderID AND OwnerID = pOwner AND active = 'Y'
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20011, 'No active order with the given orderID found for the user specified');
		END;
	
		DELETE FROM Orders
		WHERE ID = pOrderID;
	END CancelOrder;
END OrdersPackage;







