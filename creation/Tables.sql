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
		CONSTRAINT ParticipantAllowedProducts_ParticipantID_FK REFERENCES Participants(ID),
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
		CONSTRAINT Order_OwnerID_FK REFERENCES Participants(ID),
	ContractID numeric(15) NOT NULL
		CONSTRAINT Order_ContractID_FK REFERENCES Contracts(ID)
);

CREATE TABLE Trades(
	ID numeric(15)
		CONSTRAINT Trades_PK PRIMARY KEY,
	Price numeric(6, 2) NOT NULL,
	Quantity numeric(6, 1) NOT NULL
		CONSTRAINT Trade_Quantity_Positive check(Quantity > 0),
	BuyOrderID numeric(15) NOT NULL
		CONSTRAINT Trade_BuyOrderID_FK REFERENCES Orders(ID),
	SellOrderID numeric(15) NOT NULL
		CONSTRAINT Trade_SellOrderID_FK REFERENCES Orders(ID),
	ExecutionTs timestamp(3) NOT NULL,
	CONSTRAINT Trade_OrderIDs_Different CHECK(BuyOrderID <> SellOrderId)
);

/* TODO will we ADD the AUDIT table? */

CREATE TABLE ProfitAndLoss(
	ParticipantID numeric(15) NOT NULL
		CONSTRAINT ProfitAndLoss_ParticipantID_FK REFERENCES Participants(ID),
	ContractID numeric(15) NOT NULL
		CONSTRAINT ProfitAndLoss_ContractID_FK REFERENCES Contracts(ID),
	Value numeric(9, 3) NOT NULL,
	CONSTRAINT ProfitAndLoss_PK PRIMARY key(ParticipantID, ContractID)
);



/* Indexes TODO */

/* Sequences */

CREATE SEQUENCE Product_ID_Sequence START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Product_ID_Sequence START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Product_ID_Sequence START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Product_ID_Sequence START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Product_ID_Sequence START WITH 1 INCREMENT BY 1;

/* Triggers TODO */
