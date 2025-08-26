/* Admin package */
CREATE OR replace package AdminPackage
AS
	PROCEDURE CreateUser(
		pLegalName Participants.LegalName%TYPE
	);

	PROCEDURE DeleteUser(
		pParticipantID Participants.ID%TYPE
	);
	
	PROCEDURE ChangeUserLimit(
		pParticipantID Participants.ID%TYPE,
		pProductID Products.ID%TYPE,
		pNewBuyLimit ParticipantAllowedProducts.BuyLimit%TYPE,
		pNewSellLimit ParticipantAllowedProducts.SellLimit%TYPE
	);
	
	PROCEDURE CreateContract(
		pProductID Contracts.ProductID%TYPE,
		pTradingStart Contracts.TradingStart%TYPE
	);
	
	PROCEDURE CloseContract(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE
	);
	
	PROCEDURE CreateProduct(
		pProductName Products.Name%TYPE
	);
END AdminPackage;


CREATE OR replace package body AdminPackage
AS
	/* Private procedure, only in body */
	PROCEDURE CalculatePnl(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE,
		pParticipantID Participants.ID%TYPE
	) AS 
		vSellProfit ProfitAndLoss.Value%TYPE;
		vBuyLoss ProfitAndLoss.Value%TYPE;
		vBuyPosition ProfitAndLoss.Value%TYPE;
		vSellPosition ProfitAndLoss.Value%TYPE;
	BEGIN
		SELECT nvl(sum(t.Quantity), 0), nvl(sum(t.Quantity * t.Price), 0)
		INTO vBuyPosition, vBuyLoss
		FROM Trades t
		INNER JOIN Orders o ON t.BuyOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;

		SELECT nvl(sum(t.Quantity), 0), nvl(sum(t.Quantity * t.Price), 0)
		INTO vSellPosition, vSellProfit
		FROM Trades t
		INNER JOIN Orders o ON t.SellOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;
				
		INSERT INTO ProfitAndLoss(ParticipantID, ContractID, Value)
		VALUES (pParticipantID, pContract, vSellProfit - vBuyLoss + (vBuyPosition - vSellPosition) * pSettlementPrice);
	END CalculatePnl;

	PROCEDURE CreateUser(
		pLegalName Participants.LegalName%TYPE
	) AS
	BEGIN
		INSERT INTO Participants(LegalName) VALUES (pLegalName);
	END CreateUser;

	PROCEDURE DeleteUser(
		pParticipantID Participants.ID%TYPE
	) AS
		vParticipantID Participants.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vParticipantID
			FROM Participants p WHERE p.ID = pParticipantID
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Participant not found: ' || pParticipantID);
		END;
		DELETE FROM Participants p WHERE p.ID = pParticipantID;
	END DeleteUser;

	PROCEDURE ChangeUserLimit(
		pParticipantID Participants.ID%TYPE,
		pProductID Products.ID%TYPE,
		pNewBuyLimit ParticipantAllowedProducts.BuyLimit%TYPE,
		pNewSellLimit ParticipantAllowedProducts.SellLimit%TYPE
	) AS
		vParticipantID Participants.ID%TYPE;
		vProductID Products.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vParticipantID
			FROM Participants p WHERE p.ID = pParticipantID
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Participant not found: ' || pParticipantID);
		END;
		BEGIN
			SELECT 1 INTO vProductID
			FROM Products p WHERE p.ID = pProductID
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20002, 'Product not found: ' || pProductID);
		END;
	
		IF pNewBuyLimit < 0 THEN 
			RAISE_APPLICATION_ERROR(-20003, 'Buy limit cannot be negative: ' || pNewBuyLimit);
		END IF;
		
		IF pNewSellLimit < 0 THEN 
			RAISE_APPLICATION_ERROR(-20004, 'Sell limit cannot be negative: ' || pNewSellLimit);
		END IF;

		MERGE INTO ParticipantAllowedProducts dest
		USING (
			SELECT pParticipantID AS ParticipantID, pProductID AS ProductID, pNewBuyLimit AS NewBuyLimit, pNewSellLimit AS NewSellLimit 
			FROM dual) src
		ON (dest.ParticipantID = src.ParticipantID AND dest.ProductID = src.ProductID)
		WHEN MATCHED THEN
			UPDATE SET dest.BuyLimit = src.NewBuyLimit, dest.SellLimit = src.NewSellLimit
		WHEN NOT MATCHED THEN
			INSERT (ParticipantId, ProductID, BuyLimit, SellLimit)
			VALUES (src.ParticipantID, src.ProductID, src.NewBuyLimit, src.NewSellLimit);
	END ChangeUserLimit;
		
	PROCEDURE CreateContract(
		pProductID Contracts.ProductID%TYPE,
		pTradingStart Contracts.TradingStart%TYPE
	) AS
		vProductID Products.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vProductID
			FROM Products p WHERE p.ID = pProductID
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20002, 'Product not found: ' || pProductID);
		END;
	
		INSERT INTO Contracts(ProductID, TradingStart, Expired)
		VALUES (pProductID, pTradingStart, 'N');
	END CreateContract;
	
	PROCEDURE CloseContract(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE
	) AS
		vContractID Contracts.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vContractID
			FROM Contracts c WHERE c.ID = pContract
			FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20005, 'Contract not found: ' || pContract);
		END;

		UPDATE Contracts
		SET Expired = 'Y'
		WHERE ID = pContract;
	
		UPDATE Orders
		SET Active = 'N'
		WHERE ContractID = pContract;
		
		FOR owner IN (
				SELECT DISTINCT o.OwnerID 
				FROM Trades t 
				INNER JOIN Orders o ON (t.BuyOrderID = o.ID OR t.SellOrderID = o.ID)
				WHERE ContractID = pContract
		) LOOP
			AdminPackage.CalculatePnl(pContract, pSettlementPrice, owner.OwnerID);
		END LOOP;
		
	END CloseContract;
			
	PROCEDURE CreateProduct(
		pProductName Products.Name%TYPE
	) AS 
	BEGIN 
		INSERT INTO Products(Name) VALUES (pProductName);
	END CreateProduct;
END AdminPackage;


	








