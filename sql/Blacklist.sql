CREATE TABLE Blacklist (
    blacklist_id INT IDENTITY(1,1) PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    value VARCHAR(100) NOT NULL,
    reason NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
select *
from Blacklist

-- =========================================
-- MBUSHJA E Blacklist me 9000 rreshta
-- Ruaj realism dhe përputhshmëri me Users, Merchants dhe Transactions
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 9000;

DECLARE @type VARCHAR(20);
DECLARE @value VARCHAR(100);
DECLARE @reason NVARCHAR(MAX);
DECLARE @created_at DATETIME;

WHILE @counter <= @total_inserts
BEGIN
    -- Vendos tipin e blacklist
    DECLARE @rand_type INT = CAST(RAND(CHECKSUM(NEWID()))*3 AS INT);
    IF @rand_type = 0
        SET @type = 'USER';
    ELSE IF @rand_type = 1
        SET @type = 'MERCHANT';
    ELSE
        SET @type = 'IP';

    -- Vendos value dhe reason sipas tipit
    IF @type = 'USER'
    BEGIN
        -- Zgjidh random user
        DECLARE @user_email VARCHAR(100);
        SELECT TOP 1 @user_email = email FROM Users ORDER BY NEWID();
        SET @value = @user_email;
        SET @reason = 'Suspicious activity detected for user ' + @user_email;
    END
    ELSE IF @type = 'MERCHANT'
    BEGIN
        -- Zgjidh random merchant
        DECLARE @merchant_name VARCHAR(100);
        SELECT TOP 1 @merchant_name = merchant_name FROM Merchants ORDER BY NEWID();
        SET @value = @merchant_name;
        SET @reason = 'Suspicious transactions detected for merchant ' + @merchant_name;
    END
    ELSE
    BEGIN
        -- IP rastësore nga Transactions
        DECLARE @ip VARCHAR(45);
        SELECT TOP 1 @ip = ip_address FROM Transactions WHERE ip_address IS NOT NULL ORDER BY NEWID();
        IF @ip IS NULL
            SET @ip = CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR);
        SET @value = @ip;
        SET @reason = 'IP address flagged for suspicious activity: ' + @ip;
    END

    -- Created_at brenda 2 viteve
    SET @created_at = DATEADD(MINUTE, CAST(RAND(CHECKSUM(NEWID()))*60*24*730 AS INT), DATEADD(DAY, -730, GETDATE()));

    -- Insert
    INSERT INTO Blacklist (type, value, reason, created_at)
    VALUES (@type, @value, @reason, @created_at);

    -- Progres çdo 1000 rreshta
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' rreshta në Blacklist.';
