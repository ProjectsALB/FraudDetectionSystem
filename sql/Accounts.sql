CREATE TABLE Accounts (
    account_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    iban VARCHAR(34) NOT NULL UNIQUE,
    balance DECIMAL(18,2) DEFAULT 0,
    currency CHAR(3) DEFAULT 'EUR',
    account_type VARCHAR(20) DEFAULT 'STANDARD',
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Accounts_User FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

select *
from Accounts

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 10000;
DECLARE @user_id INT;
DECLARE @iban VARCHAR(34);
DECLARE @balance DECIMAL(18,2);
DECLARE @currency CHAR(3);
DECLARE @account_type VARCHAR(20);
DECLARE @status VARCHAR(20);
DECLARE @rand_curr INT;
DECLARE @rand_type INT;

WHILE @counter <= @total_inserts
BEGIN
    -- 20% user_id nga User_Roles
    IF CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT) < 20
        SELECT TOP 1 @user_id = user_id FROM User_Roles ORDER BY NEWID();
    ELSE
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();

    -- IBAN unik: 2 letra + 16 shifra + counter
    SET @iban = 'AL' + RIGHT('0000000000000000' + CAST(CAST(RAND(CHECKSUM(NEWID()))*10000000000000000 AS BIGINT) AS VARCHAR(16)),16) + CAST(@counter AS VARCHAR(5));

    -- Balance
    SET @balance = CAST(RAND(CHECKSUM(NEWID())) * 100000 AS DECIMAL(18,2));

    -- Currency
    SET @rand_curr = CAST(RAND(CHECKSUM(NEWID()))*4 AS INT);
    IF @rand_curr = 0 SET @currency = 'EUR';
    ELSE IF @rand_curr = 1 SET @currency = 'USD';
    ELSE IF @rand_curr = 2 SET @currency = 'GBP';
    ELSE SET @currency = 'CHF';

    -- Account type
    SET @rand_type = CAST(RAND(CHECKSUM(NEWID()))*3 AS INT);
    IF @rand_type = 0 SET @account_type = 'STANDARD';
    ELSE IF @rand_type = 1 SET @account_type = 'SAVINGS';
    ELSE SET @account_type = 'BUSINESS';

    -- Status
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 90
        SET @status = 'ACTIVE';
    ELSE
        SET @status = 'FROZEN';

    -- Insert
    INSERT INTO Accounts (user_id, iban, balance, currency, account_type, status)
    VALUES (@user_id, @iban, @balance, @currency, @account_type, @status);

    -- Progres
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END;

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' llogari.';
