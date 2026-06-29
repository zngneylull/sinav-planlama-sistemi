/* views*/

/*SinavProgrami*/
CREATE OR ALTER VIEW dbo.vw_SinavProgrami
AS
SELECT
    S.SinavID,
    S.Tarih,
    O.Tanim AS Oturum,
    CONVERT(VARCHAR(5), O.BaslangicSaat, 108) + ' - ' + 
    CONVERT(VARCHAR(5), O.BitisSaat, 108) AS SaatAraligi,

    D.DersKodu,
    D.Ad AS DersAdi,
    D.DersTuru,
    D.OgrenciSayisi,
    D.Yariyil,
	B.BolumAdi,

    STUFF((SELECT ', ' + DL.Ad 
           FROM dbo.Sinav_Salonlari SS 
           JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
           WHERE SS.SinavID = S.SinavID 
           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Derslikler,

    STUFF((SELECT ', ' + P.Ad + ' ' + P.Soyad 
           FROM dbo.Gozetmen_Atamalari GA
           JOIN dbo.Personel P ON GA.PersonelID = P.PersonelID
           JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
           WHERE SS.SinavID = S.SinavID 
           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Gozetmenler

FROM dbo.Sinavlar S
INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
INNER JOIN dbo.Bolumler B ON D.BolumID = B.BolumID
INNER JOIN dbo.Oturumlar O ON S.OturumID = O.OturumID
GROUP BY 
    S.SinavID, S.Tarih, O.Tanim, O.BaslangicSaat, O.BitisSaat, D.DersKodu, D.Ad, D.DersTuru, D.OgrenciSayisi, D.Yariyil, B.BolumAdi;
GO

/*GozetmenGorevDagilimi*/
CREATE OR ALTER VIEW dbo.vw_GozetmenGorevDagilimi
AS
SELECT
    P.PersonelID,
    P.Unvan,
    P.Ad,
    P.Soyad,
    P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS AdSoyad,
    B.BolumAdi,
    COUNT(GA.GozetmenAtamaID) AS GorevSayisi
FROM dbo.Personel P
INNER JOIN dbo.Bolumler B 
    ON P.BolumID = B.BolumID
LEFT JOIN dbo.Gozetmen_Atamalari GA 
    ON P.PersonelID = GA.PersonelID
GROUP BY
    P.PersonelID,
    P.Unvan,
    P.Ad,
    P.Soyad,
    B.BolumAdi;
GO

/*DerslikKullanimRaporu*/
CREATE OR ALTER VIEW dbo.vw_DerslikKullanimRaporu
AS
SELECT
    DL.DerslikID,
    DL.Ad AS Derslik,
    DL.Kapasite,
    DL.Tip,
    DL.Kat,
    DL.Aktif,
    COUNT(SS.SinavSalonID) AS KullanimSayisi
FROM dbo.Derslikler DL
LEFT JOIN dbo.Sinav_Salonlari SS 
    ON DL.DerslikID = SS.DerslikID
GROUP BY
    DL.DerslikID,
    DL.Ad,
    DL.Kapasite,
    DL.Tip,
    DL.Kat,
    DL.Aktif;
GO

/*BolumSinavYogunlugu*/
CREATE OR ALTER VIEW dbo.vw_BolumSinavYogunlugu
AS
SELECT
    B.BolumID,
    B.BolumAdi,
    D.Yariyil,
    S.Tarih,
    COUNT(S.SinavID) AS GunlukSinavSayisi,
    CASE
        WHEN COUNT(S.SinavID) > 2 THEN N'Uyarı: Aynı gün 2’den fazla sınav var'
        ELSE N'Uygun'
    END AS Durum
FROM dbo.Sinavlar S
INNER JOIN dbo.Dersler D 
    ON S.DersID = D.DersID
INNER JOIN dbo.Bolumler B 
    ON D.BolumID = B.BolumID
GROUP BY
    B.BolumID,
    B.BolumAdi,
    D.Yariyil,
    S.Tarih;
GO

/*kontrol sorguları*/
SELECT * FROM dbo.vw_SinavProgrami;
SELECT * FROM dbo.vw_GozetmenGorevDagilimi;
SELECT * FROM dbo.vw_DerslikKullanimRaporu;
SELECT * FROM dbo.vw_BolumSinavYogunlugu;
GO