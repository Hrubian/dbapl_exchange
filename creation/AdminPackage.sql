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
		pProduct Products.ID%TYPE,
		pNewBuyLimit ParticipantAllowedProducts.BuyLimit%TYPE.
		pNewSellLimit Participant AllowedProducts.SellLimit%TYPE
	);
	
	PROCEDURE CloseContract(
		pContract Contracts.ID%TYPE,
		pSettlementPrice ProfitAndLoss.Value%TYPE
	);
END AdminPackage;