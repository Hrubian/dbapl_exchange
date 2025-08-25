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
	BEGIN
		/*TODO check participant and contract existance*/
		SELECT sum(t.Quantity)
		INTO vBuyPosition
		FROM Trades t
		INNER JOIN Orders o ON t.BuyOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;

		SELECT sum(t.Quantity)
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
	BEGIN
		SELECT sum(pnl.Value)
		INTO vPNL
		FROM ProfitAndLoss pnl
		INNER JOIN Contracts ctr ON pnl.ContractID = ctr.ID
		WHERE ctr.ProductID = pProduct AND pnl.ParticipantID = pParticipantID;
	
		RETURN vPNL;
	END GetPNL;
END TradingStatisticsPackage;