CREATE DATABASE BankSystemDB;
GO

USE BankSystemDB;
GO

CREATE TABLE ClientStatus(
	StatusID INT PRIMARY KEY NOT NULL,
	StatusName NVARCHAR(50) NOT NULL
);

CREATE TABLE Client(
	ClientID INT PRIMARY KEY NOT NULL,
	ClientName NVARCHAR(50) NOT NULL,
	ClientSurname NVARCHAR(50) NOT NULL,
	StatusID INT REFERENCES ClientStatus (StatusID) NOT NULL
);

CREATE TABLE Bank(
	BankID INT PRIMARY KEY NOT NULL,
	BankName NVARCHAR(50) NOT NULL
);

CREATE TABLE Account(
	AccountID INT PRIMARY KEY NOT NULL,
	Balance MONEY NOT NULL,
	ClientID INT REFERENCES Client (ClientID) NOT NULL,
	BankID INT REFERENCES Bank (BankID) NOT NULL
);

CREATE TABLE BankCard(
	CardID INT PRIMARY KEY NOT NULL,
	Balance MONEY NOT NULL,
	AccountID INT REFERENCES Account (AccountID) NOT NULL
);

CREATE TABLE City(
	CityID INT PRIMARY KEY NOT NULL,
	CityName NVARCHAR(50) NOT NULL
);

CREATE TABLE Branch(
	BranchID INT PRIMARY KEY NOT NULL,
	CityID INT REFERENCES City (CityID) NOT NULL,
	BankID INT REFERENCES Bank (BankID) NOT NULL
);

CREATE TABLE BankClient(
	BankID INT REFERENCES Bank (BankID) NOT NULL,
	ClientID INT REFERENCES Client (ClientID) NOT NULL,
	CONSTRAINT PK_BankClient PRIMARY KEY (BankID, ClientID)
);
   
INSERT INTO ClientStatus(StatusID, StatusName)
VALUES (1, 'Without benefits');
INSERT INTO ClientStatus(StatusID, StatusName)
VALUES (2, 'Veteran of labour');
INSERT INTO ClientStatus(StatusID, StatusName)
VALUES (3, 'Disabled person');
INSERT INTO ClientStatus(StatusID, StatusName)
VALUES (4, 'The large family');
INSERT INTO ClientStatus(StatusID, StatusName)
VALUES (5, 'Pensioner');

INSERT INTO City(CityID, CityName)
VALUES (1, 'Polotsk');
INSERT INTO City(CityID, CityName)
VALUES (2, 'Mogilev');
INSERT INTO City(CityID, CityName)
VALUES (3, 'Minsk');
INSERT INTO City(CityID, CityName)
VALUES (4, 'Brest');
INSERT INTO City(CityID, CityName)
VALUES (5, 'Grodno');

INSERT INTO Bank(BankID, BankName)
VALUES (1, 'Tinkoff');
INSERT INTO Bank(BankID, BankName)
VALUES (2, 'Belarusbank');
INSERT INTO Bank(BankID, BankName)
VALUES (3, 'Sberbank');
INSERT INTO Bank(BankID, BankName)
VALUES (4, 'Alfabank');
INSERT INTO Bank(BankID, BankName)
VALUES (5, 'VTB');

INSERT INTO Branch(BranchID, BankID, CityID)
VALUES (1, 1, 1);
INSERT INTO Branch(BranchID, BankID, CityID)
VALUES (2, 1, 1);
INSERT INTO Branch(BranchID, BankID, CityID)
VALUES (3, 2, 1);
INSERT INTO Branch(BranchID, BankID, CityID)
VALUES (4, 5, 4);
INSERT INTO Branch(BranchID, BankID, CityID)
VALUES (5, 3, 2);

INSERT INTO Client(ClientID, ClientName, ClientSurname, StatusID)
VALUES (1, 'Vladislav', 'Makarov', 1);
INSERT INTO Client(ClientID, ClientName, ClientSurname, StatusID)
VALUES (2, 'Valentina', 'Prokofieva', 4);
INSERT INTO Client(ClientID, ClientName, ClientSurname, StatusID)
VALUES (3, 'Alexei', 'Averin', 3);
INSERT INTO Client(ClientID, ClientName, ClientSurname, StatusID)
VALUES (4, 'Irina', 'Ivanova', 5);
INSERT INTO Client(ClientID, ClientName, ClientSurname, StatusID)
VALUES (5, 'Dmitriy', 'Vasiliev', 2);

INSERT INTO BankClient(BankID, ClientID)
VALUES (1, 2);
INSERT INTO BankClient(BankID, ClientID)
VALUES (1, 4);
INSERT INTO BankClient(BankID, ClientID)
VALUES (1, 3);
INSERT INTO BankClient(BankID, ClientID)
VALUES (2, 2);
INSERT INTO BankClient(BankID, ClientID)
VALUES (3, 1);
INSERT INTO BankClient(BankID, ClientID)
VALUES (4, 5);
INSERT INTO BankClient(BankID, ClientID)
VALUES (4, 4);
INSERT INTO BankClient(BankID, ClientID)
VALUES (5, 2);

INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (1, 44, 1, 3);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (2, 274.4, 1, 3);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (3, 60.5, 5, 4);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (4, 540.5, 3, 1);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (5, 450.8, 4, 1);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (6, 74.1, 4, 4);
INSERT INTO Account(AccountID, Balance, ClientID, BankID)
VALUES (7, 210, 2, 5);

INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (1, 15.5, 6);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (2, 30, 6);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (3, 44, 1);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (4, 150, 2);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (5, 59.1, 3);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (6, 400, 5);
INSERT INTO BankCard(CardID, Balance, AccountID)
VALUES (7, 210, 7);

GO
-- | Creation | --
-- | Default | --
CREATE FUNCTION GetMoneyDifference (@accID INT)
RETURNS MONEY
BEGIN
	DECLARE @accBalance MONEY;
	DECLARE @sumCardBalance MONEY;
	DECLARE @moneyDifference MONEY;
	SELECT @sumCardBalance = SUM(Balance) FROM BankCard WHERE AccountID = @accID;
	SELECT @accBalance = Balance FROM Account WHERE AccountID = @accID;
	SET @moneyDifference = @accBalance - @sumCardBalance;
	RETURN @moneyDifference;
END;
GO

-- | 5 | --
CREATE PROCEDURE UpdateBalanceForStatus (@statusID INT)
AS 
UPDATE Account 
	SET Balance = Balance + 10
	WHERE ClientID IN (SELECT ClientID
						FROM Client
						WHERE StatusID = @statusID);
GO

-- | 7 | --
CREATE PROCEDURE MoneyTransferWithTranzaction (@cardId INT, @sumOfTransfer MONEY)
AS
BEGIN
	DECLARE @accountId INT;
	DECLARE @enableMoney MONEY;
	SELECT @accountId = AccountID FROM BankCard WHERE CardID = @cardId;
	SET @enableMoney = dbo.GetMoneyDifference(@accountId);

	IF @sumOfTransfer <= @enableMoney 
		AND @sumOfTransfer > 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
		BEGIN TRANSACTION;

		UPDATE Account
		SET Balance = Balance - @sumOfTransfer
		WHERE AccountID = @accountId;

		UPDATE BankCard
		SET Balance = Balance + @sumOfTransfer
		WHERE CardID = @cardId;

		COMMIT TRANSACTION;
	END;
END;
GO

-- | 8 - Accounts | --
CREATE TRIGGER CheckAccountBalance
ON Account
INSTEAD OF UPDATE
AS
	DECLARE @accountID INT;
	DECLARE @accountBalance MONEY;
	DECLARE @cardSum MONEY;

	SELECT @accountID =  AccountID FROM inserted;
	SELECT @accountBalance = Balance FROM inserted;
	SELECT @cardSum = SUM(Balance) FROM BankCard WHERE AccountID = @accountID;

	IF(@accountBalance >= @cardSum)
	BEGIN
		UPDATE Account
		SET Balance = @accountBalance
		WHERE AccountID = @accountID
	END;
GO

-- | 8 - Cards | --
CREATE TRIGGER CheckCardBalance
ON BankCard
INSTEAD OF UPDATE
AS
	DECLARE @cardID INT;
	DECLARE @newCardBalance MONEY;
	DECLARE @oldCardBalance MONEY;
	DECLARE @sumBalance MONEY;
	DECLARE @accountID INT;
	DECLARE @accountBalance MONEY;

	SELECT @cardID = CardID FROM inserted;
	SELECT @newCardBalance = Balance FROM inserted;
	SELECT @oldCardBalance = Balance FROM deleted;
	SELECT @accountID = AccountID FROM inserted;
	SELECT @accountBalance = Balance FROM Account WHERE AccountID = @accountID;
	SELECT @sumBalance = SUM(Balance) FROM BankCard WHERE AccountID = @accountID;

	IF((@sumBalance - @oldCardBalance + @newCardBalance) <= @accountBalance)
	BEGIN
		UPDATE BankCard
		SET Balance = @newCardBalance
		WHERE CardID = @cardID
	END;
GO
-- | Selection | --
-- | 1 | --
SELECT BankName 
FROM Bank 
WHERE BankID IN (SELECT BankID
				FROM Branch
				WHERE CityID = 1);

-- | 2 | --
SELECT 
	ClientName,
	ClientSurname,
	BankName,
	BankCard.Balance,
	BankCard.CardID
FROM 
	Client,
	Account,
	Bank,
	BankCard
WHERE
	Account.ClientID = Client.ClientID
	AND Account.BankID = Bank.BankID
	AND BankCard.AccountID = Account.AccountID;

-- | 3 | --
SELECT *,
		dbo.GetMoneyDifference(AccountID) AS MoneyDifference
FROM Account
WHERE dbo.GetMoneyDifference(AccountID) != 0;

-- | 4.1 | --
SELECT 
		StatusName, 
		COUNT(*) AS NumOfCards
FROM 
		ClientStatus, 
		Client, 
		Account, 
		BankCard
WHERE 
		ClientStatus.StatusID = Client.StatusID
		AND Client.ClientID = Account.ClientID
		AND Account.AccountID = BankCard.AccountID
GROUP BY 
		StatusName;

-- | 4.2 | --
SELECT 
	StatusName, 
	(SELECT COUNT(StatusID)
		FROM Client,
			Account, 
			BankCard	
		WHERE StatusID = ClientStatus.StatusID
			AND Client.ClientID = Account.ClientID
			AND Account.AccountID = BankCard.AccountID
	) AS NumOfCards
FROM ClientStatus;

-- | 6 | --
SELECT 
		Client.ClientName, 
		Client.ClientSurname, 
		Bank.BankName, 
		dbo.GetMoneyDifference(AccountID) AS EnableMoney
FROM 
		Account, 
		Client, 
		Bank
WHERE 
	Account.ClientID = Client.ClientID 
	AND Account.BankID = Bank.BankID 
	AND dbo.GetMoneyDifference(AccountID) > 0;