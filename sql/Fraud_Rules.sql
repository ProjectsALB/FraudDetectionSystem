select *
from Fraud_Rules
-- =========================================
-- MBUSHJA E Fraud_Rules me 9000 rreshta
-- Ruaj realism dhe përputhshmëri me Fraud_Alerts
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_rules INT = 9000;

DECLARE @rule_name VARCHAR(100);
DECLARE @description VARCHAR(255);
DECLARE @threshold_value DECIMAL(18,2);
DECLARE @weight INT;
DECLARE @active BIT;

WHILE @counter <= @total_rules
BEGIN
    -- Gjenero emër rregulli unik
    SET @rule_name = 'Rule_' + CAST(@counter AS VARCHAR(10));

    -- Përshkrim i rastësishëm
    SET @description = 'Fraud detection rule for pattern ' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR);

    -- Threshold: 10 - 10000 (shumëllojshmëri për realism)
    SET @threshold_value = CAST(RAND(CHECKSUM(NEWID()))*9990 + 10 AS DECIMAL(18,2));

    -- Weight 1-5
    SET @weight = CAST(RAND(CHECKSUM(NEWID()))*5 + 1 AS INT);

    -- Active 90% true, 10% false
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 90
        SET @active = 1;
    ELSE
        SET @active = 0;

    -- Insert
    INSERT INTO Fraud_Rules (rule_name, description, threshold_value, weight, active)
    VALUES (@rule_name, @description, @threshold_value, @weight, @active);

    -- Progres çdo 500
    IF @counter % 500 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_rules AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_rules AS VARCHAR) + ' fraud rules.';

select *
from Fraud_Rules