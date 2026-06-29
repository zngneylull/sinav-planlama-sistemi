-- ===================================================================
-- CANLI TEST VE VERİ DOĞRULAMA SORGULARI
-- ===================================================================

-- 1. Canlı Raporlama Görünümü (Mevcut Sınav Programı Raporu)
SELECT * FROM dbo.vw_SinavProgrami WITH (NOLOCK);

-- 2. View Tanımının (Definition) SQL Kodlarını Sorgulama
SELECT definition 
FROM sys.sql_modules 
WHERE object_id = OBJECT_ID('dbo.vw_SinavProgrami');

-- 3. Çakışma Kontrolü Testi (Mükerrer Sınav Girişini Engelleme)
-- Bu sorgu çalıştırıldığında veritabanı kısıtları yüzünden HATA fırlatmalıdır!
INSERT INTO dbo.Sinavlar (SinavID, DersID, Tarih, OturumID)
VALUES (999, 2, '2026-05-20', 2);

-- 4. Sistem Denetim İzleri (Tetikleyici / Log Tablosu Kontrolü)
SELECT * FROM dbo.Loglar ORDER BY IslemTarihi DESC;