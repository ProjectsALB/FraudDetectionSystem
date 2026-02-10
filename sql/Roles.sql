CREATE TABLE Roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

select *
from Roles

DECLARE @counter INT = 1;
DECLARE @role_name VARCHAR(50);

WHILE @counter <= 10000
BEGIN
    -- Gjeneroj role të rastësishme
    DECLARE @rand_type INT = CAST(RAND(CHECKSUM(NEWID())) * 6 AS INT);
    IF @rand_type = 0
        SET @role_name = 'Admin_' + CAST(@counter AS VARCHAR(10));
    ELSE IF @rand_type = 1
        SET @role_name = 'User_' + CAST(@counter AS VARCHAR(10));
    ELSE IF @rand_type = 2
        SET @role_name = 'Manager_' + CAST(@counter AS VARCHAR(10));
    ELSE IF @rand_type = 3
        SET @role_name = 'Analyst_' + CAST(@counter AS VARCHAR(10));
    ELSE IF @rand_type = 4
        SET @role_name = 'Operator_' + CAST(@counter AS VARCHAR(10));
    ELSE
        SET @role_name = 'Supervisor_' + CAST(@counter AS VARCHAR(10));
    
    -- Insert në tabelë
    INSERT INTO Roles (role_name)
    VALUES (@role_name);
    
    -- Shfaq progresin çdo 1000 role
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / 10000';
    
    SET @counter = @counter + 1;
END;

PRINT 'Procesi përfundoi! Janë insertuar 10000 role.';

