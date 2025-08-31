/* Trading statistics package */
CREATE OR replace package TradingStatisticsPackage
AS
	FUNCTION GetPosition(
		pParticipantID Participants.ID%TYPE,
		pContract Contracts.ID%TYPE
	) RETURN NUMBER;

	FUNCTION GetPNL(
		pParticipantID Participants.ID%TYPE,
		pProduct Products.ID%TYPE
	) RETURN ProfitAndLoss.Value%TYPE;
END TradingStatisticsPackage;


CREATE OR replace package body TradingStatisticsPackage
AS
	FUNCTION GetPosition(
		pParticipantID Participants.ID%TYPE,
		pContract Contracts.ID%TYPE
	) RETURN NUMBER AS
		vBuyPosition Trades.Quantity%TYPE;
		vSellPosition Trades.Quantity%TYPE;
		vParticipantID Participants.ID%TYPE;
		vContractID Contracts.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vParticipantID
			FROM Participants p WHERE p.ID = pParticipantID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Participant not found: ' || pParticipantID);
		END;
		BEGIN
			SELECT 1 INTO vContractID
			FROM Contracts c WHERE c.ID = pContract;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20005, 'Contract not found: ' || pContract);
		END;

		SELECT nvl(sum(t.Quantity), 0)
		INTO vBuyPosition
		FROM Trades t
		INNER JOIN Orders o ON t.BuyOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;

		SELECT nvl(sum(t.Quantity), 0)
		INTO vSellPosition
		FROM Trades t
		INNER JOIN Orders o ON t.SellOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;
		
		RETURN vSellPosition - vBuyPosition;
	END GetPosition;

	FUNCTION GetPNL(
		pParticipantID Participants.ID%TYPE,
		pProduct Products.ID%TYPE
	) RETURN ProfitAndLoss.Value%TYPE AS
		vPNL ProfitAndLoss.Value%TYPE;
		vParticipantID Participants.ID%TYPE;
		vProductID Products.ID%TYPE;
	BEGIN
		BEGIN
			SELECT 1 INTO vParticipantID
			FROM Participants p WHERE p.ID = pParticipantID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Participant not found: ' || pParticipantID);
		END;
		BEGIN
			SELECT 1 INTO vProductID
			FROM Products p WHERE p.ID = pProduct;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20002, 'Product not found: ' || pProduct);
		END;

		SELECT nvl(sum(pnl.Value), 0)
		INTO vPNL
		FROM ProfitAndLoss pnl
		INNER JOIN Contracts ctr ON pnl.ContractID = ctr.ID
		WHERE ctr.ProductID = pProduct AND pnl.ParticipantID = pParticipantID;
	
		RETURN vPNL;
	END GetPNL;
END TradingStatisticsPackage;
