CREATE TABLE ML_Predictions (
    prediction_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT NOT NULL,
    model_version VARCHAR(20) NULL,
    probability DECIMAL(5,2) NULL,
    label VARCHAR(20) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_MLPredictions_Transaction FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

select *
from ML_Predictions

-- =========================================
-- MBUSHJA E ML_Predictions me 9000 rreshta
-- Ruaj realism dhe përputhshmëri me Transactions
-- =========================================

DECLARE @counter INT = 1;
DECLARE @total_predictions INT = 9000;

DECLARE @transaction_id INT;
DECLARE @model_version VARCHAR(20);
DECLARE @probability DECIMAL(5,2);
DECLARE @label VARCHAR(20);

WHILE @counter <= @total_predictions
BEGIN
    -- Zgjidh rastësisht një transaction ekzistuese
    SELECT TOP 1 @transaction_id = transaction_id
    FROM Transactions
    ORDER BY NEWID();

    -- Zgjidh model_version rastësisht
    DECLARE @rand_model INT = CAST(RAND(CHECKSUM(NEWID()))*3 AS INT);
    IF @rand_model = 0 SET @model_version = 'v1.0';
    ELSE IF @rand_model = 1 SET @model_version = 'v1.1';
    ELSE SET @model_version = 'v2.0';

    -- Gjenero probabilitet midis 0 dhe 1 (0-100%)
    SET @probability = CAST(RAND(CHECKSUM(NEWID()))*100 AS DECIMAL(5,2));

    -- Gjenero label bazuar në probabilitet
    IF @probability >= 70
        SET @label = 'FRAUD';
    ELSE
        SET @label = 'LEGIT';

    -- Insert në tabelë
    INSERT INTO ML_Predictions (transaction_id, model_version, probability, label)
    VALUES (@transaction_id, @model_version, @probability, @label);

    -- Progres çdo 1000 rreshta
    IF @counter % 1000 = 0
        PRINT 'Insertuar: ' + CAST(@counter AS VARCHAR) + ' / ' + CAST(@total_predictions AS VARCHAR);

    SET @counter = @counter + 1;
END

PRINT 'Procesi përfundoi! Janë insertuar ' + CAST(@total_predictions AS VARCHAR) + ' rreshta në ML_Predictions.';
