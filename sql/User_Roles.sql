CREATE TABLE User_Roles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    CONSTRAINT FK_UserRoles_User FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT FK_UserRoles_Role FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);


select *
from User_Roles

-- =========================================
-- MBUSHJA E User_Roles me 15000 rreshta
-- 20% user_id ose role_id të njëjta me tabelat ekzistuese
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_inserts INT = 15000;
DECLARE @user_id INT;
DECLARE @role_id INT;

WHILE @counter <= @total_inserts
BEGIN
    -- 20% të rasteve përdorin user_id ekzistues nga tabela Users
    IF CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT) < 20
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID();
    ELSE
        SELECT TOP 1 @user_id = user_id FROM Users ORDER BY NEWID(); -- 80% edhe random nga users ekzistues

    -- 20% të rasteve përdorin role_id ekzistues nga tabela Roles
    IF CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT) < 20
        SELECT TOP 1 @role_id = role_id FROM Roles ORDER BY NEWID();
    ELSE
        SELECT TOP 1 @role_id = role_id FROM Roles ORDER BY NEWID(); -- 80% rastësor nga role ekzistues

    -- Insert në tabelë
    INSERT INTO User_Roles (user_id, role_id)
    VALUES (@user_id, @role_id);

    -- Shfaq progresin çdo 1000 regjistrime
    IF @counter % 1000 = 0
        PRINT 'Insertuar ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_inserts AS VARCHAR);

    SET @counter = @counter + 1;
END;

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_inserts AS VARCHAR) + ' rreshta në User_Roles.';
