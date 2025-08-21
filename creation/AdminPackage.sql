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
	
	PROCEDURE CloseContract(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE
	) AS
	BEGIN
		NULL;
	END CloseContract;
	
	PROCEDURE CreateProduct(
		pProductName Products.Name%TYPE
	) AS 
	BEGIN 
		INSERT INTO Products(Name) VALUES (pProductName);
	END CreateProduct;
END AdminPackage;
	