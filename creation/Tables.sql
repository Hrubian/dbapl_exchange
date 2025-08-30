/*
 * TODO description of the tables
 */

CREATE TABLE Products(
	ID numeric(15)
		CONSTRAINT Products_PK PRIMARY KEY,
	Name CHARACTER varying(30) NOT NULL
		CONSTRAINT Products_Name_Unique unique
);

CREATE TABLE Contracts(
	ID numeric(15)
		CONSTRAINT Contracts_PK PRIMARY KEY,
	ProductID numeric(15) NOT NULL
		CONSTRAINT Contracts_ProductID_FK REFERENCES Products(ID),
	TradingStart timestamp(3) NOT NULL,
	Expired char(1) DEFAULT 'N' NOT NULL
		CONSTRAINT Contracts_Expired_Bounds check(Expired IN ('Y', 'N'))
);

CREATE TABLE Participants(
	ID numeric(15)
		CONSTRAINT Participants_PK PRIMARY KEY,
	LegalName CHARACTER varying(100 char) NOT NULL
		CONSTRAINT Participants_LegalName_Unique unique
);

CREATE TABLE ParticipantAllowedProducts(
	ParticipantID numeric(15) NOT NULL
		CONSTRAINT ParticipantAllowedProducts_ParticipantID_FK REFERENCES Participants(ID) ON DELETE CASCADE,
	ProductID NUMERIC(15) NOT NULL
		CONSTRAINT ParticipantAllowedProducts_ProductID_FK REFERENCES Products(ID),
	BuyLimit NUMERIC(6, 2) NOT NULL
		CONSTRAINT ParticipantAllowedProducts_BuyLimit_Nonnegative CHECK(BuyLimit >= 0),
	SellLimit NUMERIC(6, 2) NOT NULL
		CONSTRAINT ParticipantAllowedProducts_SellLimit_Nonnegative CHECK(SellLimit >= 0),
	CONSTRAINT ParticipantAllowedProducts_PK PRIMARY key(ParticipantID, ProductID)
);

CREATE TABLE Orders(
	ID numeric(15)
		CONSTRAINT Orders_PK PRIMARY KEY,
	Price numeric(6, 2) NOT NULL,
	Quantity numeric(6, 1)  NOT NULL
		CONSTRAINT Order_Quantity_Positive check(Quantity > 0),
	Side varchar(4) NOT NULL
		CONSTRAINT Order_Side_Bounds CHECK(Side IN ('Buy', 'Sell')),
	Active char(1) DEFAULT 'Y' NOT null
		CONSTRAINT Order_Active_Bounds check(Active IN ('Y', 'N')),
	CreationTs timestamp(3) NOT NULL,
	OwnerID numeric(15) NOT NULL
		CONSTRAINT Order_OwnerID_FK REFERENCES Participants(ID) ON DELETE CASCADE,
	ContractID numeric(15) NOT NULL
		CONSTRAINT Order_ContractID_FK REFERENCES Contracts(ID)
);

CREATE TABLE Trades(
	ID numeric(15)
		CONSTRAINT Trades_PK PRIMARY KEY,
	Price numeric(6, 2) NOT NULL,
	Quantity numeric(6, 1) NOT NULL
		CONSTRAINT Trade_Quantity_Positive check(Quantity > 0),
	BuyOrderID numeric(15)
		CONSTRAINT Trade_BuyOrderID_FK REFERENCES Orders(ID) ON DELETE SET null,
	SellOrderID numeric(15)
		CONSTRAINT Trade_SellOrderID_FK REFERENCES Orders(ID) ON DELETE SET null,
	ExecutionTs timestamp(3) NOT NULL,
	CONSTRAINT Trade_OrderIDs_Different CHECK(BuyOrderID <> SellOrderId)
);

CREATE TABLE ProfitAndLoss(
	ParticipantID numeric(15) NOT NULL
		CONSTRAINT ProfitAndLoss_ParticipantID_FK REFERENCES Participants(ID) ON DELETE CASCADE,
	ContractID numeric(15) NOT NULL
		CONSTRAINT ProfitAndLoss_ContractID_FK REFERENCES Contracts(ID),
	Value numeric(9, 3) NOT NULL,
	CONSTRAINT ProfitAndLoss_PK PRIMARY key(ParticipantID, ContractID)
);

CREATE TABLE AuditLog(
	Timestamp timestamp(3) NOT NULL,
	Text CHARACTER varying(300 char) NOT NULL
);

/* Indexes */

CREATE INDEX Contracts_Product_Idx ON Contracts(ProductID);

CREATE INDEX Orders_Contract_Price_Side_Active_Idx ON Orders(ContractID, Price, Side, Active);

CREATE INDEX Trades_BuyOrderID_Idx ON Trades(BuyOrderID);
CREATE INDEX Trades_SellOrderID_Idx ON Trades(SellOrderID);

/* Sequences */

CREATE SEQUENCE Products_ID_Sequence START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER Products_INSERT
BEFORE INSERT ON Products
	FOR EACH ROW 
BEGIN
	SELECT Products_ID_Sequence.nextval INTO :NEW.ID FROM dual;
END;

CREATE SEQUENCE Contracts_ID_Sequence START WITH 1 INCREMENT BY 1;

CREATE OR replace TRIGGER Contracts_INSERT
BEFORE INSERT ON Contracts
	FOR EACH ROW 
BEGIN
	SELECT Contracts_ID_Sequence.nextval INTO :NEW.ID FROM dual;
END;

CREATE SEQUENCE Participants_ID_Sequence START WITH 1 INCREMENT BY 1;

CREATE OR replace TRIGGER Participants_INSERT
BEFORE INSERT ON Participants
	FOR EACH ROW 
BEGIN
	SELECT Participants_ID_Sequence.nextval INTO :NEW.ID FROM dual;
END;

CREATE SEQUENCE Orders_ID_Sequence START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER Orders_INSERT
BEFORE INSERT ON Orders
	FOR EACH ROW 
BEGIN
	IF (:NEW.Active <> 'Y') THEN
		RAISE_APPLICATION_ERROR(-20015, 'Cannot insert inactive order');
	END IF;
	SELECT Orders_ID_Sequence.nextval INTO :NEW.ID FROM dual;
END;

CREATE SEQUENCE Trades_ID_Sequence START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER Trades_INSERT
BEFORE INSERT ON Trades
	FOR EACH ROW 
BEGIN
	IF (:NEW.BuyOrderID IS NULL OR :NEW.SellOrderID IS null) THEN
		RAISE_APPLICATION_ERROR(-20016, 'Trades should have both order IDs on insertion');
	END IF;
	SELECT Trades_ID_Sequence.nextval INTO :NEW.ID FROM dual;
END;

/* Triggers */

CREATE OR REPLACE TRIGGER AuditLogInsert
BEFORE INSERT ON AuditLog
FOR EACH ROW
BEGIN
	:NEW.Timestamp := SYSTIMESTAMP;
END;

CREATE OR REPLACE TRIGGER AuditLogImmutable
BEFORE UPDATE OR DELETE ON AuditLog
FOR EACH ROW
BEGIN
	RAISE_APPLICATION_ERROR(-20020, 'Updates or delete are not allowed on the audit log.');
END;

CREATE OR REPLACE TRIGGER TradesImmutable
BEFORE UPDATE OR DELETE ON Trades
FOR EACH ROW
BEGIN
	RAISE_APPLICATION_ERROR(-20021, 'The trades cannot be removed and altered for audit purposes');
END;


/* Logging procedure */
CREATE OR REPLACE PROCEDURE LogMessage(
	pText AuditLog.Text%TYPE
) AS
BEGIN
	INSERT INTO AuditLog(Text)
	VALUES (pText);
END LogMessage;









