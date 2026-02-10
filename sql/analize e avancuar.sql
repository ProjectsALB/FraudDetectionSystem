--) Lista e përdoruesve me risk më të lartë

SELECT u.user_id, u.full_name, u.email, u.risk_level, COUNT(t.transaction_id) AS total_transactions
FROM Users u
LEFT JOIN Accounts a ON u.user_id = a.user_id
LEFT JOIN Transactions t ON a.account_id = t.account_id
GROUP BY u.user_id, u.full_name, u.email, u.risk_level
ORDER BY u.risk_level DESC, total_transactions DESC;


--Transaksionet e dyshimta sipas vlerës dhe vendit

SELECT t.transaction_id, t.amount, t.currency, t.geo_location, t.transaction_time, t.risk_score, u.full_name
FROM Transactions t
JOIN Accounts a ON t.account_id = a.account_id
JOIN Users u ON a.user_id = u.user_id
WHERE t.amount > 1000 -- threshold për transaksione të mëdha
   OR t.geo_location NOT IN (SELECT common_country FROM Behavior_Profile bp WHERE bp.user_id = a.user_id)
ORDER BY t.risk_score DESC, t.transaction_time DESC;


--Përdorues me login nga paisje të panjohura

SELECT u.user_id, u.full_name, lh.device_id, COUNT(lh.login_id) AS login_count
FROM Login_History lh
JOIN Users u ON lh.user_id = u.user_id
WHERE lh.device_id NOT IN (SELECT device_id FROM Devices WHERE trusted = 1)
GROUP BY u.user_id, u.full_name, lh.device_id
ORDER BY login_count DESC;


 --Top 5 merchant që kanë shkaktuar më shumë alerts

 SELECT top 5
 m.merchant_name, COUNT(fa.alert_id) AS total_alerts, SUM(t.amount) AS total_alert_amount
FROM Fraud_Alerts fa
JOIN Transactions t ON fa.transaction_id = t.transaction_id
JOIN Merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name
ORDER BY total_alerts DESC
 

--Transaksionet që nuk përputhen me profilein e përdoruesit
 
SELECT 
    t.transaction_id, 
    t.account_id, 
    u.user_id, 
    u.full_name, 
    t.amount, 
    t.geo_location, 
    bp.common_country,
    t.transaction_time,
    t.risk_score
FROM Transactions t
JOIN Accounts a ON t.account_id = a.account_id
JOIN Users u ON a.user_id = u.user_id
LEFT JOIN Behavior_Profile bp ON u.user_id = bp.user_id
WHERE t.geo_location IS DISTINCT FROM bp.common_country
   OR t.amount > bp.avg_transaction_amount * 3
ORDER BY t.risk_score DESC, t.transaction_time DESC;

--top 10 paisjet më aktive të përdoruesve

 
SELECT top 10
    lh.device_id,
    COUNT(lh.login_id) AS total_logins,
    MAX(lh.login_time) AS last_login,
    u.user_id,
    u.full_name
FROM Login_History lh
JOIN Users u ON lh.user_id = u.user_id
GROUP BY lh.device_id, u.user_id, u.full_name
ORDER BY total_logins DESC



--Transaksione për një user që tejkalojnë mesataren e tij


SELECT 
    t.transaction_id,
    t.account_id,
    u.user_id,
    u.full_name,
    t.amount,
    bp.avg_transaction_amount,
    t.transaction_time
FROM Transactions t
JOIN Accounts a ON t.account_id = a.account_id
JOIN Users u ON a.user_id = u.user_id
JOIN Behavior_Profile bp ON u.user_id = bp.user_id
WHERE t.amount > bp.avg_transaction_amount * 2
ORDER BY t.amount DESC;


--Merchant me vlerën më të madhe totale të transaksioneve


SELECT top 10
    m.merchant_id,
    m.merchant_name,
    m.category,
    SUM(t.amount) AS total_amount,
    COUNT(t.transaction_id) AS total_transactions,
    m.risk_score
FROM Merchants m
JOIN Transactions t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_id, m.merchant_name, m.category, m.risk_score
ORDER BY total_amount DESC


--Alerts të papërpunuara për analistë
 
SELECT 
    fa.alert_id,
    fa.transaction_id,
    t.amount,
    u.user_id,
    u.full_name,
    fa.risk_score,
    fa.severity,
    fa.created_at
FROM Fraud_Alerts fa
JOIN Transactions t ON fa.transaction_id = t.transaction_id
JOIN Accounts a ON t.account_id = a.account_id
JOIN Users u ON a.user_id = u.user_id
WHERE fa.resolved = 0
ORDER BY fa.risk_score DESC, fa.created_at DESC;


                                  -----sorted procedure

--Llogarit risk bazuar në vlerë, frekuencë, dhe tip transaksioni.

-- Stored Procedure për llogaritjen e Risk Score
CREATE PROCEDURE CalculateRiskScore
    @TransactionID INT
AS
BEGIN
    DECLARE @Amount DECIMAL(18,2);
    DECLARE @AccountID INT;
    DECLARE @Risk INT = 0;

    -- Merr vlerat e transaksionit
    SELECT @Amount = amount, @AccountID = account_id
    FROM Transactions
    WHERE transaction_id = @TransactionID;

    -- Risk nga vlera
    IF @Amount > 10000
        SET @Risk = @Risk + 50;
    ELSE IF @Amount > 5000
        SET @Risk = @Risk + 30;

    -- Risk nga frekuenca e transaksioneve 24h
    IF (SELECT COUNT(*) 
        FROM Transactions
        WHERE account_id = @AccountID
          AND transaction_time >= DATEADD(DAY, -1, GETDATE())) > 5
    BEGIN
        SET @Risk = @Risk + 20;
    END

    -- Përditëso risk_score në Transactions
    UPDATE Transactions
    SET risk_score = @Risk
    WHERE transaction_id = @TransactionID;
END;
GO

 
EXEC CalculateRiskScore @TransactionID = 123;

 -- Krijo Stored Procedure për HighRiskTransactions
CREATE PROCEDURE GetHighRiskTransactions
AS
BEGIN
    -- Select i transaksioneve me risk > 70
    SELECT 
        t.transaction_id AS TransactionID,
        u.full_name AS UserName,
        a.account_id AS AccountID,
        t.amount AS Amount,
        t.transaction_time AS TransactionTime,
        fa.risk_score AS RiskScore,
        fa.severity AS Severity
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    JOIN Users u ON a.user_id = u.user_id
    LEFT JOIN Fraud_Alerts fa ON t.transaction_id = fa.transaction_id
    WHERE fa.risk_score >= 70
    ORDER BY fa.risk_score DESC, t.transaction_time DESC;
END;
GO
-- Ekzekuto Stored Procedure dhe shiko output tabelar
EXEC GetHighRiskTransactions;



--Gjenerimi i alertëve të fraudit për një transaksion të ri

CREATE OR ALTER PROCEDURE Generate_Fraud_Alert
    @trans_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @trans_amount DECIMAL(18,2);
    DECLARE @acc_id INT;
    DECLARE @user_id INT;
    DECLARE @risk_score INT = 0;

    -- Merr detajet e transaksionit
    SELECT @trans_amount = amount, @acc_id = account_id
    FROM Transactions
    WHERE transaction_id = @trans_id;

    -- Merr user_id nga account
    SELECT @user_id = user_id
    FROM Accounts
    WHERE account_id = @acc_id;

    -- Rregulli 1: nëse transaksioni > 1000 EUR
    IF @trans_amount > 1000
    BEGIN
        SET @risk_score = @risk_score + 2;
        INSERT INTO Fraud_Alerts(transaction_id, risk_score, severity, created_at)
        VALUES (@trans_id, @risk_score, 'HIGH', GETDATE());
    END

    -- Rregulli 2: nëse user ka risk_level > 5
    DECLARE @user_risk INT;
    SELECT @user_risk = risk_level
    FROM Users
    WHERE user_id = @user_id;

    IF @user_risk > 5
    BEGIN
        SET @risk_score = @risk_score + 1;
        INSERT INTO Fraud_Alerts(transaction_id, risk_score, severity, created_at)
        VALUES (@trans_id, @risk_score, 'MEDIUM', GETDATE());
    END

    -- Shfaq info për verifikim
    SELECT transaction_id, @risk_score AS total_risk_score
    FROM Transactions
    WHERE transaction_id = @trans_id;
END;


EXEC Generate_Fraud_Alert @trans_id = 10;



--Llogarit riskun total për një user bazuar në transaksionet e fundit

CREATE OR ALTER PROCEDURE Calculate_User_Risk
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total_risk INT = 0;

    -- Risk total i transaksioneve të fundit 30 ditë
    SELECT @total_risk = ISNULL(SUM(f.risk_score), 0)
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    LEFT JOIN Fraud_Alerts f ON t.transaction_id = f.transaction_id
    WHERE a.user_id = @user_id
      AND t.transaction_time >= DATEADD(DAY, -30, GETDATE());

    -- Update risk_level te Users
    UPDATE Users
    SET risk_level = @total_risk
    WHERE user_id = @user_id;

    -- Shfaq info
    SELECT user_id, risk_level
    FROM Users
    WHERE user_id = @user_id;
END;


EXEC Calculate_User_Risk @user_id = 5;


--Raporti i transaksioneve të dyshimta për një muaj

CREATE OR ALTER PROCEDURE Monthly_Suspicious_Report
    @month_num INT,
    @year_num INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.transaction_id, u.full_name, t.amount, t.transaction_time, ISNULL(f.risk_score, 0) AS risk_score
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    JOIN Users u ON a.user_id = u.user_id
    LEFT JOIN Fraud_Alerts f ON t.transaction_id = f.transaction_id
    WHERE MONTH(t.transaction_time) = @month_num
      AND YEAR(t.transaction_time) = @year_num
      AND (ISNULL(f.risk_score, 0) > 0 OR t.amount > 1000)
    ORDER BY risk_score DESC, t.amount DESC;
END;


EXEC Monthly_Suspicious_Report @month_num = 2, @year_num = 2026;


--Update ML Score dhe klasifikim

CREATE OR ALTER PROCEDURE Update_ML_Score
    @transaction_id INT,
    @ml_probability DECIMAL(5,2),
    @ml_label NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert prediction në tabelën ML_Predictions
    INSERT INTO ML_Predictions(transaction_id, model_version, probability, label, created_at)
    VALUES (@transaction_id, 'v1.0', @ml_probability, @ml_label, GETDATE());

    -- Update risk_score në Transactions bazuar në ML probability
    DECLARE @risk INT = 0;
    IF @ml_probability >= 0.8 SET @risk = 3;
    ELSE IF @ml_probability >= 0.5 SET @risk = 2;
    ELSE IF @ml_probability >= 0.3 SET @risk = 1;

    UPDATE Transactions
    SET ml_score = @ml_probability, risk_score = @risk
    WHERE transaction_id = @transaction_id;

    -- Kthe info për verifikim
    SELECT transaction_id, ml_score, risk_score, @ml_label AS ml_label
    FROM Transactions
    WHERE transaction_id = @transaction_id;
END;


EXEC Update_ML_Score @transaction_id = 101, @ml_probability = 0.85, @ml_label = 'FRAUD';


--Update Behavior Profile pas transaksioni

CREATE OR ALTER PROCEDURE Update_Behavior_Profile
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @avg_amount DECIMAL(18,2);
    DECLARE @daily_tx DECIMAL(5,2);
    DECLARE @common_country NVARCHAR(50);
    DECLARE @usual_hour INT;
    DECLARE @risk_pattern INT = 0;

    -- Merr statistikat e fundit
    SELECT @avg_amount = AVG(amount)
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id;

    SELECT @daily_tx = AVG(daily_count) 
    FROM (
        SELECT CAST(transaction_time AS DATE) AS tx_date, COUNT(*) AS daily_count
        FROM Transactions t
        JOIN Accounts a ON t.account_id = a.account_id
        WHERE a.user_id = @user_id
        GROUP BY CAST(transaction_time AS DATE)
    ) AS daily_stats;

    SELECT TOP 1 @common_country = geo_location
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id
    GROUP BY geo_location
    ORDER BY COUNT(*) DESC;

    SELECT TOP 1 @usual_hour = DATEPART(HOUR, transaction_time)
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    WHERE a.user_id = @user_id
    GROUP BY DATEPART(HOUR, transaction_time)
    ORDER BY COUNT(*) DESC;

    -- Risk pattern shembull: shumë transaksione mbi mesatare
    IF @avg_amount > 1000 OR @daily_tx > 5
        SET @risk_pattern = 2;

    -- Update ose insert
    IF EXISTS (SELECT 1 FROM Behavior_Profile WHERE user_id = @user_id)
        UPDATE Behavior_Profile
        SET avg_transaction_amount = @avg_amount,
            avg_daily_transactions = @daily_tx,
            common_country = @common_country,
            usual_login_hour = @usual_hour,
            risk_pattern_score = @risk_pattern,
            last_updated = GETDATE()
        WHERE user_id = @user_id;
    ELSE
        INSERT INTO Behavior_Profile(user_id, avg_transaction_amount, avg_daily_transactions, common_country, usual_login_hour, risk_pattern_score, last_updated)
        VALUES (@user_id, @avg_amount, @daily_tx, @common_country, @usual_hour, @risk_pattern, GETDATE());

    -- Shfaq info
    SELECT * FROM Behavior_Profile WHERE user_id = @user_id;
END;

EXEC Update_Behavior_Profile @user_id = 5;


--Kontroll Auto-Whitelist / Blacklist

CREATE OR ALTER PROCEDURE Check_Whitelist_Blacklist
    @user_id INT,
    @merchant_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @is_blacklisted BIT = 0;
    DECLARE @is_whitelisted BIT = 0;

    -- Kontroll blacklist
    IF EXISTS (SELECT 1 FROM Blacklist WHERE (type='USER' AND value=CAST(@user_id AS NVARCHAR)) 
               OR (type='MERCHANT' AND value=CAST(@merchant_id AS NVARCHAR)))
        SET @is_blacklisted = 1;

    -- Kontroll whitelist
    IF EXISTS (SELECT 1 FROM Whitelist WHERE user_id=@user_id OR merchant_id=@merchant_id)
        SET @is_whitelisted = 1;

    SELECT @is_blacklisted AS Blacklisted, @is_whitelisted AS Whitelisted;
END;

EXEC Check_Whitelist_Blacklist @user_id = 5, @merchant_id = 10;



--Auto-blocking për rrezik të lartë

CREATE OR ALTER PROCEDURE Auto_Block_High_Risk
    @transaction_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @risk_score INT;
    DECLARE @acc_id INT;

    SELECT @risk_score = risk_score, @acc_id = account_id
    FROM Transactions
    WHERE transaction_id = @transaction_id;

    IF @risk_score >= 3
    BEGIN
        -- Blloko account
        UPDATE Accounts
        SET status = 'BLOCKED'
        WHERE account_id = @acc_id;

        -- Insert alert
        INSERT INTO Fraud_Alerts(transaction_id, risk_score, severity, created_at)
        VALUES (@transaction_id, @risk_score, 'CRITICAL', GETDATE());
    END

    SELECT @transaction_id AS transaction_id, @risk_score AS risk_score, 
           (SELECT status FROM Accounts WHERE account_id = @acc_id) AS account_status;
END;


EXEC Auto_Block_High_Risk @transaction_id = 101;

                               --views/index

 


CREATE INDEX idx_transactions_time
ON Transactions(transaction_time);


SELECT *
FROM Transactions
WHERE transaction_time >= DATEADD(DAY, -7, GETDATE());


CREATE INDEX idx_transactions_risk
ON Transactions(risk_score);

SELECT *
FROM Transactions
WHERE risk_score >= 3
ORDER BY risk_score DESC;


 


-- Fraud Alerts
CREATE INDEX idx_alerts_transaction
ON Fraud_Alerts(transaction_id);

SELECT *
FROM Fraud_Alerts
WHERE transaction_id = 101;


-- Behavior Profile
CREATE INDEX idx_behavior_user
ON Behavior_Profile(user_id);

SELECT *
FROM Behavior_Profile
WHERE user_id = 5;


-- Merchants
CREATE INDEX idx_merchants_risk
ON Merchants(risk_score);

SELECT merchant_name, risk_score
FROM Merchants
WHERE risk_score > 3
ORDER BY risk_score DESC;


                                        --trigger

  

 
-- Kontrollo nëse trigger ekziston dhe fshihet


-- Tani krijo trigger-in nga fillimi
CREATE TRIGGER trg_AfterTransactionInsert
ON Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @trans_id INT;
    DECLARE @amount DECIMAL(18,2);
    DECLARE @rule_id INT;
    DECLARE @threshold DECIMAL(18,2);

    SELECT @trans_id = transaction_id, @amount = amount
    FROM inserted;

    SELECT TOP 1 @rule_id = rule_id, @threshold = threshold_value
    FROM Fraud_Rules
    WHERE active = 1 AND rule_name = 'High Transaction Amount';

    IF @amount > @threshold
    BEGIN
        INSERT INTO Fraud_Alerts(transaction_id, rule_id, risk_score, severity)
        VALUES (@trans_id, @rule_id, 100, 'HIGH');
    END
END
GO

-- prova
-- Shto një rregull për transaksione të mëdha

INSERT INTO Fraud_Rules(rule_name, description, threshold_value, weight, active)
VALUES ('High Transaction Amount', 'Alert për transaksione të mëdha', 1000, 2, 1);
GO


SELECT alert_id, transaction_id, rule_id, risk_score, severity, created_at
FROM Fraud_Alerts
ORDER BY created_at DESC;
GO


--Update risk_level përdoruesi pas alert

CREATE TRIGGER trg_AfterFraudAlertInsert
ON Fraud_Alerts
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @user_id INT;
    DECLARE @trans_id INT;

    SELECT @trans_id = transaction_id FROM inserted;

    -- Merr user_id nga transaksioni
    SELECT @user_id = a.user_id
    FROM Transactions t
    JOIN Accounts a ON t.account_id = a.account_id
    WHERE t.transaction_id = @trans_id;

    -- Rrit risk_level me 10 për çdo alert
    UPDATE Users
    SET risk_level = risk_level + 10,
        updated_at = GETDATE()
    WHERE user_id = @user_id;
END
GO

-- Shiko risk_level para
SELECT user_id, full_name, risk_level FROM Users WHERE user_id = 1;

-- Shto një alert manual për test
INSERT INTO Fraud_Alerts(transaction_id, rule_id, risk_score)
VALUES (1, 1, 100);

-- Shiko risk_level pas
SELECT user_id, full_name, risk_level FROM Users WHERE user_id = 1;


--Auto update last_seen në Devices

CREATE TRIGGER trg_AfterLoginInsert
ON Login_History
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Devices
    SET last_seen = GETDATE()
    FROM Devices d
    JOIN inserted i ON d.device_id = i.device_id
    WHERE i.device_id IS NOT NULL;
END
GO

-- Shiko last_seen para
SELECT device_id, last_seen FROM Devices WHERE device_id = 1;

-- Shto login
INSERT INTO Login_History(user_id, device_id, ip_address)
VALUES (1, 1, '192.168.1.10');

-- Shiko last_seen pas
SELECT device_id, last_seen FROM Devices WHERE device_id = 1;


--Auto insert në Audit_Logs për update në Accounts

CREATE TRIGGER trg_AfterAccountsUpdate
ON Accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit_Logs(table_name, record_id, action, old_value, new_value, changed_by, changed_at)
    SELECT 
        'Accounts',
        d.account_id,
        'UPDATE',
        CONCAT('balance=', d.balance, ', status=', d.status),
        CONCAT('balance=', i.balance, ', status=', i.status),
        i.user_id,
        GETDATE()
    FROM deleted d
    JOIN inserted i ON d.account_id = i.account_id
    WHERE d.balance <> i.balance OR d.status <> i.status;
END
GO

-- Shiko Audit Logs para
SELECT * FROM Audit_Logs WHERE table_name = 'Accounts';

-- Përditëso balancen
UPDATE Accounts
SET balance = balance + 500
WHERE account_id = 1;

-- Shiko Audit Logs pas
SELECT * FROM Audit_Logs WHERE table_name = 'Accounts';


