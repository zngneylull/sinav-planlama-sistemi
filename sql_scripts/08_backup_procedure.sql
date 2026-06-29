/* bonus ister backupdatabase sp haline getirme*/

CREATE OR ALTER PROCEDURE dbo.sp_VeritabaniYedekAl
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName NVARCHAR(128);
    DECLARE @BackupPath NVARCHAR(500);
    DECLARE @FileName NVARCHAR(500);
    DECLARE @Sql NVARCHAR(MAX);

    SET @DatabaseName = DB_NAME();

    SET @BackupPath = N'C:\Yedekler\';

    SET @FileName = @BackupPath 
        + @DatabaseName 
        + N'_' 
        + REPLACE(CONVERT(NVARCHAR(10), GETDATE(), 120), '-', '') 
        + N'_' 
        + REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), ':', '') 
        + N'.bak';

    SET @Sql = N'
        BACKUP DATABASE [' + @DatabaseName + N']
        TO DISK = N''' + @FileName + N'''
        WITH FORMAT,
             INIT,
             NAME = N''' + @DatabaseName + N' Full Backup'',
             SKIP,
             NOREWIND,
             NOUNLOAD,
             STATS = 10;
    ';

    EXEC sp_executesql @Sql;

    INSERT INTO dbo.Loglar
    (
        IslemTuru,
        TabloAdi,
        KayitID,
        EskiDeger,
        YeniDeger,
        DegistirenKullanici,
        IslemTarihi,
        Aciklama
    )
    VALUES
    (
        N'BACKUP',
        N'Database',
        NULL,
        NULL,
        @FileName,
        SYSTEM_USER,
        GETDATE(),
        N'Veritabanı yedeği alındı.'
    );

    SELECT 
        N'Veritabanı yedeği başarıyla alındı.' AS Mesaj,
        @DatabaseName AS DatabaseName,
        @FileName AS BackupFilePath;
END
GO
/*

------------------------------------------------------------
-- TEST ÇAĞRISI
------------------------------------------------------------

-- EXEC dbo.sp_VeritabaniYedekAl;

-- SELECT * FROM dbo.Loglar ORDER BY LogID DESC;
GO 