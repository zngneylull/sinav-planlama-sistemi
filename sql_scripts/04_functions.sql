/* udf */

/* gözetmen müsaitlik durumu (Max 4 oturum kuralı eklendi) */
CREATE OR ALTER FUNCTION dbo.fn_GozetmenMusaitMi
(
    @PersonelID INT,
    @Tarih DATE,
    @OturumID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Sonuc BIT = 1;

    -- 1. Mazeret / izin / danışmanlık kontrolü
    IF EXISTS (
        SELECT 1
        FROM dbo.Personel_Durum PD
        WHERE PD.PersonelID = @PersonelID
          AND PD.Tarih = @Tarih
          AND PD.OturumID = @OturumID
          AND PD.Uygun = 0
    )
    BEGIN
        SET @Sonuc = 0;
    END

    -- 2. Aynı oturumda başka sınavda görevli mi?
    IF EXISTS (
        SELECT 1
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS
            ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Sinavlar S
            ON SS.SinavID = S.SinavID
        WHERE GA.PersonelID = @PersonelID
          AND S.Tarih = @Tarih
          AND S.OturumID = @OturumID
    )
    BEGIN
        SET @Sonuc = 0;
    END

    -- 3. Günlük Max 4 Oturum Kontrolü
    DECLARE @GunlukOturumSayisi INT;
    SELECT @GunlukOturumSayisi = COUNT(DISTINCT S.OturumID)
    FROM dbo.Gozetmen_Atamalari GA
    INNER JOIN dbo.Sinav_Salonlari SS
        ON GA.SinavSalonID = SS.SinavSalonID
    INNER JOIN dbo.Sinavlar S
        ON SS.SinavID = S.SinavID
    WHERE GA.PersonelID = @PersonelID
      AND S.Tarih = @Tarih;

    IF @GunlukOturumSayisi >= 4
    BEGIN
        SET @Sonuc = 0;
    END

    RETURN @Sonuc;
END
GO

/* ardışık oturum uygun mu
   Kural:
   - Bir öğretim elemanı art arda en fazla 3 oturumda görev alabilir.
   - 1-2-3 olabilir.
   - 1-2-3-4 olamaz.
   - 1-2-3-5 olabilir.
   - 2-3-4-5 olamaz.
*/
CREATE OR ALTER FUNCTION dbo.fn_ArdisikOturumUygunMu
(
    @PersonelID INT,
    @Tarih DATE,
    @OturumID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Sonuc BIT = 1;

    DECLARE @Oturumlar TABLE
    (
        OturumID INT PRIMARY KEY
    );

    -- Hocanın o tarihte zaten görevli olduğu oturumları al
    INSERT INTO @Oturumlar (OturumID)
    SELECT DISTINCT S.OturumID
    FROM dbo.Gozetmen_Atamalari GA
    INNER JOIN dbo.Sinav_Salonlari SS
        ON GA.SinavSalonID = SS.SinavSalonID
    INNER JOIN dbo.Sinavlar S
        ON SS.SinavID = S.SinavID
    WHERE GA.PersonelID = @PersonelID
      AND S.Tarih = @Tarih;

    -- Yeni atanmak istenen oturumu da listeye ekle
    IF NOT EXISTS (
        SELECT 1
        FROM @Oturumlar
        WHERE OturumID = @OturumID
    )
    BEGIN
        INSERT INTO @Oturumlar (OturumID)
        VALUES (@OturumID);
    END

    -- Art arda 4 oturum varsa uygun değildir.
    -- Örn: 1-2-3-4 veya 2-3-4-5
    IF EXISTS (
        SELECT 1
        FROM @Oturumlar O1
        INNER JOIN @Oturumlar O2
            ON O2.OturumID = O1.OturumID + 1
        INNER JOIN @Oturumlar O3
            ON O3.OturumID = O1.OturumID + 2
        INNER JOIN @Oturumlar O4
            ON O4.OturumID = O1.OturumID + 3
    )
    BEGIN
        SET @Sonuc = 0;
    END

    RETURN @Sonuc;
END
GO

/*görev sayısı*/
CREATE OR ALTER FUNCTION dbo.fn_GozetmenGorevSayisi
(
    @PersonelID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @GorevSayisi INT;

    SELECT @GorevSayisi = COUNT(*)
    FROM dbo.Gozetmen_Atamalari
    WHERE PersonelID = @PersonelID;

    RETURN ISNULL(@GorevSayisi, 0);
END
GO

/* salon müsaitlik durumu*/
CREATE OR ALTER FUNCTION dbo.fn_SalonMusaitMi
(
    @DerslikID INT,
    @Tarih DATE,
    @OturumID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Sonuc BIT = 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.Sinav_Salonlari SS
        INNER JOIN dbo.Sinavlar S
            ON SS.SinavID = S.SinavID
        WHERE SS.DerslikID = @DerslikID
          AND S.Tarih = @Tarih
          AND S.OturumID = @OturumID
    )
    BEGIN
        SET @Sonuc = 0;
    END

    RETURN @Sonuc;
END
GO

/* salon kapasite*/
CREATE OR ALTER FUNCTION dbo.fn_ToplamSalonKapasitesi
(
    @SinavID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @ToplamKapasite INT;

    SELECT @ToplamKapasite = SUM(D.Kapasite)
    FROM dbo.Sinav_Salonlari SS
    INNER JOIN dbo.Derslikler D
        ON SS.DerslikID = D.DerslikID
    WHERE SS.SinavID = @SinavID;

    RETURN ISNULL(@ToplamKapasite, 0);
END
GO

/* günlük sınav sayısı*/
CREATE OR ALTER FUNCTION dbo.fn_GunlukSinavSayisi
(
    @Tarih DATE,
    @Yariyil INT
)
RETURNS INT
AS
BEGIN
    DECLARE @SinavSayisi INT;

    SELECT @SinavSayisi = COUNT(*)
    FROM dbo.Sinavlar S
    INNER JOIN dbo.Dersler D
        ON S.DersID = D.DersID
    WHERE S.Tarih = @Tarih
      AND D.Yariyil = @Yariyil;

    RETURN ISNULL(@SinavSayisi, 0);
END
GO

/* test sorguları*/

-- Gözetmen müsaitlik testi
SELECT dbo.fn_GozetmenMusaitMi(1, '2026-05-20', 1) AS GozetmenMusaitMi;

-- Ardışık oturum testi
SELECT dbo.fn_ArdisikOturumUygunMu(1, '2026-05-20', 4) AS ArdisikOturumUygunMu;

-- Görev sayısı testi
SELECT dbo.fn_GozetmenGorevSayisi(1) AS GozetmenGorevSayisi;

-- Salon müsaitlik testi
SELECT dbo.fn_SalonMusaitMi(1, '2026-05-20', 1) AS SalonMusaitMi;

-- Toplam kapasite testi
SELECT dbo.fn_ToplamSalonKapasitesi(1) AS ToplamSalonKapasitesi;

-- Günlük sınav sayısı testi
SELECT dbo.fn_GunlukSinavSayisi('2026-05-20', 4) AS GunlukSinavSayisi;
GO