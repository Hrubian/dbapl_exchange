/* Test phases:
* - create inactive contract
* - verify we cannot create orders on it
* - wait for the contract activation time
* - create order, modify and cancel it
* - create another order to be later removed by the expiration
* - expire the contract
* - check the order is not active anymore (use the view for it)
* - check no new order can be created
* - chech the PNL report is present and has correct value
*/

DECLARE
	vProductID Products.ID%TYPE;
	vContractID Contracts.ID%TYPE;
	vOrderID1 Orders.ID%TYPE;
	vOrderID2 Orders.ID%TYPE;
BEGIN
	AdminPackage.CreateProduct('Wheat');
	SELECT ID INTO vProductID FROM Products WHERE Name = 'Wheat';

	AdminPackage.CreateContract(vProductID, systimestamp + INTERVAL '20' SECOND);
	SELECT ID INTO vContractID FROM Contracts WHERE ProductID = vProductID;
END;

