CREATE TABLE Devices (
    device_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    device_fingerprint VARCHAR(100) UNIQUE,
    os VARCHAR(50),
    browser VARCHAR(50),
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    trusted BIT DEFAULT 0,
    CONSTRAINT FK_Devices_User FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

select *
from Devices


-- =========================================
-- MBUSHJA E Devices me 5000 rreshta
-- 20% user_id të përbashkët me User_Roles për realism
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 5000;
DECLARE @user_id INT;
DECLARE @device_fingerprint VARCHAR(100);
DECLARE @os VARCHAR(50);
DECLARE @browser VARCHAR(50);
DECLARE @first_seen DATETIME;
DECLARE @last_seen DATETIME;
DECLARE @trusted BIT;

-- Arrays për OS dhe Browser
DECLARE @os_list TABLE (name VARCHAR(50));
INSERT INTO @os_list VALUES ('Windows 10'),('Windows 11'),('macOS'),('Linux'),('iOS'),('Android');

DECLARE @browser_list TABLE (name VARCHAR(50));
INSERT INTO @browser_list VALUES ('Chrome'),('Firefox'),('Edge'),('Safari'),('Opera');

WHILE @counter <= @total_inserts
BEGIN
    -- 20% të device lidhen me user_id që ka role në User_Roles
    IF CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT) < 20
        SELECT TOP 1 @user_id = user_id FROM User_Roles ORDER BY NEWID();
    ELSE
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();

    -- Gjenero device_fingerprint unik
    SET @device_fingerprint = 'DEV-' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(15)) + '-' + CAST(@counter AS VARCHAR(5));

    -- Zgjidh OS random
    SELECT TOP 1 @os = name FROM @os_list ORDER BY NEWID();

    -- Zgjidh Browser random
    SELECT TOP 1 @browser = name FROM @browser_list ORDER BY NEWID();

    -- first_seen dhe last_seen: rastësor brenda 2 viteve të fundit
    SET @first_seen = DATEADD(DAY, -CAST(RAND(CHECKSUM(NEWID()))*730 AS INT), GETDATE());
    SET @last_seen = DATEADD(DAY, CAST(RAND(CHECKSUM(NEWID()))*30 AS INT), @first_seen);

    -- trusted: 70% chance të jetë 1
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 70
        SET @trusted = 1;
    ELSE
        SET @trusted = 0;

    -- Insert në Devices
    INSERT INTO Devices (user_id, device_fingerprint, os, browser, first_seen, last_seen, trusted)
    VALUES (@user_id, @device_fingerprint, @os, @browser, @first_seen, @last_seen, @trusted);

    -- Progres çdo 500 device
    IF @counter % 500 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END;

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' device.';
