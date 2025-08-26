/* DROP ALL views */
DROP VIEW l1;
DROP VIEW ActiveOrders;
DROP VIEW ActiveParticipants;
DROP VIEW UsersPNL;

/* DROP ALL packages */
DROP package AdminPackage;
DROP package OrdersPackage;
DROP package TradingStatisticsPackage;

/* DROP ALL sequences */
DROP SEQUENCE Products_ID_Sequence;
DROP SEQUENCE Contracts_ID_Sequence;
DROP SEQUENCE Participants_ID_Sequence;
DROP SEQUENCE Orders_ID_Sequence;
DROP SEQUENCE Trades_ID_Sequence;

/* DROP ALL triggers */
TODO

/* DROP ALL indexes */
DROP INDEX Contracts_Product_Idx;
DROP INDEX Orders_Contract_Price_Side_Active_Idx;
DROP INDEX Trades_BuyOrderID_Idx;
DROP INDEX Trades_SellOrderID_Idx;

/* DROP ALL tables */
DROP TABLE ProfitAndLoss;
DROP TABLE Trades;
DROP TABLE Orders;
DROP TABLE ParticipantAllowedProducts;
DROP TABLE Participants;
DROP TABLE Contracts;
DROP TABLE Products;
