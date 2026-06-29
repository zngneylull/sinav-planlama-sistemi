/* trigger */

/*sınav saati değişikliği triggeri ek ister*/
CREATE OR ALTER TRIGGER dbo.trg_SinavSaatDegisikligi_Log
ON dbo.Sinavlar
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

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
    SELECT
        N'UPDATE',
        N'Sinavlar',
        I.SinavID,

        N'Eski Tarih: ' + CONVERT(NVARCHAR(20), D.Tarih, 120) +
        N', Eski OturumID: ' + CAST(D.OturumID AS NVARCHAR(10)),

        N'Yeni Tarih: ' + CONVERT(NVARCHAR(20), I.Tarih, 120) +
        N', Yeni OturumID: ' + CAST(I.OturumID AS NVARCHAR(10)),

        SYSTEM_USER,
        GETDATE(),
        N'Sınav tarihi veya oturumu değiştirildi.'

    FROM inserted I
    INNER JOIN deleted D
        ON I.SinavID = D.SinavID
    WHERE 
        ISNULL(I.Tarih, '1900-01-01') <> ISNULL(D.Tarih, '1900-01-01')
        OR ISNULL(I.OturumID, -1) <> ISNULL(D.OturumID, -1);
END
GO

/*gözetmen atama triggeri*/
CREATE OR ALTER TRIGGER dbo.trg_GozetmenAtama_Log
ON dbo.Gozetmen_Atamalari
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

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
    SELECT
        N'INSERT',
        N'Gozetmen_Atamalari',
        I.GozetmenAtamaID,
        NULL,
        N'SinavSalonID: ' + CAST(I.SinavSalonID AS NVARCHAR(10)) +
        N', PersonelID: ' + CAST(I.PersonelID AS NVARCHAR(10)) +
        N', Kaynak: ' + I.AtamaKaynak,
        SYSTEM_USER,
        GETDATE(),
        N'Yeni gözetmen ataması yapıldı.'
    FROM inserted I;
END
GO

/*salon atama triggeri*/
CREATE OR ALTER TRIGGER dbo.trg_SalonAtama_Log
ON dbo.Sinav_Salonlari
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

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
    SELECT
        N'INSERT',
        N'Sinav_Salonlari',
        I.SinavSalonID,
        NULL,
        N'SinavID: ' + CAST(I.SinavID AS NVARCHAR(10)) +
        N', DerslikID: ' + CAST(I.DerslikID AS NVARCHAR(10)),
        SYSTEM_USER,
        GETDATE(),
        N'Sınava yeni salon ataması yapıldı.'
    FROM inserted I;
END
GO

CREATE OR ALTER TRIGGER dbo.trg_OtomatikAtama
ON dbo.Sinavlar
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SinavID INT;
    SELECT @SinavID = SinavID FROM inserted;

    BEGIN TRY
        -- Atamaları burada yapıyoruz
        EXEC dbo.sp_SalonAtamaYap @SinavID = @SinavID, @DerslikIDList = '11'; 
        EXEC dbo.sp_GozetmenAta @SinavID = @SinavID;
    END TRY
    BEGIN CATCH
        -- HATA OLURSA SADECE LOGLA, ASLA ROLLBACK YAPMA!
        -- Bu blok, sınav ekleme işleminin iptal edilmesini engeller.
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) 
        VALUES ('TRIGGER_HATA', ERROR_MESSAGE());
    END CATCH
END
GO

------------------------------------------------------------
-- 4. TRIGGER TEST SORGULARI
-- Not:
-- Bunlar SSMS üzerinde test amaçlı tek tek çalıştırılabilir.
------------------------------------------------------------

-- Sınav saat değişikliği trigger testi:
-- EXEC dbo.sp_SinavSaatiGuncelle
--      @SinavID = 1,
--      @YeniTarih = '2026-05-20',
--      @YeniOturumID = 2;

-- Logları gör:
-- SELECT * FROM dbo.Loglar ORDER BY LogID DESC;

GO