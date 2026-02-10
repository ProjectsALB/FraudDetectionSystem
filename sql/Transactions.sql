CREATE TABLE Transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    account_id INT NOT NULL,
    merchant_id INT NOT NULL,
    device_id INT NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency CHAR(3) DEFAULT 'EUR',
    transaction_type VARCHAR(50) DEFAULT 'PAYMENT',
    geo_location VARCHAR(100),
    ip_address VARCHAR(45),
    transaction_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'SUCCESS',
    risk_score INT DEFAULT 0,
    ml_score DECIMAL(5,2) NULL,
    CONSTRAINT FK_Transactions_Account FOREIGN KEY (account_id) REFERENCES Accounts(account_id),
    CONSTRAINT FK_Transactions_Merchant FOREIGN KEY (merchant_id) REFERENCES Merchants(merchant_id),
    CONSTRAINT FK_Transactions_Device FOREIGN KEY (device_id) REFERENCES Devices(device_id)
);

select *
from Transactions

-- =========================================
-- MBUSHJA E Transactions me 10000 rreshta
-- 20% përputhshmëri me user/device/account ekzistues
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 10000;

DECLARE @account_id INT;
DECLARE @merchant_id INT;
DECLARE @device_id INT;
DECLARE @amount DECIMAL(18,2);
DECLARE @currency CHAR(3);
DECLARE @transaction_type VARCHAR(50);
DECLARE @geo_location VARCHAR(100);
DECLARE @ip_address VARCHAR(45);
DECLARE @transaction_time DATETIME;
DECLARE @status VARCHAR(20);
DECLARE @risk_score INT;
DECLARE @ml_score DECIMAL(5,2);

-- Lista e tipave të transaksioneve
DECLARE @types TABLE (name VARCHAR(50));
INSERT INTO @types VALUES ('PAYMENT'),('TRANSFER'),('WITHDRAWAL'),('DEPOSIT');

WHILE @counter <= @total_inserts
BEGIN
    -- 20% përputhshmëri me device + account
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 20
    BEGIN
        -- Zgjidh një account që ka device të lidhur
        SELECT TOP 1 @account_id = A.account_id, @device_id = D.device_id
        FROM Accounts A
        JOIN Devices D ON A.user_id = D.user_id
        ORDER BY NEWID();
    END
    ELSE
    BEGIN
        -- Account random
        SELECT TOP 1 @account_id = account_id, @device_id = device_id
        FROM Accounts
        LEFT JOIN Devices ON Accounts.user_id = Devices.user_id
        ORDER BY NEWID();
    END

    -- Merchant random
    SELECT TOP 1 @merchant_id = merchant_id FROM Merchants ORDER BY NEWID();

    -- Amount 1 - 10000
    SET @amount = CAST(RAND(CHECKSUM(NEWID()))*10000+1 AS DECIMAL(18,2));

    -- Currency rastësore
    DECLARE @rand_curr INT = CAST(RAND(CHECKSUM(NEWID()))*4 AS INT);
    IF @rand_curr = 0 SET @currency = 'EUR';
    ELSE IF @rand_curr = 1 SET @currency = 'USD';
    ELSE IF @rand_curr = 2 SET @currency = 'GBP';
    ELSE SET @currency = 'CHF';

    -- Transaction type
    SELECT TOP 1 @transaction_type = name FROM @types ORDER BY NEWID();

    -- geo_location dhe IP
    DECLARE @lat DECIMAL(10,6) = CAST(RAND(CHECKSUM(NEWID()))*180-90 AS DECIMAL(10,6));
    DECLARE @long DECIMAL(10,6) = CAST(RAND(CHECKSUM(NEWID()))*360-180 AS DECIMAL(10,6));
    SET @geo_location = CAST(@lat AS VARCHAR) + ', ' + CAST(@long AS VARCHAR);

    SET @ip_address = CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR);

    -- transaction_time brenda 2 viteve të fundit
    SET @transaction_time = DATEADD(MINUTE, CAST(RAND(CHECKSUM(NEWID()))*60*24*730 AS INT), DATEADD(DAY, -730, GETDATE()));

    -- status: 90% SUCCESS, 10% FAILED
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 90
        SET @status = 'SUCCESS';
    ELSE
        SET @status = 'FAILED';

    -- risk_score: 0-100
    SET @risk_score = CAST(RAND(CHECKSUM(NEWID()))*101 AS INT);

    -- ml_score: 0.00 - 1.00
    SET @ml_score = CAST(RAND(CHECKSUM(NEWID())) AS DECIMAL(5,2));

    -- Insert në tabelë
    INSERT INTO Transactions (account_id, merchant_id, device_id, amount, currency, transaction_type, geo_location, ip_address, transaction_time, status, risk_score, ml_score)
    VALUES (@account_id, @merchant_id, @device_id, @amount, @currency, @transaction_type, @geo_location, @ip_address, @transaction_time, @status, @risk_score, @ml_score);

    -- Progres çdo 1000 transaksione
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' transactions.';
