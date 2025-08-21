
/* Order actions package */
CREATE OR replace package OrdersPackage
AS
	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
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
	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pSide Orders.Side%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pContract Orders.ContractID%TYPE		
	) AS 
	BEGIN
		/* TODO check user existence */
		/* TODO check contract existance and activity */
		INSERT INTO Orders(Price, Quantity, Side, Active, CreationTs, OwnerID, ContractID)
		VALUES (pPrice, pQuantity, pSide, 'Y', CAST(systimestamp AS timestamp(3), pOwner, pContract);
		
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
		
		LOOP
			FETCH vBuyOrderCursor INTO vBuyOrder;
			FETCH vSellOrderCursor INTO vSellOrder;
			EXIT WHEN vBuyOrderCursor%NOTFOUND;
			EXIT WHEN vSellOrderCursor%NOTFOUND;
		
			IF vBuyOrder.Price < vSellOrder.Price THEN
				EXIT;
			END IF;
			
			
		END LOOP
		
		
	END MatchOrders;
END OrdersPackage;







