-- VM2-SQL: Create all tables for PharmaCare pharmacy database
-- Run as: sqlcmd -S VM2-SQL -d PharmacyDB -E -i 02_CreateTables.sql

USE PharmacyDB;
GO

-- ============================================================
-- MEDICATIONS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Medications')
BEGIN
    CREATE TABLE Medications (
        Id                   INT IDENTITY(1,1) PRIMARY KEY,
        Name                 NVARCHAR(200)  NOT NULL,
        GenericName          NVARCHAR(200)  NOT NULL DEFAULT '',
        Category             NVARCHAR(100)  NOT NULL,
        DosageForm           NVARCHAR(100)  NOT NULL DEFAULT '',
        Strength             NVARCHAR(50)   NOT NULL DEFAULT '',
        Manufacturer         NVARCHAR(200)  NOT NULL DEFAULT '',
        Description          NVARCHAR(1000) NOT NULL DEFAULT '',
        Price                DECIMAL(18,2)  NOT NULL,
        Stock                INT            NOT NULL DEFAULT 0,
        RequiresPrescription BIT            NOT NULL DEFAULT 0,
        ImageUrl             NVARCHAR(500)  NOT NULL DEFAULT '',
        CreatedAt            DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt            DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    CREATE INDEX IX_Medications_Category ON Medications (Category);
    CREATE INDEX IX_Medications_Name     ON Medications (Name);
    PRINT 'Table Medications created.';
END
GO

-- ============================================================
-- PATIENTS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Patients')
BEGIN
    CREATE TABLE Patients (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        FirstName   NVARCHAR(100) NOT NULL,
        LastName    NVARCHAR(100) NOT NULL,
        Email       NVARCHAR(255) NOT NULL,
        Phone       NVARCHAR(20)  NOT NULL DEFAULT '',
        Address     NVARCHAR(300) NOT NULL DEFAULT '',
        City        NVARCHAR(100) NOT NULL DEFAULT '',
        State       NVARCHAR(50)  NOT NULL DEFAULT '',
        ZipCode     NVARCHAR(20)  NOT NULL DEFAULT '',
        DateOfBirth DATE          NULL,
        CreatedAt   DATETIME2     NOT NULL DEFAULT GETUTCDATE()
    );
    CREATE UNIQUE INDEX UX_Patients_Email    ON Patients (Email);
    CREATE INDEX IX_Patients_LastName        ON Patients (LastName);
    PRINT 'Table Patients created.';
END
GO

-- ============================================================
-- ORDERS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Orders')
BEGIN
    CREATE TABLE Orders (
        Id                   INT IDENTITY(1,1) PRIMARY KEY,
        PatientId            INT            NOT NULL,
        OrderDate            DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        Status               NVARCHAR(50)   NOT NULL DEFAULT 'Pending',
        TotalAmount          DECIMAL(18,2)  NOT NULL DEFAULT 0,
        DeliveryAddress      NVARCHAR(500)  NOT NULL DEFAULT '',
        PrescriptionVerified BIT            NOT NULL DEFAULT 0,
        CONSTRAINT FK_Orders_Patients FOREIGN KEY (PatientId)
            REFERENCES Patients(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Orders_PatientId ON Orders (PatientId);
    CREATE INDEX IX_Orders_Status    ON Orders (Status);
    CREATE INDEX IX_Orders_OrderDate ON Orders (OrderDate DESC);
    PRINT 'Table Orders created.';
END
GO

-- ============================================================
-- ORDER ITEMS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'OrderItems')
BEGIN
    CREATE TABLE OrderItems (
        Id           INT IDENTITY(1,1) PRIMARY KEY,
        OrderId      INT           NOT NULL,
        MedicationId INT           NOT NULL,
        Quantity     INT           NOT NULL DEFAULT 1,
        UnitPrice    DECIMAL(18,2) NOT NULL,
        CONSTRAINT FK_OrderItems_Orders      FOREIGN KEY (OrderId)      REFERENCES Orders(Id)      ON DELETE CASCADE,
        CONSTRAINT FK_OrderItems_Medications FOREIGN KEY (MedicationId) REFERENCES Medications(Id)
    );
    CREATE INDEX IX_OrderItems_OrderId      ON OrderItems (OrderId);
    CREATE INDEX IX_OrderItems_MedicationId ON OrderItems (MedicationId);
    PRINT 'Table OrderItems created.';
END
GO

-- ============================================================
-- INVENTORY
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Inventory')
BEGIN
    CREATE TABLE Inventory (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        MedicationId    INT           NOT NULL,
        QuantityOnHand  INT           NOT NULL DEFAULT 0,
        ReorderLevel    INT           NOT NULL DEFAULT 20,
        ReorderQuantity INT           NOT NULL DEFAULT 50,
        StorageLocation NVARCHAR(50)  NOT NULL DEFAULT '',
        LastUpdated     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Inventory_Medications FOREIGN KEY (MedicationId) REFERENCES Medications(Id)
    );
    CREATE UNIQUE INDEX UX_Inventory_MedicationId ON Inventory (MedicationId);
    CREATE INDEX IX_Inventory_StorageLocation      ON Inventory (StorageLocation);
    PRINT 'Table Inventory created.';
END
GO

PRINT 'All tables created successfully.';
GO
