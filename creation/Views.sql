/* Views */

/* View of all best prices (also called l1-data) for all currently active contracts */
CREATE OR replace VIEW l1
AS
	SELECT ContractID, min(Price) AS BestPrice, Side
	FROM Orders 
	WHERE Side = 'BUY'
	GROUP BY ContractID, Side
	UNION
	SELECT ContractID, max(Price) AS BestPrice, Side 
	FROM Orders
	WHERE Side = 'SELL'
	GROUP BY ContractID, Side;

/* View all active orders */
CREATE OR REPLACE VIEW ActiveOrders
AS
	SELECT * FROM Orders
	WHERE Active = 'Y';

/* View of all market participants that can trade anything (have at least some non-zero limits) */
CREATE OR replace VIEW ActiveParticipants
AS
	SELECT p.LegalName, count(pap.ProductID) AS AllowedProducts
	FROM Participants p
		INNER JOIN (ParticipantAllowedProducts pap
			INNER JOIN Products prod 
				ON prod.ID = pap.ProductID)
		ON pap.ParticipantID = p.ID
	WHERE pap.BuyLimit > 0 OR pap.SellLimit > 0
	GROUP BY p.LegalName;

/* View of total traded volume across all products */
CREATE OR replace VIEW UsersTradedVolume
AS
	SELECT prod.Name ProductName, sum(tr.Quantity) TradedVolume
	FROM Trades tr
		INNER JOIN (Orders ord
			INNER JOIN (Contracts con
				INNER JOIN Products prod
					ON prod.ID = con.ProductID)
				ON ord.ContractID = con.ID)
			ON (tr.BuyOrderID = ord.ID OR tr.SellOrderID = ord.ID)
	GROUP BY prod.ID, prod.Name;

CREATE OR REPLACE VIEW TradesWithParticipants
AS
	SELECT t.Quantity Quantity, t.Price Price, bp.LegalName Buyer, sp.LegalName Seller 
		FROM Trades t
		INNER JOIN Orders bo ON t.BuyOrderID = bo.ID
		INNER JOIN Orders so ON t.SellOrderID = so.ID
		INNER JOIN Participant bp ON bp.ID = bo.OwnerID
		INNER join Participant sp ON sp.ID = so.OwnerID;