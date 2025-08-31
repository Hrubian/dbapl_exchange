
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
				VALUES (vBuyOrder.Price, vBuyOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3)));
				
				FETCH vBuyOrderCursor INTO vBuyOrder;
				FETCH vSellOrderCursor INTO vSellOrder;
			ELSIF vBuyOrder.Quantity < vSellOrder.Quantity THEN 
				/* Eat the buy order fully */
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vBuyOrderCursor;
			
				UPDATE Orders
				SET Quantity = vSellOrder.Quantity - vBuyOrder.Quantity
				WHERE CURRENT OF vSellOrderCursor;
				
				INSERT INTO Trades(Price, Quantity, BuyOrderID, SellOrderId, ExecutionTs)
				VALUES (vBuyOrder.Price, vBuyOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3)));
				
				vSellOrder.Quantity := vSellOrder.Quantity - vBuyOrder.Quantity;
				FETCH vBuyOrderCursor INTO vBuyOrder;
			ELSE /* vBuyOrder.Quantity > vSellOrder.Quantity */
				/* Eat the sell order fully */
				UPDATE Orders
				SET Quantity = vBuyOrder.Quantity - vSellOrder.Quantity
				WHERE CURRENT OF vBuyOrderCursor;
			
				UPDATE Orders
				SET Quantity = 0, Active = 'N'
				WHERE CURRENT OF vSellOrderCursor;
				
				INSERT INTO Trades(Price, Quantity, BuyOrderID, SellOrderId, ExecutionTs)
				VALUES (vBuyOrder.Price, vSellOrder.Quantity, vBuyOrder.ID, vSellOrder.ID, CAST(systimestamp AS timestamp(3)));

				vBuyOrder.Quantity := vBuyOrder.Quantity - vSellOrder.Quantity;
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
		vTradesVolume Trades.Quantity%TYPE;
		vOrdersVolume Orders.Quantity%TYPE;
		vUserLimit ParticipantAllowedProducts.BuyLimit%TYPE;
		vContract Contracts%ROWTYPE;
	BEGIN
		BEGIN
		SELECT * INTO vContract FROM Contracts WHERE ID = pContract;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20021, 'Contract not found');
		END;
		IF (vContract.Expired = 'Y' OR vContract.TradingStart > systimestamp) THEN
			RAISE_APPLICATION_ERROR(-20025, 'Contract not active for trading');
		END IF;
	
		IF (pSide = 'Buy') THEN
			SELECT nvl(sum(t.Quantity), 0)
			INTO vTradesVolume
			FROM Trades t
			INNER JOIN Orders o ON t.BuyOrderID = o.ID
			WHERE o.OwnerID = pOwner AND o.ContractID = pContract;
		
			BEGIN
				SELECT pap.BuyLimit
				INTO vUserLimit
				FROM ParticipantAllowedProducts pap
				INNER JOIN Contracts c ON c.ProductID = pap.ProductID
				WHERE c.ID = pContract AND pap.ParticipantID = pOwner;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20022, 'No user limit definition found');
			END;
		ELSE -- pSide = 'Sell'
			SELECT nvl(sum(t.Quantity), 0)
			INTO vTradesVolume
			FROM Trades t
			INNER JOIN Orders o ON t.SellOrderID = o.ID
			WHERE o.OwnerID = pOwner AND o.ContractID = pContract;
			
			BEGIN
				SELECT pap.SellLimit
				INTO vUserLimit
				FROM ParticipantAllowedProducts pap
				INNER JOIN Contracts c ON c.ProductID = pap.ProductID
				WHERE c.ID = pContract AND pap.ParticipantID = pOwner;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20022, 'No user limit definition found');
			END;
		END IF;
			
		SELECT nvl(sum(Quantity), 0)
		INTO vOrdersVolume
		FROM Orders
		WHERE OwnerID = pOwner AND ContractID = pContract AND Side = pSide AND Active = 'Y';
		
		IF (vTradesVolume + vOrdersVolume + pQuantity > vUserLimit) THEN 
			RAISE_APPLICATION_ERROR(-20023, 'The new order would exceed the user limits.');
		END IF;

		INSERT INTO Orders(Price, Quantity, Side, Active, CreationTs, OwnerID, ContractID)
		VALUES (pPrice, pQuantity, pSide, 'Y', CAST(systimestamp AS timestamp(3)), pOwner, pContract);
	
		LogMessage('New order created with price ' || pPrice ||', quantity ' || pQuantity || ', side ' || pSide || ', owner ' || pOwner || 'for contract ' || pContract);
		
		MatchOrders(pContract);
	END NewOrder;

	PROCEDURE ModifyOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	) AS 
		vContractID Orders.ContractID%TYPE;
		vOldQuantity Orders.Quantity%TYPE;
		vSide Orders.Side%TYPE;
		vTradesVolume Trades.Quantity%TYPE;
		vOrdersVolume Orders.Quantity%TYPE;
		vUserLimit ParticipantAllowedProducts.BuyLimit%TYPE;
	BEGIN
		BEGIN 
			SELECT ContractID, Quantity, Side
			INTO vContractID, vOldQuantity, vSide
			FROM Orders
			WHERE ID = pOrderID AND OwnerID = pOwner AND active = 'Y';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20011, 'No active order with the given orderID found for the user specified');
		END;

		IF (vSide = 'Buy') THEN
			SELECT nvl(sum(t.Quantity), 0)
			INTO vTradesVolume
			FROM Trades t
			INNER JOIN Orders o ON t.BuyOrderID = o.ID
			WHERE o.OwnerID = pOwner AND o.ContractID = vContractID;
		
			BEGIN
				SELECT pap.BuyLimit
				INTO vUserLimit
				FROM ParticipantAllowedProducts pap
				INNER JOIN Contracts c ON c.ProductID = pap.ProductID
				WHERE c.ID = vContractID AND pap.ParticipantID = pOwner;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20022, 'No user limit definition found');
			END;
		ELSE -- vSide = 'Sell'
			SELECT nvl(sum(t.Quantity), 0)
			INTO vTradesVolume
			FROM Trades t
			INNER JOIN Orders o ON t.SellOrderID = o.ID
			WHERE o.OwnerID = pOwner AND o.ContractID = vContractID;
			
			BEGIN
				SELECT pap.SellLimit
				INTO vUserLimit
				FROM ParticipantAllowedProducts pap
				INNER JOIN Contracts c ON c.ProductID = pap.ProductID
				WHERE c.ID = vContractID AND pap.ParticipantID = pOwner;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20022, 'No user limit definition found');
			END;
		END IF;
		
		SELECT nvl(sum(Quantity), 0)
		INTO vOrdersVolume
		FROM Orders
		WHERE OwnerID = pOwner AND ContractID = vContractID AND Side = vSide AND Active = 'Y';
		
		IF (vTradesVolume + vOrdersVolume + pQuantity - vOldQuantity > vUserLimit) THEN 
			RAISE_APPLICATION_ERROR(-20023, 'The modification would exceed the user limits.');
		END IF;
		
		UPDATE Orders
		SET Price = pPrice, Quantity = pQuantity
		WHERE ID = pOrderID;
		
		LogMessage('Order with ID ' || pOrderID || ' has new price ' || pPrice || ' and quantity ' || pQuantity);
	
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
	
		UPDATE Orders
		SET Active = 'N'
		WHERE ID = pOrderID;
		
		LogMessage('Order with ID ' || pOrderID || ' cancelled');
	END CancelOrder;
END OrdersPackage;







