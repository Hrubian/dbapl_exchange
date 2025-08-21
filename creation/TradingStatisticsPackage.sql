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
	BEGIN
		/*TODO check participant and contract existance*/
		SELECT sum(Quantity)
		FROM Trades
		WHERE 
	END GetPosition;
END TradingStatisticsPackage;