/* role based security grant deny revoke*/


/*login oluşturma*/

IF NOT EXISTS (
    SELECT 1 
    FROM sys.server_principals 
    WHERE name = N'App_Admin'
)
BEGIN
    CREATE LOGIN App_Admin 
    WITH PASSWORD = 'Admin_12345!',
         CHECK_POLICY = OFF;
END
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.server_principals 
    WHERE name = N'App_Viewer'
)
BEGIN
    CREATE LOGIN App_Viewer 
    WITH PASSWORD = 'Viewer_12345!',
         CHECK_POLICY = OFF;
END
GO

/* db user oluşturma*/

IF NOT EXISTS (
    SELECT 1 
    FROM sys.database_principals 
    WHERE name = N'App_Admin'
)
BEGIN
    CREATE USER App_Admin FOR LOGIN App_Admin;
END
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.database_principals 
    WHERE name = N'App_Viewer'
)
BEGIN
    CREATE USER App_Viewer FOR LOGIN App_Viewer;
END
GO

/*yönetici her tabloya okuma yazma yapabilir*/

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Bolumler TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Dersler TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Oturumlar TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Derslikler TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Personel TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Personel_Durum TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Sinavlar TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Sinav_Salonlari TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Gozetmen_Atamalari TO App_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Loglar TO App_Admin;
GO

/*sp çalıştırma yetkileri*/

GRANT EXECUTE ON dbo.sp_SinavOlustur TO App_Admin;
GRANT EXECUTE ON dbo.sp_SalonAtamaYap TO App_Admin;
GRANT EXECUTE ON dbo.sp_GozetmenAta TO App_Admin;
GRANT EXECUTE ON dbo.sp_SinavSaatiGuncelle TO App_Admin;
GO

/*view yetkileri*/

GRANT SELECT ON dbo.vw_SinavProgrami TO App_Viewer;
GRANT SELECT ON dbo.vw_GozetmenGorevDagilimi TO App_Viewer;
GRANT SELECT ON dbo.vw_DerslikKullanimRaporu TO App_Viewer;
GRANT SELECT ON dbo.vw_BolumSinavYogunlugu TO App_Viewer;
GO

/*tablo yazma yetkileri engelleme*/

DENY INSERT, UPDATE, DELETE ON dbo.Bolumler TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Dersler TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Oturumlar TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Derslikler TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Personel TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Personel_Durum TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Sinavlar TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Sinav_Salonlari TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Gozetmen_Atamalari TO App_Viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Loglar TO App_Viewer;
GO

/*doğrudan select atama yok rapordan görsün*/

DENY SELECT ON dbo.Bolumler TO App_Viewer;
DENY SELECT ON dbo.Dersler TO App_Viewer;
DENY SELECT ON dbo.Oturumlar TO App_Viewer;
DENY SELECT ON dbo.Derslikler TO App_Viewer;
DENY SELECT ON dbo.Personel TO App_Viewer;
DENY SELECT ON dbo.Personel_Durum TO App_Viewer;
DENY SELECT ON dbo.Sinavlar TO App_Viewer;
DENY SELECT ON dbo.Sinav_Salonlari TO App_Viewer;
DENY SELECT ON dbo.Gozetmen_Atamalari TO App_Viewer;
DENY SELECT ON dbo.Loglar TO App_Viewer;
GO

/* yanlışlıkla verilen execute yetkisi geri alınır*/
REVOKE EXECUTE TO App_Viewer;
GO

------------------------------------------------------------
-- 9. SECURITY TEST SORGULARI
-- Bunlar SSMS'te test amaçlı kullanılabilir.
------------------------------------------------------------

-- App_Admin olarak test:
-- EXECUTE AS USER = 'App_Admin';
-- SELECT * FROM dbo.Dersler;
-- INSERT INTO dbo.Bolumler (BolumAdi, Fakulte) VALUES (N'Test Bölümü', N'Mühendislik Fakültesi');
-- REVERT;

-- App_Viewer olarak test:
-- EXECUTE AS USER = 'App_Viewer';
-- SELECT * FROM dbo.vw_SinavProgrami;
-- SELECT * FROM dbo.Dersler; -- DENY nedeniyle hata vermeli
-- INSERT INTO dbo.Dersler (DersKodu, DersTuru, Ad, OgrenciSayisi, Yariyil, BolumID)
-- VALUES (N'TEST101', N'Zorunlu', N'Test Dersi', 10, 1, 1); -- DENY nedeniyle hata vermeli
-- REVERT;
GO