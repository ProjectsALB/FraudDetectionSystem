-- 13. BEHAVIOR_PROFILE
CREATE TABLE Behavior_Profile (
    profile_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    avg_transaction_amount DECIMAL(18,2) NULL,
    avg_daily_transactions DECIMAL(5,2) NULL,
    common_country VARCHAR(50) NULL,
    usual_login_hour INT NULL,
    risk_pattern_score INT DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_BehaviorProfile_User FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

select *
from Behavior_Profile


-- =========================================
-- MBUSHJA E Behavior_Profile me 10000 rreshta (rregulluar)
-- Ruaj realism dhe përputhshmëri me Users, Transactions, Login_History
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_users INT = 10000;

DECLARE @user_id INT;
DECLARE @avg_transaction_amount DECIMAL(18,2);
DECLARE @avg_daily_transactions DECIMAL(5,2);
DECLARE @common_country VARCHAR(50);
DECLARE @usual_login_hour INT;
DECLARE @risk_pattern_score INT;

WHILE @counter <= @total_users
BEGIN
    -- Zgjidh user_id që nuk ka profile akoma
    SELECT TOP 1 @user_id = user_id 
    FROM Users 
    WHERE user_id NOT IN (SELECT user_id FROM Behavior_Profile)
    ORDER BY NEWID();

    -- Gjenero avg_transaction_amount nga Transactions të këtij user
    SELECT @avg_transaction_amount = AVG(amount)
    FROM Transactions t
    INNER JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id;

    IF @avg_transaction_amount IS NULL
        SET @avg_transaction_amount = CAST(RAND(CHECKSUM(NEWID())) * 1000 AS DECIMAL(18,2));

    -- Gjenero avg_daily_transactions bazuar në Transactions
    DECLARE @total_tx INT, @days_active INT;
    SELECT @total_tx = COUNT(*)
    FROM Transactions t
    INNER JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id;

    SELECT @days_active = DATEDIFF(DAY, MIN(transaction_time), MAX(transaction_time))
    FROM Transactions t
    INNER JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id;

    IF @days_active IS NULL OR @days_active = 0
        SET @days_active = 1;

    SET @avg_daily_transactions = CAST(@total_tx * 1.0 / @days_active AS DECIMAL(5,2));

    -- Gjenero common_country nga Login_History ose Users.country si fallback
    SELECT TOP 1 @common_country = lh.country
    FROM Login_History lh
    WHERE lh.user_id = @user_id
    GROUP BY lh.country
    ORDER BY COUNT(*) DESC;

    IF @common_country IS NULL
        SELECT @common_country = country FROM Users WHERE user_id = @user_id;

    -- Gjenero usual_login_hour nga Login_History
    SELECT TOP 1 @usual_login_hour = DATEPART(HOUR, login_time)
    FROM Login_History
    WHERE user_id = @user_id
    ORDER BY NEWID();

    IF @usual_login_hour IS NULL
        SET @usual_login_hour = CAST(RAND(CHECKSUM(NEWID()))*24 AS INT);

    -- Gjenero risk_pattern_score rastësor 0-100
    SET @risk_pattern_score = CAST(RAND(CHECKSUM(NEWID()))*101 AS INT);

    -- Insert në tabelë
    INSERT INTO Behavior_Profile (
        user_id, 
        avg_transaction_amount, 
        avg_daily_transactions, 
        common_country, 
        usual_login_hour, 
        risk_pattern_score
    )
    VALUES (
        @user_id, 
        @avg_transaction_amount, 
        @avg_daily_transactions, 
        @common_country, 
        @usual_login_hour, 
        @risk_pattern_score
    );

    -- Progres çdo 1000 rreshta
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_users AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_users AS VARCHAR) + ' Behavior Profiles.';



