/* isterlerin testleri */

/* tablo kontrolleri*/
SELECT * FROM dbo.Bolumler;
SELECT * FROM dbo.Dersler;
SELECT * FROM dbo.Oturumlar;
SELECT * FROM dbo.Derslikler;
SELECT * FROM dbo.Personel;
SELECT * FROM dbo.Personel_Durum;
SELECT * FROM dbo.Sinavlar;
SELECT * FROM dbo.Sinav_Salonlari;
SELECT * FROM dbo.Gozetmen_Atamalari;
SELECT * FROM dbo.Loglar;
GO

/*view testleri*/
SELECT * FROM dbo.vw_SinavProgrami;
SELECT * FROM dbo.vw_GozetmenGorevDagilimi;
SELECT * FROM dbo.vw_DerslikKullanimRaporu;
SELECT * FROM dbo.vw_BolumSinavYogunlugu;
GO

/*udf testleri*/

--gözetmen müsait mi
SELECT dbo.fn_GozetmenMusaitMi(1, '2026-05-20', 1) AS GozetmenMusaitMi;
GO

--ardışık oturum
SELECT dbo.fn_ArdisikOturumUygunMu(1, '2026-05-20', 4) AS ArdisikOturumUygunMu;
GO

--görev sayısı
SELECT dbo.fn_GozetmenGorevSayisi(1) AS GozetmenGorevSayisi;
GO

--salon boş mu
SELECT dbo.fn_SalonMusaitMi(1, '2026-05-20', 1) AS SalonMusaitMi;
GO

--toplam kapasite
SELECT dbo.fn_ToplamSalonKapasitesi(1) AS ToplamSalonKapasitesi;
GO

--aynı dönemdeki günlük sınav sayısı
SELECT dbo.fn_GunlukSinavSayisi('2026-05-20', 4) AS GunlukSinavSayisi;
GO

/* sp testleri*/

--yeni sınav oluşturma 
EXEC dbo.sp_SinavOlustur
    @DersID = 101,
    @Tarih = '2026-05-21',
    @OturumID = 2;
GO

--salon atama
EXEC dbo.sp_SalonAtamaYap
    @SinavID = 1,
    @DerslikIDList = '11,12,13';
GO

--gözetmen atama
EXEC dbo.sp_GozetmenAta
    @SinavID = 1;
GO

--sınav saati güncelleme 
EXEC dbo.sp_SinavSaatiGuncelle
    @SinavID = 1,
    @YeniTarih = '2026-05-20',
    @YeniOturumID = 2;
GO

/*trigger testleri*/

--sınav saati değişikliği log kaydı
SELECT * 
FROM dbo.Loglar
ORDER BY LogID DESC;
GO

--gözetmen atama logları
SELECT *
FROM dbo.Loglar
WHERE TabloAdi = N'Gozetmen_Atamalari'
ORDER BY LogID DESC;
GO

--salon atama logları
SELECT *
FROM dbo.Loglar
WHERE TabloAdi = N'Sinav_Salonlari'
ORDER BY LogID DESC;
GO

/*transaction testleri*/

-- Bu test hata verebilir, bu normaldir.
-- Çünkü Lab-1 kapasitesi 30, YZM2126 öğrenci sayısı 132.
-- İşlem geri alınmalı.
BEGIN TRY
    EXEC dbo.sp_SalonAtamaYap
        @SinavID = 1,
        @DerslikIDList = '3';
END TRY
BEGIN CATCH
    SELECT 
        N'Rollback testi başarılı: Hata yakalandı ve işlem geri alındı.' AS Mesaj,
        ERROR_MESSAGE() AS HataMesaji;
END CATCH;
GO

/*güvenlik testleri*/

-- App_Admin tüm tablolarda SELECT yapabilmeli.
EXECUTE AS USER = 'App_Admin';
SELECT TOP 5 * FROM dbo.Dersler;
SELECT TOP 5 * FROM dbo.Sinavlar;
REVERT;
GO

-- App_Viewer sadece view görebilmeli.
EXECUTE AS USER = 'App_Viewer';
SELECT TOP 5 * FROM dbo.vw_SinavProgrami;
REVERT;
GO

-- App_Viewer doğrudan tablo okuyamamalı.
-- Bu test hata verebilir, bu normaldir.
BEGIN TRY
    EXECUTE AS USER = 'App_Viewer';
    SELECT TOP 5 * FROM dbo.Dersler;
    REVERT;
END TRY
BEGIN CATCH
    IF ORIGINAL_LOGIN() IS NOT NULL
    BEGIN
        REVERT;
    END

    SELECT 
        N'App_Viewer tablo SELECT engeli başarılı.' AS Mesaj,
        ERROR_MESSAGE() AS HataMesaji;
END CATCH;
GO

-- App_Viewer INSERT yapamamalı.
-- Bu test hata verebilir, bu normaldir.
BEGIN TRY
    EXECUTE AS USER = 'App_Viewer';

    INSERT INTO dbo.Bolumler (BolumAdi, Fakulte)
    VALUES (N'Yetkisiz Test Bölümü', N'Mühendislik Fakültesi');

    REVERT;
END TRY
BEGIN CATCH
    IF ORIGINAL_LOGIN() IS NOT NULL
    BEGIN
        REVERT;
    END

    SELECT 
        N'App_Viewer INSERT engeli başarılı.' AS Mesaj,
        ERROR_MESSAGE() AS HataMesaji;
END CATCH;
GO

------------------------------------------------------------
-- 8. BACKUP BONUS TESTİ
-- 08_backup_procedure.sql şu an pasif hale getirildi.
-- Aktif edilirse aşağıdaki komut çalıştırılabilir.
------------------------------------------------------------

-- EXEC dbo.sp_VeritabaniYedekAl;
-- SELECT * FROM dbo.Loglar ORDER BY LogID DESC;
GO

------------------------------------------------------------
-- 9. FINAL KONTROL RAPORU
------------------------------------------------------------

SELECT 
    (SELECT COUNT(*) FROM dbo.Bolumler) AS BolumSayisi,
    (SELECT COUNT(*) FROM dbo.Dersler) AS DersSayisi,
    (SELECT COUNT(*) FROM dbo.Oturumlar) AS OturumSayisi,
    (SELECT COUNT(*) FROM dbo.Derslikler) AS DerslikSayisi,
    (SELECT COUNT(*) FROM dbo.Personel) AS PersonelSayisi,
    (SELECT COUNT(*) FROM dbo.Sinavlar) AS SinavSayisi,
    (SELECT COUNT(*) FROM dbo.Sinav_Salonlari) AS SalonAtamaSayisi,
    (SELECT COUNT(*) FROM dbo.Gozetmen_Atamalari) AS GozetmenAtamaSayisi,
    (SELECT COUNT(*) FROM dbo.Loglar) AS LogSayisi;
GO