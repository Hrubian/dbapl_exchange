
/* Order actions package */
CREATE OR replace package OrdersPackage
AS
	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pContract Orders.ContractID%TYPE		
	);

	PROCEDURE ModifyOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
	
	PROCEDURE CancelOrder(
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
END OrdersPackage;

CREATE OR replace package body OrdersPackage
AS
	PROCEDURE NewOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pContract Orders.ContractID%TYPE		
	);

	PROCEDURE ModifyOrder(
		pPrice Orders.Price%TYPE,
		pQuantity Orders.Quantity%TYPE,
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
	
	PROCEDURE CancelOrder(
		pOwner Orders.OwnerID%TYPE,
		pOrderID Orders.ID%TYPE
	);
END OrdersPackage;