CREATE TABLE Whitelist (
    whitelist_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NULL,
    merchant_id INT NULL,
    reason NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Whitelist_User FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT FK_Whitelist_Merchant FOREIGN KEY (merchant_id) REFERENCES Merchants(merchant_id)
);

select *
from Whitelist

-- =========================================
-- MBUSHJA E Whitelist me 9000 rreshta
-- Ruaj realism dhe përputhshmëri me Users dhe Merchants
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 9000;

DECLARE @user_id INT;
DECLARE @merchant_id INT;
DECLARE @reason NVARCHAR(MAX);

WHILE @counter <= @total_inserts
BEGIN
    DECLARE @rand_type INT = CAST(RAND(CHECKSUM(NEWID()))*100 AS INT);

    IF @rand_type < 50
    BEGIN
        -- 50% vetëm user
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();
        SET @merchant_id = NULL;
        SET @reason = 'Trusted user: ' + CAST(@user_id AS NVARCHAR(10));
    END
    ELSE IF @rand_type < 80
    BEGIN
        -- 30% vetëm merchant
        SET @user_id = NULL;
        SELECT TOP 1 @merchant_id = merchant_id FROM Merchants ORDER BY NEWID();
        SET @reason = 'Trusted merchant: ' + CAST(@merchant_id AS NVARCHAR(10));
    END
    ELSE
    BEGIN
        -- 20% user + merchant
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();
        SELECT TOP 1 @merchant_id = merchant_id FROM Merchants ORDER BY NEWID();
        SET @reason = 'Trusted user ' + CAST(@user_id AS NVARCHAR(10)) + ' and merchant ' + CAST(@merchant_id AS NVARCHAR(10));
    END

    -- Insert
    INSERT INTO Whitelist (user_id, merchant_id, reason)
    VALUES (@user_id, @merchant_id, @reason);

    -- Progres çdo 1000 rreshta
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' rreshta në Whitelist.';
