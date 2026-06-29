CREATE OR ALTER PROCEDURE dbo.sp_SinavOlustur
    @DersID INT,
    @Tarih DATE,
    @OturumID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Yariyil INT, @GunlukSinavSayisi INT;

    SELECT @Yariyil = Yariyil FROM dbo.Dersler WHERE DersID = @DersID;

    IF @Yariyil IS NULL
    BEGIN
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('HATA', 'Ders bulunamadı.');
        RETURN; 
    END

    /* 1. ve 2. KURALLAR: Çakışma kontrolü */
    IF EXISTS (
        SELECT 1 FROM dbo.Sinavlar S
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        WHERE D.Yariyil = @Yariyil AND S.Tarih = @Tarih AND D.DersID <> @DersID AND ABS(S.OturumID - @OturumID) < 2
    )
    BEGIN
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('KURAL', 'Çakışma veya boşluk kuralı ihlali.');
        RETURN; 
    END

    /* 3. KURAL: Günlük max 2 sınav kontrolü */
    SET @GunlukSinavSayisi = dbo.fn_GunlukSinavSayisi(@Tarih, @Yariyil);
    IF @GunlukSinavSayisi >= 2
    BEGIN
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('KURAL', 'Günlük sınav limiti aşıldı.');
        RETURN;
    END

    INSERT INTO dbo.Sinavlar (DersID, Tarih, OturumID) VALUES (@DersID, @Tarih, @OturumID);

    SELECT S.SinavID, D.DersKodu, D.Ad AS DersAdi
    FROM dbo.Sinavlar S
    INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
    WHERE S.SinavID = SCOPE_IDENTITY();
END
GO

/*salon atama*/
CREATE OR ALTER PROCEDURE dbo.sp_SalonAtamaYap
    @SinavID INT,
    @DerslikIDList NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Tarih DATE;
        DECLARE @OturumID INT;
        DECLARE @OgrenciSayisi INT;
        DECLARE @ToplamKapasite INT;

        SELECT
            @Tarih = S.Tarih,
            @OturumID = S.OturumID,
            @OgrenciSayisi = D.OgrenciSayisi
        FROM dbo.Sinavlar S
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        WHERE S.SinavID = @SinavID;

        IF @Tarih IS NULL
        BEGIN
            INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('HATA', 'Sınav bulunamadı.');
            RETURN; -- Hata fırlatma, sadece çık
        END

        /* Seçilen salon toplam kapasite */
        SELECT @ToplamKapasite = SUM(DL.Kapasite)
        FROM dbo.Derslikler DL
        WHERE DL.DerslikID IN (
            SELECT TRY_CAST(value AS INT)
            FROM STRING_SPLIT(@DerslikIDList, ',')
        );

        /* KAPASİTE KONTROLÜ: Hata fırlatmak yerine sadece logla ve çık */
        IF ISNULL(@ToplamKapasite, 0) < @OgrenciSayisi
        BEGIN
            INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('KAPASİTE HATASI', N'Seçilen salonların kapasitesi öğrenci sayısından az.');
            RETURN; -- İşlemi sessizce durdur, böylece sınav silinmez
        END

        /* Salon çakışma kontrolü */
        IF EXISTS (
            SELECT 1
            FROM STRING_SPLIT(@DerslikIDList, ',') X
            WHERE dbo.fn_SalonMusaitMi(TRY_CAST(X.value AS INT), @Tarih, @OturumID) = 0
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.Sinav_Salonlari SS
                  WHERE SS.SinavID = @SinavID AND SS.DerslikID = TRY_CAST(X.value AS INT)
              )
        )
        BEGIN
            INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('ÇAKIŞMA HATASI', N'Seçilen salon dolu.');
            RETURN;
        END

        /* Atama ekle */
        INSERT INTO dbo.Sinav_Salonlari (SinavID, DerslikID)
        SELECT @SinavID, TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@DerslikIDList, ',') X
        WHERE TRY_CAST(value AS INT) IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM dbo.Sinav_Salonlari SS
              WHERE SS.SinavID = @SinavID AND SS.DerslikID = TRY_CAST(X.value AS INT)
          );

        SELECT N'Salon atama işlemi başarıyla tamamlandı.' AS Mesaj;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('SİSTEM HATASI', ERROR_MESSAGE());
    END CATCH
END
GO

/*gözetmen atama*/
CREATE OR ALTER PROCEDURE dbo.sp_GozetmenAta
    @SinavID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Transaction'ı başlatıyoruz ancak RAISERROR yerine loglama yapacağız
        BEGIN TRANSACTION;

        DECLARE @Tarih DATE, @OturumID INT, @DersBolumID INT;

        SELECT @Tarih = S.Tarih, @OturumID = S.OturumID, @DersBolumID = D.BolumID
        FROM dbo.Sinavlar S
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        WHERE S.SinavID = @SinavID;

        -- HATA 1: Sınav bulunamadı
        IF @Tarih IS NULL 
        BEGIN
            INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('HATA', 'Sınav bulunamadı.');
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RETURN; 
        END

        DECLARE @SinavSalonID INT, @SecilenPersonelID INT, @AtamaKaynak NVARCHAR(50);

        DECLARE salon_cursor CURSOR FOR
        SELECT SS.SinavSalonID FROM dbo.Sinav_Salonlari SS
        WHERE SS.SinavID = @SinavID AND NOT EXISTS (SELECT 1 FROM dbo.Gozetmen_Atamalari GA WHERE GA.SinavSalonID = SS.SinavSalonID);

        OPEN salon_cursor;
        FETCH NEXT FROM salon_cursor INTO @SinavSalonID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SecilenPersonelID = NULL;
            
            -- Bölüme uygun gözetmen
            SELECT TOP 1 @SecilenPersonelID = P.PersonelID, @AtamaKaynak = N'Kendi Bölümü'
            FROM dbo.Personel P
            WHERE P.Aktif = 1 AND P.BolumID = @DersBolumID
              AND dbo.fn_GozetmenMusaitMi(P.PersonelID, @Tarih, @OturumID) = 1
              AND dbo.fn_ArdisikOturumUygunMu(P.PersonelID, @Tarih, @OturumID) = 1
            ORDER BY dbo.fn_GozetmenGorevSayisi(P.PersonelID) ASC;

            -- Ortak havuz
            IF @SecilenPersonelID IS NULL
            BEGIN
                SELECT TOP 1 @SecilenPersonelID = P.PersonelID, @AtamaKaynak = N'Ortak Havuz'
                FROM dbo.Personel P
                WHERE P.Aktif = 1 AND P.BolumID <> @DersBolumID
                  AND dbo.fn_GozetmenMusaitMi(P.PersonelID, @Tarih, @OturumID) = 1
                  AND dbo.fn_ArdisikOturumUygunMu(P.PersonelID, @Tarih, @OturumID) = 1
                ORDER BY dbo.fn_GozetmenGorevSayisi(P.PersonelID) ASC;
            END

            -- HATA 2: Uygun gözetmen bulunamadı
            IF @SecilenPersonelID IS NULL 
            BEGIN
                INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('HATA', 'Uygun gözetmen bulunamadı.');
                CLOSE salon_cursor; DEALLOCATE salon_cursor;
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN; -- İşlemi durdur ama arayüzü çökertme
            END

            INSERT INTO dbo.Gozetmen_Atamalari (SinavSalonID, PersonelID, AtamaKaynak)
            VALUES (@SinavSalonID, @SecilenPersonelID, @AtamaKaynak);

            FETCH NEXT FROM salon_cursor INTO @SinavSalonID;
        END

        CLOSE salon_cursor;
        DEALLOCATE salon_cursor;

        COMMIT TRANSACTION;
        SELECT N'Gözetmen atama işlemi başarıyla tamamlandı.' AS Mesaj, @SinavID AS SinavID;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'salon_cursor') >= 0
        BEGIN CLOSE salon_cursor; DEALLOCATE salon_cursor; END

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO dbo.Loglar (IslemTuru, Aciklama) VALUES ('SİSTEM HATASI', ERROR_MESSAGE());
    END CATCH
END
GO

/*sınav saati güncelleme*/
CREATE OR ALTER PROCEDURE dbo.sp_SinavSaatiGuncelle
    @SinavID INT,
    @YeniTarih DATE,
    @YeniOturumID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Sinavlar
        WHERE SinavID = @SinavID
    )
    BEGIN
        RAISERROR(N'Sınav bulunamadı.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Sinavlar
    SET 
        Tarih = @YeniTarih,
        OturumID = @YeniOturumID
    WHERE SinavID = @SinavID;

    SELECT 
        N'Sınav tarihi / oturumu güncellendi. Log triggerı çalışacaktır.' AS Mesaj,
        @SinavID AS SinavID,
        @YeniTarih AS YeniTarih,
        @YeniOturumID AS YeniOturumID;
END
GO

------------------------------------------------------------
-- 5. TEST ÇAĞRILARI
-- Not:
-- Bunlar test amaçlıdır. Gerekirse SSMS'te tek tek çalıştırılır.
------------------------------------------------------------

-- Yeni sınav oluşturma örneği:
-- EXEC dbo.sp_SinavOlustur 
--      @DersID = 2, 
--      @Tarih = '2026-05-21', 
--      @OturumID = 2;

-- Salon atama örneği:
-- EXEC dbo.sp_SalonAtamaYap 
--      @SinavID = 1, 
--      @DerslikIDList = '1,2';

-- Gözetmen atama örneği:
-- EXEC dbo.sp_GozetmenAta 
--      @SinavID = 1;

-- Sınav saati güncelleme örneği:
-- EXEC dbo.sp_SinavSaatiGuncelle 
--      @SinavID = 1,
--      @YeniTarih = '2026-05-20',
--      @YeniOturumID = 2;
GO