CREATE TABLE Fraud_Alerts (
    alert_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT NOT NULL,
    rule_id INT NULL,
    risk_score INT DEFAULT 0,
    severity VARCHAR(20) DEFAULT 'MEDIUM',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved BIT DEFAULT 0,
    analyst_id INT NULL,
    CONSTRAINT FK_FraudAlerts_Transaction FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    CONSTRAINT FK_FraudAlerts_Rule FOREIGN KEY (rule_id) REFERENCES Fraud_Rules(rule_id),
    CONSTRAINT FK_FraudAlerts_Analyst FOREIGN KEY (analyst_id) REFERENCES Users(user_id)
);
 



select *
from Fraud_Alerts


-- =========================================
-- MBUSHJA E Fraud_Alerts me 8000 rreshta
-- Ruaj referential integrity me Transactions, Fraud_Rules, Users
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 8000;

DECLARE @transaction_id INT;
DECLARE @rule_id INT;
DECLARE @risk_score INT;
DECLARE @severity VARCHAR(20);
DECLARE @created_at DATETIME;
DECLARE @resolved BIT;
DECLARE @analyst_id INT;

-- Lista e severities
DECLARE @severities TABLE (name VARCHAR(20));
INSERT INTO @severities VALUES ('LOW'),('MEDIUM'),('HIGH'),('CRITICAL');

WHILE @counter <= @total_inserts
BEGIN
    -- Zgjidh transaction ekzistuese
    SELECT TOP 1 @transaction_id = transaction_id 
    FROM Transactions 
    ORDER BY NEWID();

    -- 20% e rasteve lidhen me rule + analyst ekzistues
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 20
    BEGIN
        SELECT TOP 1 @rule_id = rule_id FROM Fraud_Rules ORDER BY NEWID();
        SELECT TOP 1 @analyst_id = user_id FROM Users ORDER BY NEWID();
    END
    ELSE
    BEGIN
        -- 80% rastësor: mund të mos ketë analyst ose rule
        SELECT TOP 1 @rule_id = rule_id FROM Fraud_Rules ORDER BY NEWID();
        SET @analyst_id = NULL;
    END

    -- risk_score 0-100
    SET @risk_score = CAST(RAND(CHECKSUM(NEWID()))*101 AS INT);

    -- severity rastësore
    SELECT TOP 1 @severity = name FROM @severities ORDER BY NEWID();

    -- resolved 70% false, 30% true
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 30
        SET @resolved = 1;
    ELSE
        SET @resolved = 0;

    -- created_at brenda 2 viteve të fundit
    SET @created_at = DATEADD(MINUTE, CAST(RAND(CHECKSUM(NEWID()))*60*24*730 AS INT), DATEADD(DAY, -730, GETDATE()));

    -- Insert
    INSERT INTO Fraud_Alerts (transaction_id, rule_id, risk_score, severity, created_at, resolved, analyst_id)
    VALUES (@transaction_id, @rule_id, @risk_score, @severity, @created_at, @resolved, @analyst_id);

    -- Progres çdo 1000 alerts
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' fraud alerts.';
