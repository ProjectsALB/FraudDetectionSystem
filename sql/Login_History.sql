CREATE TABLE Login_History (
    login_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    device_id INT NULL,
    ip_address VARCHAR(45),
    geo_lat DECIMAL(10,6),
    geo_long DECIMAL(10,6),
    country VARCHAR(50),
    city VARCHAR(50),
    login_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    success BIT DEFAULT 1,
    CONSTRAINT FK_LoginHistory_User FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT FK_LoginHistory_Device FOREIGN KEY (device_id) REFERENCES Devices(device_id)
);

select *
from Login_History
-- =========================================
-- MBUSHJA E Login_History me 20000 rreshta
-- 20% user_id + device_id të përbashkët për realism
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 20000;
DECLARE @user_id INT;
DECLARE @device_id INT;
DECLARE @ip_address VARCHAR(45);
DECLARE @geo_lat DECIMAL(10,6);
DECLARE @geo_long DECIMAL(10,6);
DECLARE @country VARCHAR(50);
DECLARE @city VARCHAR(50);
DECLARE @login_time DATETIME;
DECLARE @success BIT;

-- Lista e vendeve dhe qyteteve
DECLARE @locations TABLE (country VARCHAR(50), city VARCHAR(50));
INSERT INTO @locations VALUES
('Kosove','Prishtine'),('Kosove','Gjakove'),('Kosove','Peje'),
('Shqipëri','Tirane'),('Shqipëri','Durres'),('Shqipëri','Vlore'),
('USA','New York'),('USA','Los Angeles'),('USA','Chicago'),
('UK','London'),('UK','Manchester'),('UK','Liverpool'),
('Germany','Berlin'),('Germany','Munich'),('Germany','Hamburg');

WHILE @counter <= @total_inserts
BEGIN
    -- 20% user + device të përbashkët nga Devices për realism
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 20
    BEGIN
        SELECT TOP 1 @user_id = user_id, @device_id = device_id 
        FROM Devices ORDER BY NEWID();
    END
    ELSE
    BEGIN
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();
        
        -- 70% mund të lidhet me device të këtij user, 30% NULL
        IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 70
            SELECT TOP 1 @device_id = device_id FROM Devices WHERE user_id = @user_id ORDER BY NEWID();
        ELSE
            SET @device_id = NULL;
    END

    -- IP address random
    SET @ip_address = CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR) + '.' +
                      CAST(CAST(RAND(CHECKSUM(NEWID()))*255 AS INT) AS VARCHAR);

    -- Lokacion rastësor
    SELECT TOP 1 @country = country, @city = city FROM @locations ORDER BY NEWID();

    -- Koha e login: 2 vite prapa + rastësore orë
    SET @login_time = DATEADD(MINUTE, CAST(RAND(CHECKSUM(NEWID()))*60*24*730 AS INT), DATEADD(DAY, -730, GETDATE()));

    -- Success: 85% chance të jetë 1
    IF CAST(RAND(CHECKSUM(NEWID()))*100 AS INT) < 85
        SET @success = 1;
    ELSE
        SET @success = 0;

    -- Insert
    INSERT INTO Login_History (user_id, device_id, ip_address, geo_lat, geo_long, country, city, login_time, success)
    VALUES (
        @user_id,
        @device_id,
        @ip_address,
        CAST(RAND(CHECKSUM(NEWID()))*180-90 AS DECIMAL(10,6)), -- geo_lat: -90 deri 90
        CAST(RAND(CHECKSUM(NEWID()))*360-180 AS DECIMAL(10,6)), -- geo_long: -180 deri 180
        @country,
        @city,
        @login_time,
        @success
    );

    -- Progres çdo 1000 login
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' login records.';
