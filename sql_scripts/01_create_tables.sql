/* tablo oluşturma */

/*bölümler*/
IF OBJECT_ID('dbo.Bolumler', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bolumler (
        BolumID INT IDENTITY(1,1) PRIMARY KEY,
        BolumAdi NVARCHAR(100) NOT NULL,
        Fakulte NVARCHAR(100) NOT NULL DEFAULT N'Mühendislik Fakültesi',

        CONSTRAINT UQ_Bolumler_BolumAdi UNIQUE (BolumAdi)
    );
END
GO

/*dersler*/
IF OBJECT_ID('dbo.Dersler', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dersler (
        DersID INT IDENTITY(1,1) PRIMARY KEY,
        DersKodu NVARCHAR(20) NOT NULL,
        DersTuru NVARCHAR(30) NOT NULL,
        Ad NVARCHAR(150) NOT NULL,
        OgrenciSayisi INT NOT NULL,
        Yariyil INT NOT NULL,
        BolumID INT NOT NULL,

        CONSTRAINT UQ_Dersler_DersKodu UNIQUE (DersKodu),

        CONSTRAINT CK_Dersler_OgrenciSayisi 
            CHECK (OgrenciSayisi > 0),

        CONSTRAINT CK_Dersler_Yariyil 
            CHECK (Yariyil BETWEEN 1 AND 8),

        CONSTRAINT CK_Dersler_DersTuru 
            CHECK (DersTuru IN (N'Zorunlu', N'Seçmeli')),

        CONSTRAINT FK_Dersler_Bolumler 
            FOREIGN KEY (BolumID) REFERENCES dbo.Bolumler(BolumID)
    );
END
GO

/*oturumlar*/
IF OBJECT_ID('dbo.Oturumlar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Oturumlar (
        OturumID INT IDENTITY(1,1) PRIMARY KEY,
        Tanim NVARCHAR(50) NOT NULL,
        BaslangicSaat TIME NOT NULL,
        BitisSaat TIME NOT NULL,

        CONSTRAINT UQ_Oturumlar_Tanim UNIQUE (Tanim),

        CONSTRAINT CK_Oturumlar_Saat 
            CHECK (BaslangicSaat < BitisSaat)
    );
END
GO

/*derslikler*/
IF OBJECT_ID('dbo.Derslikler', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Derslikler (
        DerslikID INT IDENTITY(1,1) PRIMARY KEY,
        Ad NVARCHAR(50) NOT NULL,
        Kapasite INT NOT NULL,
        Tip NVARCHAR(30) NOT NULL,
        Kat INT NULL,
        Aktif BIT NOT NULL DEFAULT 1,

        CONSTRAINT UQ_Derslikler_Ad UNIQUE (Ad),

        CONSTRAINT CK_Derslikler_Kapasite 
            CHECK (Kapasite > 0),

        CONSTRAINT CK_Derslikler_Tip 
            CHECK (Tip IN (N'Amfi', N'Sınıf', N'Lab'))
    );
END
GO

/*personel*/
IF OBJECT_ID('dbo.Personel', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Personel (
        PersonelID INT IDENTITY(1,1) PRIMARY KEY,
        Unvan NVARCHAR(50) NOT NULL,
        Ad NVARCHAR(50) NOT NULL,
        Soyad NVARCHAR(50) NOT NULL,
        BolumID INT NOT NULL,
        Aktif BIT NOT NULL DEFAULT 1,

        CONSTRAINT FK_Personel_Bolumler 
            FOREIGN KEY (BolumID) REFERENCES dbo.Bolumler(BolumID)
    );
END
GO

/*personel durum izinli mi değil mi*/
IF OBJECT_ID('dbo.Personel_Durum', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Personel_Durum (
        DurumID INT IDENTITY(1,1) PRIMARY KEY,
        PersonelID INT NOT NULL,
        Tarih DATE NOT NULL,
        OturumID INT NOT NULL,
        MazeretTuru NVARCHAR(100) NOT NULL,
        Uygun BIT NOT NULL DEFAULT 0,

        CONSTRAINT FK_PersonelDurum_Personel 
            FOREIGN KEY (PersonelID) REFERENCES dbo.Personel(PersonelID),

        CONSTRAINT FK_PersonelDurum_Oturumlar 
            FOREIGN KEY (OturumID) REFERENCES dbo.Oturumlar(OturumID),

        CONSTRAINT UQ_PersonelDurum_Personel_Tarih_Oturum 
            UNIQUE (PersonelID, Tarih, OturumID)
    );
END
GO

/*sınavlar*/
IF OBJECT_ID('dbo.Sinavlar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sinavlar (
        SinavID INT IDENTITY(1,1) PRIMARY KEY,
        DersID INT NOT NULL,
        Tarih DATE NOT NULL,
        OturumID INT NOT NULL,

        CONSTRAINT FK_Sinavlar_Dersler 
            FOREIGN KEY (DersID) REFERENCES dbo.Dersler(DersID),

        CONSTRAINT FK_Sinavlar_Oturumlar 
            FOREIGN KEY (OturumID) REFERENCES dbo.Oturumlar(OturumID),

        CONSTRAINT UQ_Sinavlar_Ders_Tarih_Oturum 
            UNIQUE (DersID, Tarih, OturumID)
    );
END
GO

/*sınav salonu bir sınav birden fazla salonda olabilir*/
IF OBJECT_ID('dbo.Sinav_Salonlari', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sinav_Salonlari (
        SinavSalonID INT IDENTITY(1,1) PRIMARY KEY,
        SinavID INT NOT NULL,
        DerslikID INT NOT NULL,

        CONSTRAINT FK_SinavSalonlari_Sinavlar 
            FOREIGN KEY (SinavID) REFERENCES dbo.Sinavlar(SinavID),

        CONSTRAINT FK_SinavSalonlari_Derslikler 
            FOREIGN KEY (DerslikID) REFERENCES dbo.Derslikler(DerslikID),

        CONSTRAINT UQ_SinavSalonlari_Sinav_Derslik 
            UNIQUE (SinavID, DerslikID)
    );
END
GO

/*gözetmen atama*/
IF OBJECT_ID('dbo.Gozetmen_Atamalari', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Gozetmen_Atamalari (
        GozetmenAtamaID INT IDENTITY(1,1) PRIMARY KEY,
        SinavSalonID INT NOT NULL,
        PersonelID INT NOT NULL,
        AtamaKaynak NVARCHAR(50) NOT NULL DEFAULT N'Kendi Bölümü',

        CONSTRAINT FK_GozetmenAtamalari_SinavSalonlari 
            FOREIGN KEY (SinavSalonID) REFERENCES dbo.Sinav_Salonlari(SinavSalonID),

        CONSTRAINT FK_GozetmenAtamalari_Personel 
            FOREIGN KEY (PersonelID) REFERENCES dbo.Personel(PersonelID),

        CONSTRAINT CK_GozetmenAtamalari_Kaynak 
            CHECK (AtamaKaynak IN (N'Kendi Bölümü', N'Ortak Havuz')),

        CONSTRAINT UQ_GozetmenAtamalari_SinavSalon_Personel 
            UNIQUE (SinavSalonID, PersonelID)
    );
END
GO

/*log*/
IF OBJECT_ID('dbo.Loglar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Loglar (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        IslemTuru NVARCHAR(50) NOT NULL,
        TabloAdi NVARCHAR(100) NOT NULL,
        KayitID INT NULL,
        EskiDeger NVARCHAR(MAX) NULL,
        YeniDeger NVARCHAR(MAX) NULL,
        DegistirenKullanici NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        IslemTarihi DATETIME NOT NULL DEFAULT GETDATE(),
        Aciklama NVARCHAR(500) NULL
    );
END
GO