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
		pProduct Contracts.ProductID%TYPE,
		pTradingStart Contracts.TradingStart%TYPE,
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
	PROCEDURE CreateUser(
		pLegalName Participants.LegalName%TYPE
	) AS
	BEGIN
		INSERT INTO Participants(LegalName) VALUES (pLegalName);
	END CreateUser;

	PROCEDURE DeleteUser(
		pParticipantID Participants.ID%TYPE
	) AS
	BEGIN
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
		pTradingStart Contracts.TradingStart%TYPE,
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
	BEGIN
		/*
		 * TODO:
		 * - close contract
		 * - deactivate orders
		 * - calculate pnls
		 * */
		UPDATE Contracts
		SET Expired = 'Y'
		WHERE ID = pContract;
	
		UPDATE Orders
		SET Active = 'N'
		WHERE ContractID = pContract;
		
		FOR r IN (SELECT ) LOOP
			AdminPackage.CalculatePnl(pContract, pSettlementPrice, )
		END LOOP
		
	END CloseContract;
		
	/* Private procedure, only in body */
	PROCEDURE CalculatePnl(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE,
		pParticipant Participants.ID%TYPE
	) AS 
	BEGIN
		
	END CalculatePnl;
	
	PROCEDURE CreateProduct(
		pProductName Products.Name%TYPE
	) AS 
	BEGIN 
		INSERT INTO Products(Name) VALUES (pProductName);
	END CreateProduct;
END AdminPackage;


	