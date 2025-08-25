DELETE FROM ProfitAndLoss;
DELETE FROM Trades;
DELETE FROM Orders;
DELETE FROM ParticipantAllowedProducts;
DELETE FROM Participants;
DELETE FROM Contracts;
DELETE FROM Products;

BEGIN
    AdminPackage.CreateUser('Juan Valdez');
    AdminPackage.CreateUser('Sofia Vergara');
    AdminPackage.CreateUser('Fernando Botero');
    AdminPackage.CreateUser('Shakira Mebarak');
    AdminPackage.CreateProduct('Coffee');
    AdminPackage.CreateProduct('Crude Oil');
    AdminPackage.CreateProduct('Gold');
    AdminPackage.CreateProduct('Sugar');
END;
/

DECLARE
    vUserID1 Participants.ID%TYPE;
    vUserID2 Participants.ID%TYPE;
    vUserID3 Participants.ID%TYPE;
    vUserID4 Participants.ID%TYPE;
    vProductID1 Products.ID%TYPE;
    vProductID2 Products.ID%TYPE;
    vProductID3 Products.ID%TYPE;
    vProductID4 Products.ID%TYPE;
BEGIN
    SELECT ID INTO vUserID1 FROM Participants WHERE LegalName = 'Juan Valdez';
    SELECT ID INTO vUserID2 FROM Participants WHERE LegalName = 'Sofia Vergara';
    SELECT ID INTO vUserID3 FROM Participants WHERE LegalName = 'Fernando Botero';
    SELECT ID INTO vUserID4 FROM Participants WHERE LegalName = 'Shakira Mebarak';
    SELECT ID INTO vProductID1 FROM Products WHERE Name = 'Coffee';
    SELECT ID INTO vProductID2 FROM Products WHERE Name = 'Crude Oil';
    SELECT ID INTO vProductID3 FROM Products WHERE Name = 'Gold';
    SELECT ID INTO vProductID4 FROM Products WHERE Name = 'Sugar';

    AdminPackage.CreateContract(vProductID1, SYSTIMESTAMP);
    AdminPackage.CreateContract(vProductID1, SYSTIMESTAMP + INTERVAL '1' DAY);
    AdminPackage.CreateContract(vProductID2, SYSTIMESTAMP);
    AdminPackage.CreateContract(vProductID2, SYSTIMESTAMP + INTERVAL '1' DAY);
    AdminPackage.CreateContract(vProductID3, SYSTIMESTAMP);
    AdminPackage.CreateContract(vProductID3, SYSTIMESTAMP + INTERVAL '1' DAY);
    AdminPackage.CreateContract(vProductID4, SYSTIMESTAMP);
    AdminPackage.CreateContract(vProductID4, SYSTIMESTAMP + INTERVAL '1' DAY);

    AdminPackage.ChangeUserLimit(vUserID1, vProductID1, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID1, vProductID2, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID1, vProductID3, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID1, vProductID4, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID2, vProductID1, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID2, vProductID2, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID2, vProductID3, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID2, vProductID4, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID3, vProductID1, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID3, vProductID2, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID3, vProductID3, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID3, vProductID4, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID4, vProductID1, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID4, vProductID2, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID4, vProductID3, 100, 100);
    AdminPackage.ChangeUserLimit(vUserID4, vProductID4, 100, 100);
END;
/