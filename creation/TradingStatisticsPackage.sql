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