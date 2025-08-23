/* Trading statistics package */
CREATE OR replace package TradingStatisticsPackage
AS
	FUNCTION GetPosition(
		pParticipantID Participants.ID%TYPE,
		pContract Contracts.ID%TYPE
	);

	FUNCTION GetPNL(
		pParticipantID Participant.ID%TYPE,
		pProduct Products.ID%TYPE
	);
END TradingStatisticsPackage;


CREATE OR replace package body TradingStatisticsPackage
AS
	FUNCTION GetPostion(
		pParticipantID Participants.ID%TYPE,
		pContract Contracts.ID%TYPE
	) AS
		vBuyPosition Trades.Quantity%TYPE;
		vSellPosition Trades.Quantity%TYPE;
	BEGIN
		/*TODO check participant and contract existance*/
		SELECT sum(Quantity)
		INTO vBuyPosition
		FROM Trades t
		INNER JOIN Orders o ON t.BuyOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;

		SELECT sum(Quantity)
		INTO vBuyPosition
		FROM Trades t
		INNER JOIN Orders o ON t.SellOrderID = o.ID
		WHERE o.ContractID = pContract AND o.OwnerID = pParticipantID;
		
		RETURN vSellPosition - vBuyPosition;
	END GetPosition;

	FUNCTION GetPNL(
		pParticipantID Participant.ID%TYPE,
		pProduct Products.ID%TYPE
	) AS
	BEGIN
		RETURN SELECT sum(pnl.Value)
		FROM ProfitAndLoss pnl
		INNER JOIN Contracts ctr ON pnl.ContractID = ctr.ID
		WHERE ctr.ProductID = pProduct;
	END GetPNL;
END TradingStatisticsPackage;