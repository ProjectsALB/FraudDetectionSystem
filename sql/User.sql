CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    country VARCHAR(50),
    kyc_status BIT DEFAULT 0,
    risk_level INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL
);
select *
from Users


DECLARE @counter INT = 1;
DECLARE @first_name VARCHAR(50);
DECLARE @last_name VARCHAR(50);
DECLARE @full_name VARCHAR(100);
DECLARE @email VARCHAR(100);
DECLARE @phone VARCHAR(20);
DECLARE @date_of_birth DATE;
DECLARE @country VARCHAR(50);
DECLARE @kyc_status BIT;
DECLARE @risk_level INT;

-- Lista e emrave realë
DECLARE @first_names TABLE (id INT IDENTITY, name VARCHAR(50));
INSERT INTO @first_names (name) VALUES
('Agim'),('Arta'),('Besnik'),('Drita'),('Elton'),('Fatos'),('Gent'),('Hana'),('Ilir'),('Jon'),
('Krenar'),('Liridona'),('Migjen'),('Nora'),('Olti'),('Pranvera'),('Qendrim'),('Rina'),('Shkumbin'),('Teuta'),
('Uran'),('Valon'),('Ylli'),('Zana'),('Adriatik'),('Blerina'),('Drilon'),('Era'),('Flamur'),('Granit'),
('Hekuran'),('Ibrahim'),('Jeta'),('Kushtrim'),('Leotrim'),('Mimoza'),('Nderim'),('Orges'),('Petrit'),('Qamil'),
('Rrezart'),('Sabri'),('Trim'),('Urim'),('Vjosa'),('Xhemail'),('Yll'),('Zamir'),('Altin'),('Blerim'),
('Donika'),('Edona'),('Fitim'),('Genta'),('Hysni'),('Indrit'),('Jeton'),('Klea'),('Luan'),('Mergim'),
('Naim'),('Olsi'),('Pajtim'),('Rigon'),('Shprese'),('Tringa'),('Valmir'),('Xhevat'),('Ylber'),('Zef');

-- Lista e mbiemrave realë
DECLARE @last_names TABLE (id INT IDENTITY, surname VARCHAR(50));
INSERT INTO @last_names (surname) VALUES
('Krasniqi'),('Berisha'),('Hoxha'),('Shala'),('Pllana'),('Morina'),('Gashi'),('Dedaj'),('Rexha'),('Kadriu'),
('Bytyqi'),('Thaçi'),('Basha'),('Mehmeti'),('Kryeziu'),('Gjoka'),('Mustafa'),('Kastrati'),('Rrahmani'),('Hoti'),
('Pajaziti'),('Kamberi'),('Sahiti'),('Kuka'),('Leka'),('Hyseni'),('Maloku'),('Rama'),('Maliqi'),('Beka'),
('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),('Rodriguez'),('Martinez'),
('Hernandez'),('Lopez'),('Gonzalez'),('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin');

-- Lista e vendeve
DECLARE @countries TABLE (id INT IDENTITY, country VARCHAR(50));
INSERT INTO @countries (country) VALUES
('Kosove'),('Shqipëri'),('USA'),('UK'),('Germany'),('Italy'),('France'),('Spain'),('Switzerland'),('Netherlands');

-- Domenet e email
DECLARE @domains TABLE (id INT IDENTITY, domain VARCHAR(50));
INSERT INTO @domains (domain) VALUES
('gmail.com'),('hotmail.com'),('yahoo.com'),('outlook.com'),('icloud.com'),('live.com'),('protonmail.com'),('aol.com');

-- Prefix për numrat e telefonit
DECLARE @prefixes TABLE (country VARCHAR(50), prefix VARCHAR(10));
INSERT INTO @prefixes VALUES
('Kosove','+38349'),('Shqipëri','+35569'),('USA','+1201'),('UK','+4479'),
('Germany','+4915'),('Italy','+3933'),('France','+336'),('Spain','+346'),
('Switzerland','+4176'),('Netherlands','+316');

WHILE @counter <= 10000
BEGIN
    -- Zgjidh random emrin
    SELECT TOP 1 @first_name = name FROM @first_names ORDER BY NEWID();
    
    -- Zgjidh random mbiemrin
    SELECT TOP 1 @last_name = surname FROM @last_names ORDER BY NEWID();
    
    -- Zgjidh random vendin
    SELECT TOP 1 @country = country FROM @countries ORDER BY NEWID();
    
    -- Krijo full name
    SET @full_name = @first_name + ' ' + @last_name;
    
    -- Krijo email unik
    DECLARE @domain VARCHAR(50);
    SELECT TOP 1 @domain = domain FROM @domains ORDER BY NEWID();
    
    -- Krijo variante të ndryshme email për ta bërë unik
    DECLARE @email_suffix INT = @counter % 4;
    IF @email_suffix = 0
        SET @email = LOWER(@first_name) + '.' + LOWER(@last_name) + CAST(@counter AS VARCHAR(10)) + '@' + @domain;
    ELSE IF @email_suffix = 1
        SET @email = LOWER(LEFT(@first_name, 1)) + LOWER(@last_name) + CAST(@counter AS VARCHAR(10)) + '@' + @domain;
    ELSE IF @email_suffix = 2
        SET @email = LOWER(@first_name) + '_' + LOWER(@last_name) + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '@' + @domain;
    ELSE
        SET @email = LOWER(@first_name) + CAST(@counter % 1000 AS VARCHAR(10)) + '@' + @domain;
    
    -- Krijo numrin e telefonit
    DECLARE @phone_prefix VARCHAR(10);
    SELECT @phone_prefix = prefix FROM @prefixes WHERE country = @country;
    IF @phone_prefix IS NULL
        SELECT TOP 1 @phone_prefix = prefix FROM @prefixes ORDER BY NEWID();
    
    SET @phone = @phone_prefix + 
                 RIGHT('0000000' + CAST(CAST(RAND(CHECKSUM(NEWID())) * 10000000 AS INT) AS VARCHAR(10)), 7);
    
    -- Krijo datën e lindjes (18-65 vjeç)
    SET @date_of_birth = DATEADD(YEAR, -1 * (18 + CAST(RAND(CHECKSUM(NEWID())) * 47 AS INT)), 
                                DATEADD(DAY, CAST(RAND(CHECKSUM(NEWID())) * 365 AS INT), GETDATE()));
    
    -- Krijo KYC status (70% kanë KYC të bërë)
    IF CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT) < 70
        SET @kyc_status = 1;
    ELSE
        SET @kyc_status = 0;
    
    -- Krijo risk level (shpërndarje realiste)
    DECLARE @rand_risk INT = CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT);
    IF @rand_risk < 60
        SET @risk_level = 0; -- Low risk: 60%
    ELSE IF @rand_risk < 85
        SET @risk_level = 1; -- Medium-Low: 25%
    ELSE IF @rand_risk < 95
        SET @risk_level = 2; -- Medium: 10%
    ELSE IF @rand_risk < 98
        SET @risk_level = 3; -- Medium-High: 3%
    ELSE
        SET @risk_level = 4; -- High risk: 2%
    
    -- Insert në tabelë
    INSERT INTO Users (full_name, email, phone, date_of_birth, country, kyc_status, risk_level)
    VALUES (@full_name, @email, @phone, @date_of_birth, @country, @kyc_status, @risk_level);
    
    -- Shfaq progresin çdo 1000 regjistrime
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / 10000';
    
    SET @counter = @counter + 1;
END;

PRINT 'Procesi përfundoi! Janë insertuar 10000 regjistrime.';