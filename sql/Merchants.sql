CREATE TABLE Merchants (
    merchant_id INT IDENTITY(1,1) PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    country VARCHAR(50),
    risk_score INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

select *
from Merchants

-- =========================================
-- MBUSHJA E Merchants me 5000 rreshta
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_merchants INT = 5000;
DECLARE @merchant_name VARCHAR(100);
DECLARE @category VARCHAR(50);
DECLARE @country VARCHAR(50);
DECLARE @risk_score INT;
DECLARE @created_at DATETIME;

-- Lista e kategorive të merchant
DECLARE @categories TABLE (name VARCHAR(50));
INSERT INTO @categories VALUES
('Electronics'),('Clothing'),('Groceries'),('Restaurants'),('Travel'),('Healthcare'),
('Automotive'),('Education'),('Entertainment'),('Sports'),('Beauty'),('Furniture');

-- Lista e vendeve
DECLARE @countries TABLE (name VARCHAR(50));
INSERT INTO @countries VALUES
('Kosove'),('Shqipëri'),('USA'),('UK'),('Germany'),('Italy'),('France'),('Spain'),('Switzerland'),('Netherlands');

WHILE @counter <= @total_merchants
BEGIN
    -- Gjenero merchant_name unik
    SET @merchant_name = 'Merchant_' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)) + '_' + CAST(@counter AS VARCHAR(5));

    -- Zgjidh kategori rastësore
    SELECT TOP 1 @category = name FROM @categories ORDER BY NEWID();

    -- Zgjidh vend rastësor
    SELECT TOP 1 @country = name FROM @countries ORDER BY NEWID();

    -- Risk score 0-100
    SET @risk_score = CAST(RAND(CHECKSUM(NEWID()))*101 AS INT);

    -- created_at brenda 3 viteve të fundit
    SET @created_at = DATEADD(DAY, -CAST(RAND(CHECKSUM(NEWID()))*1095 AS INT), GETDATE());

    -- Insert
    INSERT INTO Merchants (merchant_name, category, country, risk_score, created_at)
    VALUES (@merchant_name, @category, @country, @risk_score, @created_at);

    -- Progres çdo 500
    IF @counter % 500 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_merchants AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_merchants AS VARCHAR) + ' merchants.';
