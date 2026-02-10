CREATE TABLE Audit_Logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_value NVARCHAR(MAX) NULL,
    new_value NVARCHAR(MAX) NULL,
    changed_by INT NULL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_AuditLogs_User FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

select *
from Audit_Logs
-- =========================================
-- MBUSHJA E Audit_Logs me 9000 rreshta
-- Ruaj realism dhe përputhshmëri me Users dhe tabelat e tjera
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_logs INT = 9000;

DECLARE @table_name VARCHAR(50);
DECLARE @record_id INT;
DECLARE @action VARCHAR(20);
DECLARE @old_value NVARCHAR(MAX);
DECLARE @new_value NVARCHAR(MAX);
DECLARE @changed_by INT;

WHILE @counter <= @total_logs
BEGIN
    -- Zgjidh rastësisht tabelën ku do të ndodhë ndryshimi
    DECLARE @rand_table INT = CAST(RAND(CHECKSUM(NEWID()))*7 AS INT);

    IF @rand_table = 0 SET @table_name = 'Users';
    ELSE IF @rand_table = 1 SET @table_name = 'Accounts';
    ELSE IF @rand_table = 2 SET @table_name = 'Transactions';
    ELSE IF @rand_table = 3 SET @table_name = 'Devices';
    ELSE IF @rand_table = 4 SET @table_name = 'Login_History';
    ELSE IF @rand_table = 5 SET @table_name = 'Merchants';
    ELSE SET @table_name = 'Fraud_Alerts';

    -- Zgjidh record_id valid nga tabela përputhëse
    IF @table_name = 'Users'
        SELECT TOP 1 @record_id = user_id FROM Users ORDER BY NEWID();
    ELSE IF @table_name = 'Accounts'
        SELECT TOP 1 @record_id = account_id FROM Accounts ORDER BY NEWID();
    ELSE IF @table_name = 'Transactions'
        SELECT TOP 1 @record_id = transaction_id FROM Transactions ORDER BY NEWID();
    ELSE IF @table_name = 'Devices'
        SELECT TOP 1 @record_id = device_id FROM Devices ORDER BY NEWID();
    ELSE IF @table_name = 'Login_History'
        SELECT TOP 1 @record_id = login_id FROM Login_History ORDER BY NEWID();
    ELSE IF @table_name = 'Merchants'
        SELECT TOP 1 @record_id = merchant_id FROM Merchants ORDER BY NEWID();
    ELSE IF @table_name = 'Fraud_Alerts'
        SELECT TOP 1 @record_id = alert_id FROM Fraud_Alerts ORDER BY NEWID();

    -- Zgjidh një user rastësisht si changed_by
    SELECT TOP 1 @changed_by = user_id FROM Users ORDER BY NEWID();

    -- Zgjidh rastësisht action
    DECLARE @rand_action INT = CAST(RAND(CHECKSUM(NEWID()))*3 AS INT);
    IF @rand_action = 0 SET @action = 'INSERT';
    ELSE IF @rand_action = 1 SET @action = 'UPDATE';
    ELSE SET @action = 'DELETE';

    -- Gjenero old_value dhe new_value si tekst të rastësishëm për realism
    SET @old_value = 'Old value sample ' + CAST(CHECKSUM(NEWID()) % 1000 AS NVARCHAR(10));
    SET @new_value = 'New value sample ' + CAST(CHECKSUM(NEWID()) % 1000 AS NVARCHAR(10));

    -- Insert në tabelë
    INSERT INTO Audit_Logs (table_name, record_id, action, old_value, new_value, changed_by)
    VALUES (@table_name, @record_id, @action, @old_value, @new_value, @changed_by);

    -- Progres çdo 1000 rreshta
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_logs AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_logs AS VARCHAR) + ' rreshta në Audit_Logs.';
