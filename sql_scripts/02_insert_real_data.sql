-- ========================================================
-- ONCE TEMIZLIK (Yabancı Anahtar Hiyerarşisine Uygun Sıra)
-- ========================================================
DELETE FROM dbo.Loglar;
DELETE FROM dbo.Gozetmen_Atamalari;
DELETE FROM dbo.Sinav_Salonlari;
DELETE FROM dbo.Sinavlar;
DELETE FROM dbo.Personel_Durum;
DELETE FROM dbo.Personel;
DELETE FROM dbo.Dersler;
DELETE FROM dbo.Derslikler;
DELETE FROM dbo.Bolumler;
DELETE FROM dbo.Oturumlar;

-- ========================================================
-- 1. RESMI OTURUMLAR
-- ========================================================
SET IDENTITY_INSERT dbo.Oturumlar ON;
INSERT INTO dbo.Oturumlar (OturumID, Tanim, BaslangicSaat, BitisSaat) VALUES 
(1, N'Sabah-1', '09:00', '10:00'),
(2, N'Sabah-2', '10:30', '11:30'),
(3, N'Öğle', '12:00', '13:00'),
(4, N'Öğleden Sonra-1', '13:45', '14:45'),
(5, N'Öğleden Sonra-2', '15:15', '16:30');
SET IDENTITY_INSERT dbo.Oturumlar OFF;

-- ========================================================
-- 2. RESMI DERSLIKLER VE KONTENJANLARI
-- ========================================================
SET IDENTITY_INSERT dbo.Derslikler ON;
INSERT INTO dbo.Derslikler (DerslikID, Ad, Kapasite, Tip, Aktif) VALUES 
-- Küçük Sınıflar (Sınav Salon Kontenjanı: 36)
(1, '205', 36, N'Sınıf', 1), (2, '206', 36, N'Sınıf', 1), 
(3, '207', 36, N'Sınıf', 1), (4, '208', 36, N'Sınıf', 1),
(5, '305', 36, N'Sınıf', 1), (6, '306', 36, N'Sınıf', 1), 
(7, '307', 36, N'Sınıf', 1), (8, '308', 36, N'Sınıf', 1),
-- Orta Büyüklükteki Sınıflar
(9, '309', 40, N'Sınıf', 1),
(10, '311', 50, N'Sınıf', 1),
-- Büyük Sınıflar (Sınav Salon Kontenjanı: 60)
(11, '209', 60, N'Amfi', 1), (12, '210', 60, N'Amfi', 1), 
(13, '310', 60, N'Amfi', 1), (14, '409', 60, N'Amfi', 1), 
(15, '410', 60, N'Amfi', 1);
SET IDENTITY_INSERT dbo.Derslikler OFF;

-- ========================================================
-- 3. RESMI BEŞ MÜHENDİSLİK BÖLÜMÜ
-- ========================================================
SET IDENTITY_INSERT dbo.Bolumler ON;
INSERT INTO dbo.Bolumler (BolumID, BolumAdi, Fakulte) VALUES 
(1, N'Yazılım Mühendisliği', N'Mühendislik Fakültesi'),
(2, N'Elektrik Mühendisliği', N'Mühendislik Fakültesi'),
(3, N'Makine Mühendisliği', N'Mühendislik Fakültesi'),
(4, N'Mekatronik Mühendisliği', N'Mühendislik Fakültesi'),
(5, N'Enerji Sistemleri Mühendisliği', N'Mühendislik Fakültesi');
SET IDENTITY_INSERT dbo.Bolumler OFF;

-- ========================================================
-- 4. PDF'LERDEN EKSİKSİZ AYIKLANAN TÜM DERSLER (TÜM SENARYOLAR)
-- (Kural: Küçük Sınıf->60, 309->80, 311->50, Büyük Sınıf->150)
-- ========================================================
SET IDENTITY_INSERT dbo.Dersler ON;

-- ==========================================
-- 4.1. YAZILIM MÜHENDİSLİĞİ DERSLERİ (GÜZ & BAHAR)
-- ==========================================
INSERT INTO dbo.Dersler (DersID, DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID, DersTuru) VALUES 
-- 1. Sınıf Güz / Bahar
(101, 'YZM1111', N'Algoritma ve Programlama I', 150, 1, 1, N'Zorunlu'),
(102, 'MAT1301_YZM', N'Matematik I (Yazılım)', 150, 1, 1, N'Zorunlu'),
(103, 'FIZ1301_YZM', N'Fizik I (Yazılım)', 150, 1, 1, N'Zorunlu'),
(104, 'YZM1107', N'Temel Bilgisayar Bilimleri', 60, 1, 1, N'Zorunlu'),
(105, 'YZM1113', N'Yazılım Müh. Kariyer Planlama', 60, 1, 1, N'Zorunlu'),
(106, 'YZM1108', N'Yazılım Mühendisliğine Giriş', 150, 2, 1, N'Zorunlu'),
(107, 'YZM1110', N'Algoritma ve Programlama II', 150, 2, 1, N'Zorunlu'),
(108, 'MAT1302_YZM', N'Matematik II (Yazılım)', 150, 2, 1, N'Zorunlu'),
(109, 'FIZ1302_YZM', N'Fizik II (Yazılım)', 150, 2, 1, N'Zorunlu'),

-- 2. Sınıf Güz / Bahar
(110, 'YZM2127', N'Yazılım Gereksinim Analizi', 150, 3, 1, N'Zorunlu'),
(111, 'YZM2113', N'Mühendislik Matematiği (Yazılım)', 150, 3, 1, N'Zorunlu'),
(112, 'YZM2123', N'Web Programlamaya Giriş', 150, 3, 1, N'Zorunlu'),
(113, 'YZM2125', N'Nesneye Yönelik Programlama', 150, 3, 1, N'Zorunlu'),
(114, 'YZM2111', N'Ayrık Yapılar', 150, 3, 1, N'Zorunlu'),
(115, 'YZM2135', N'Diferansiyel Denklemler', 80, 3, 1, N'Zorunlu'),
(116, 'CBU4403_YZM', N'İş Sağlığı ve Güvenliği I (Yazılım)', 60, 3, 1, N'Zorunlu'),
(117, 'YZM2122', N'Yazılım Yapımı', 150, 4, 1, N'Zorunlu'),
(118, 'YZM2124', N'Veri Yapıları', 150, 4, 1, N'Zorunlu'),
(119, 'YZM2118', N'Yazılım Mimarisi ve Tasarımı', 150, 4, 1, N'Zorunlu'),
(120, 'YZM2134', N'Yapay Zekada Matematiksel Yöntemler', 150, 4, 1, N'Zorunlu'),
(121, 'YZM2126', N'Veritabanı Sistemlerine Giriş', 150, 4, 1, N'Zorunlu'),
(122, 'YZM2206', N'Temel Elektronik (Yazılım)', 150, 4, 1, N'Zorunlu'),
(123, 'YZM2208', N'Yazılım Geliştirmede Çevik Yöntemler', 150, 4, 1, N'Seçmeli'),
(124, 'YZM2114', N'Olasılık ve İstatistik', 150, 4, 1, N'Zorunlu'),
(125, 'CBU4404_YZM', N'İş Sağlığı ve Güvenliği II (Yazılım)', 80, 4, 1, N'Zorunlu'),

-- 3. Sınıf Güz / Bahar
(126, 'YZM3107', N'Veritabanı Yönetim Sistemleri', 80, 5, 1, N'Zorunlu'),
(127, 'YZM3219', N'Servis Odaklı Mimari', 150, 5, 1, N'Seçmeli'),
(128, 'YZM3223', N'Makine Öğrenmesi', 150, 5, 1, N'Seçmeli'),
(129, 'YZM3109', N'Python Programlama', 80, 5, 1, N'Seçmeli'),
(130, 'YZM3215', N'İleri Web Programlama', 150, 5, 1, N'Seçmeli'),
(131, 'YZM3211', N'Bilgisayar Ağları', 60, 5, 1, N'Seçmeli'),
(132, 'YZM3111', N'Yazılım Sınama', 150, 5, 1, N'Zorunlu'),
(133, 'YZM3112', N'Algoritma Analizi ve Tasarımı', 150, 6, 1, N'Zorunlu'),
(134, 'YZM3229', N'Biçimsel Diller ve Otomata Teorisi', 60, 6, 1, N'Seçmeli'),
(135, 'YZM3231', N'Derin Öğrenme', 60, 6, 1, N'Seçmeli'),
(136, 'YZM3217', N'Yapay Zeka', 60, 6, 1, N'Seçmeli'),
(137, 'YZM3202', N'Kablosuz İletişim Ağları', 60, 6, 1, N'Seçmeli'),
(138, 'YZM3232', N'Siber Güvenlik', 60, 6, 1, N'Seçmeli'),
(139, 'YZM3108', N'İşletim Sistemleri', 150, 6, 1, N'Zorunlu'),
(140, 'YZM3214', N'Mobil Uygulama Geliştirme', 60, 6, 1, N'Seçmeli'),
(141, 'YZM3228', N'Nesnelerin İnterneti', 60, 6, 1, N'Seçmeli'),
(142, 'YZM3110', N'Yazılım Projesi Yönetimi', 150, 6, 1, N'Zorunlu'),
(143, 'YZM3222', N'Bulut Bilişim', 60, 6, 1, N'Seçmeli'),

-- 4. Sınıf Güz / Bahar
(144, 'YZM4331', N'Karar Destek Sistemleri', 80, 7, 1, N'Seçmeli'),
(145, 'ASD4205_YZM', N'Bilimsel Araştırma Yöntemleri ', 50, 8, 1, N'Zorunlu'),
(146, 'YZM4313', N'Profesyonel Yazılım Müh. Uyg.', 60, 8, 1, N'Zorunlu'),
(147, 'YZM4201', N'Yazılım Mühendisliğinde Özel Konular', 50, 7, 1, N'Seçmeli'),
(148, 'YZM4333', N'Veri Madenciliği', 150, 7, 1, N'Seçmeli'),
(149, 'YZM4317', N'Optimizasyon Teknikleri', 60, 7, 1, N'Seçmeli');

-- ==========================================
-- 4.2. ELEKTRİK MÜHENDİSLİĞİ DERSLERİ (GÜZ & BAHAR)
-- ==========================================
INSERT INTO dbo.Dersler (DersID, DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID, DersTuru) VALUES 
-- 1. Sınıf Güz / Bahar
(201, 'ELK1107', N'Bilgisayar Destekli Çizim', 60, 1, 2, N'Zorunlu'),
(202, 'MAT1301_ELK', N'Matematik-I (Elektrik)', 60, 1, 2, N'Zorunlu'),
(203, 'ELK1101', N'Lineer Cebir (Elektrik)', 60, 1, 2, N'Zorunlu'),
(204, 'FIZ1301_ELK', N'Fizik I (Elektrik)', 80, 1, 2, N'Zorunlu'),
(205, 'ELK1105', N'Elektrik Mühendisliğine Giriş', 60, 1, 2, N'Zorunlu'),
(206, 'ELK1106', N'Elektrik Ölçme Teknikleri', 60, 2, 2, N'Zorunlu'),
(207, 'ELK1104', N'Bilgisayar Programlama', 60, 2, 2, N'Zorunlu'),
(208, 'MAT1302_ELK', N'Matematik II (Elektrik)', 60, 2, 2, N'Zorunlu'),
(209, 'ELK1102', N'Elektrik Devreleri I', 60, 2, 2, N'Zorunlu'),
(210, 'FIZ1302_ELK', N'Fizik II (Elektrik)', 60, 2, 2, N'Zorunlu'),

-- 2. Sınıf Güz / Bahar
(212, 'ELK2107', N'Elektronik', 60, 3, 2, N'Zorunlu'),
(213, 'ELK2101', N'Elektrik Devreleri II (Elektrik)', 60, 3, 2, N'Zorunlu'),
(214, 'ADS2253_ELK', N'Bilimsel Araştırma Yöntemleri', 60, 3, 2, N'Zorunlu'),
(215, 'CBU4403_ELK', N'İş Sağlığı ve Güvenliği I (Elektrik)', 60, 3, 2, N'Zorunlu'),
(216, 'ELK2103', N'Elektromanyetik Alan Teorisi', 60, 3, 2, N'Zorunlu'),
(217, 'ELK2209', N'Sensörler ve Algılayıcılar', 60, 3, 2, N'Seçmeli'),
(218, 'ELK2105', N'Diferansiyel Denklemler (Elektrik)', 50, 3, 2, N'Zorunlu'),
(219, 'ELK2104', N'Aydınlatma Tekniği ve Tesis Projesi', 60, 4, 2, N'Zorunlu'),
(220, 'ELK2102', N'Sayısal Elektronik', 60, 4, 2, N'Zorunlu'),
(221, 'ELK2216', N'Elektrik Şalt Tesisleri', 60, 4, 2, N'Seçmeli'),
(222, 'ELK2218', N'Alternatif Enerji ve Modelleme', 60, 4, 2, N'Seçmeli'),
(223, 'ELK2110', N'Elektrik ve Elektromekanik Enerji Dönüşümü', 60, 4, 2, N'Zorunlu'),
(224, 'ELK2112', N'Ayrık Matematik (Elektrik)', 60, 4, 2, N'Zorunlu');

-- ==========================================
-- 4.3. MAKİNE MÜHENDİSLİĞİ DERSLERİ (GÜZ & BAHAR)
-- ==========================================
INSERT INTO dbo.Dersler (DersID, DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID, DersTuru) VALUES 
-- 1. Sınıf Güz / Bahar
(301, 'MAK1101', N'Teknik Resim A', 50, 1, 3, N'Zorunlu'),
(302, 'MAK1102_B', N'Teknik Resim B', 50, 1, 3, N'Zorunlu'),
(303, 'MAT1301_MAK', N'Matematik I (Makine)', 150, 1, 3, N'Zorunlu'),
(304, 'KİM1301_MAK', N'Kimya (Makine)', 150, 1, 3, N'Zorunlu'),
(305, 'FIZ1301_MAK', N'Fizik I (Makine)', 150, 1, 3, N'Zorunlu'),
(306, 'MAK1103', N'Makine Mühendisliğine Giriş', 150, 1, 3, N'Zorunlu'),
(307, 'MAK1102_A', N'Bilg. Destekli Teknik Resim A', 50, 2, 3, N'Zorunlu'),
(308, 'MAK1106', N'Bilg. Destekli Teknik Resim B', 50, 2, 3, N'Zorunlu'),
(309, 'MAK1302_MAK', N'Matematik II (Makine)', 80, 2, 3, N'Zorunlu'),
(310, 'ADS1232_MAK', N'Mühendislik Standartları II', 60, 2, 3, N'Zorunlu'),
(311, 'MAK1104', N'Statik I (Makine)', 150, 2, 3, N'Zorunlu'),
(312, 'FIZ1302_MAK', N'Fizik 2 (Makine)', 150, 2, 3, N'Zorunlu'),
(313, 'ADS1212_MAK', N'Çevre Politikaları', 60, 2, 3, N'Zorunlu'),
(314, 'MAK1216', N'Bilgisayar Bilimi ve Programlama', 150, 2, 3, N'Zorunlu'),
(315, 'MAK1212', N'Mühendislikte Teknik İngilizce', 50, 2, 3, N'Zorunlu'),

-- 2. Sınıf Güz / Bahar
(316, 'MAK2105', N'Malzeme Bilimi', 150, 3, 3, N'Zorunlu'),
(317, 'MAK2111', N'Endüstriyel Ölçme', 60, 3, 3, N'Zorunlu'),
(318, 'MAK2121', N'Müh. Deneysel Metotlar I', 60, 3, 3, N'Zorunlu'),
(319, 'MAK2109', N'Termodinamik I', 150, 3, 3, N'Zorunlu'),
(320, 'MAK2119', N'Mukavemet', 150, 3, 3, N'Zorunlu'),
(321, 'MAK2113_1', N'Temel İmalat İşlemleri I', 60, 3, 3, N'Zorunlu'),
(322, 'MAK2215', N'Mühendislikte Lab Uygulamaları I', 60, 3, 3, N'Zorunlu'),
(323, 'MAK2217', N'Mühendislikte Deneysel Enerji Uygulamaları I', 60, 3, 3, N'Zorunlu'),
(324, 'MAK2113_2', N'Dinamik I (Makine)', 80, 3, 3, N'Zorunlu'),
(325, 'MAK2103', N'Statik II (Makine)', 60, 3, 3, N'Zorunlu'),
(326, 'MAK2107', N'Akışkanlar Mekaniği I', 150, 3, 3, N'Zorunlu'),
(327, 'MAK2101', N'Mühendislik Matematiği I', 150, 3, 3, N'Zorunlu'),
(328, 'MAK2127', N'İstatistik I', 150, 3, 3, N'Zorunlu'),
(329, 'MAK2106', N'Mühendislik Malzemeleri', 80, 4, 3, N'Zorunlu'),
(330, 'MAK2120', N'Termodinamik II (Makine)', 150, 4, 3, N'Zorunlu'),
(331, 'MAK2114', N'İleri Matematik Uygulamaları', 150, 4, 3, N'Zorunlu'),
(332, 'MAK2220', N'Mühendislikte Deneysel Metotlar II', 60, 4, 3, N'Seçmeli'),
(333, 'MAK2212', N'Temel İmalat İşlemleri II', 60, 4, 3, N'Zorunlu'),
(334, 'MAK2214', N'Mühendislikte Lab Uygulamaları II', 60, 4, 3, N'Zorunlu'),
(335, 'MAK2216', N'Mühendislikte Deneysel Enerji Uygulamaları II', 60, 4, 3, N'Zorunlu'),
(336, 'MAK2104', N'Mukavemet I (Makine)', 150, 4, 3, N'Zorunlu'),
(337, 'MAK2108', N'Dinamik II (Makine)', 80, 4, 3, N'Zorunlu'),
(338, 'CBU4403_MAK_1', N'İş Sağlığı ve Güvenliği I (Makine)', 80, 4, 3, N'Zorunlu'),
(339, 'MAK2110', N'Isı Transferi', 150, 4, 3, N'Zorunlu'),
(340, 'MAK2102', N'Mühendislik Matematiği II', 80, 4, 3, N'Zorunlu'),
(341, 'MAK2132', N'Sayısal Analiz', 60, 4, 3, N'Zorunlu'),
(342, 'MAK2116', N'Mukavemet II (Makine)', 150, 4, 3, N'Zorunlu'),

-- 3. Sınıf Güz / Bahar
(343, 'MAK3109', N'Bilgisayar Destekli Mühendislik', 60, 5, 3, N'Zorunlu'),
(344, 'MAK3107', N'Sistem Analizi ve Kontrol', 60, 5, 3, N'Zorunlu'),
(345, 'MAK3209_1', N'Kariyer Planlama', 60, 5, 3, N'Zorunlu'),
(346, 'MAK3105', N'Mekanizma Tekniği', 60, 5, 3, N'Zorunlu'),
(347, 'MAK3101', N'Makine Elemanları I', 80, 5, 3, N'Zorunlu'),
(348, 'MAK3112_1', N'Üretim Yöntemleri I', 60, 5, 3, N'Zorunlu'),
(349, 'MAK3209_2', N'Plastik Malzemeler', 60, 5, 3, N'Seçmeli'),
(350, 'MAK3216', N'Isıl İşlemler', 60, 5, 3, N'Seçmeli'),
(351, 'MAK3103', N'Mukavemet II (Makine)', 60, 5, 3, N'Zorunlu'),
(352, 'CBU4403_MAK_2', N'İş Sağlığı ve Güvenliği I (Makine)', 60, 5, 3, N'Zorunlu'),
(353, 'MAK3116', N'Makine Dinamiği', 50, 6, 3, N'Zorunlu'),
(354, 'MAK3112_2', N'Üretim Yönetimleri I', 60, 6, 3, N'Zorunlu'),
(355, 'MAK3108', N'Elektronik ve Otomasyon Bilgisi', 80, 6, 3, N'Zorunlu'),
(356, 'MAK3122', N'Üretim Yöntemleri II', 50, 6, 3, N'Zorunlu'),
(357, 'MAK3124', N'Isı Transferi II', 150, 6, 3, N'Zorunlu'),
(358, 'MAK3110', N'Mühendislik Yönetimi ve Ekonomisi', 50, 6, 3, N'Zorunlu'),
(359, 'MAK3104', N'İstatistik II (Makine)', 50, 6, 3, N'Zorunlu'),
(360, 'MAK3102', N'Makine Elemanları II', 60, 6, 3, N'Zorunlu'),
(361, 'CBU4404_MAK', N'İş Sağlığı ve Güvenliği II (Makine)', 80, 6, 3, N'Zorunlu'),

-- 4. Sınıf Güz / Bahar
(362, 'MAK4222', N'Modern İmalat Yöntemleri', 60, 7, 3, N'Seçmeli'),
(363, 'MAK4263', N'Otomasyon ve Robotik', 60, 7, 3, N'Seçmeli'),
(364, 'MAK4228', N'Hidrolik Pnömatik', 60, 7, 3, N'Seçmeli'),
(365, 'MAK4276', N'İleri Bilgisayar Programlama', 60, 7, 3, N'Seçmeli'),
(366, 'MAK4277', N'Eklemeli İmalat', 60, 7, 3, N'Seçmeli'),
(367, 'MAK4278', N'Cnc İmalat Teknolojisi', 60, 7, 3, N'Seçmeli'),
(368, 'MAK4245', N'Hareket Kontrol Sistemleri', 60, 7, 3, N'Seçmeli'),
(369, 'MAK4279', N'Bilgisayar Destekli İmalat', 60, 7, 3, N'Seçmeli'),
(370, 'MAK4205', N'Talaşlı İmalat Teknolojisi', 60, 8, 3, N'Seçmeli'),
(371, 'MAK4223', N'Kaynak Teknolojisi', 60, 8, 3, N'Seçmeli');

-- ==========================================
-- 4.4. MEKATRONİK MÜHENDİSLİĞİ DERSLERİ (GÜZ & BAHAR)
-- ==========================================
INSERT INTO dbo.Dersler (DersID, DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID, DersTuru) VALUES 
-- 1. Sınıf Güz / Bahar
(401, 'MKR1101', N'Mekatronik Mühendisliğine Giriş', 150, 1, 4, N'Zorunlu'),
(402, 'KIM1311_MKR', N'Kimya (Mekatronik)', 150, 1, 4, N'Zorunlu'),
(403, 'MAT1301_MKR', N'Matematik I (Mekatronik)', 150, 1, 4, N'Zorunlu'),
(404, 'FIZ1301_MKR', N'Fizik I (Mekatronik)', 150, 1, 4, N'Zorunlu'),
(405, 'MKR1103', N'Bilgisayar Bilimi ve Prog. Giriş', 60, 1, 4, N'Zorunlu'),
(406, 'MKR1105', N'Kariyer Planlama (Mekatronik)', 60, 1, 4, N'Zorunlu'),
(407, 'MAT1302_MKR', N'Matematik II (Mekatronik)', 150, 2, 4, N'Zorunlu'),
(408, 'MKR1106', N'Elektrik Devreleri I (Mekatronik)', 150, 2, 4, N'Zorunlu'),
(409, 'MKR1104', N'Bilgisayar Programlama', 150, 2, 4, N'Zorunlu'),
(410, 'ADS1208_MKR', N'Rapor Hazırlama Teknikleri', 60, 2, 4, N'Zorunlu'),
(411, 'MKR1108_A', N'Bilgisayar Destekli Teknik Resim A', 60, 2, 4, N'Zorunlu'),
(412, 'MKR1108_B', N'Bilgisayar Destekli Teknik Resim B', 60, 2, 4, N'Zorunlu'),
(413, 'MKR1102', N'Statik I (Mekatronik)', 80, 2, 4, N'Zorunlu'),
(414, 'FIZ1302_MKR', N'Fizik II (Mekatronik)', 150, 2, 4, N'Zorunlu'),

-- 2. Sınıf Güz / Bahar
(415, 'MKR2109', N'Diferansiyel Denklemler (Mekatronik)', 150, 3, 4, N'Zorunlu'),
(416, 'MKR2113', N'Mantık Devreleri', 150, 3, 4, N'Zorunlu'),
(417, 'MKT2115', N'Mühendisler için Kimya', 150, 3, 4, N'Zorunlu'),
(418, 'MKT2105', N'Statik (Mekatronik)', 60, 3, 4, N'Zorunlu'),
(419, 'MKR2117', N'Mukavemet I (Mekatronik)', 150, 3, 4, N'Zorunlu'),
(420, 'MKT2109', N'Malzeme Bilimi (Mekatronik)', 80, 3, 4, N'Zorunlu'),
(421, 'MKR2111', N'Dinamik (Mekatronik)', 150, 3, 4, N'Zorunlu'),
(422, 'MKR2201', N'Elektrik Devreleri II (Mekatronik)', 150, 3, 4, N'Zorunlu'),
(423, 'CBU4403_MKR_1', N'İş Sağlığı ve Güvenliği I (Mekatronik) ', 60, 3, 4, N'Zorunlu'),
(424, 'MKR2110', N'Algılayıcılar ve Aktüatörler I', 150, 4, 4, N'Zorunlu'),
(425, 'MKT2108', N'Makine Teorisi', 60, 4, 4, N'Zorunlu'),
(426, 'MKR2120', N'Lineer Cebir (Mekatronik)', 150, 4, 4, N'Zorunlu'),
(427, 'MKR2202', N'Mühendislik Matematiği II', 150, 4, 4, N'Zorunlu'),
(428, 'MKR2112', N'Elektrik Makineleri', 150, 4, 4, N'Zorunlu'),
(429, 'MKR2114', N'Elektronik Devreler ve Analizi', 150, 4, 4, N'Zorunlu'),
(430, 'MKT2110', N'Makine Elemanları', 150, 4, 4, N'Zorunlu'),
(431, 'SSD2236', N'Rapor Hazırlama Teknikleri', 60, 4, 4, N'Zorunlu'),
(432, 'MKT2106', N'Mukavemet II (Mekatronik)', 60, 4, 4, N'Zorunlu'),
(433, 'MKR2216', N'Elektronik Malzemeler', 50, 4, 4, N'Seçmeli'),
(434, 'MKR2118', N'Malzeme Kimyası ve Bilimi', 80, 4, 4, N'Zorunlu'),
(435, 'CBU4403_MKR_2', N'İş Sağlığı ve Güvenliği II (Mekatronik) ', 60, 4, 4, N'Zorunlu'),

-- 3. Sınıf Güz / Bahar
(436, 'MKT3101', N'Otomatik Kontrol I', 150, 5, 4, N'Zorunlu'),
(437, 'MKT3109', N'Mikrokontrolörler', 150, 5, 4, N'Zorunlu'),
(438, 'MKT3111', N'Güç Elektroniği ve Sürücü Sis.', 150, 5, 4, N'Zorunlu'),
(439, 'MKT3107_A', N'Bilgisayar Destekli Tasarım A', 60, 5, 4, N'Zorunlu'),
(440, 'MKT3107_B', N'Bilgisayar Destekli Tasarım B', 60, 5, 4, N'Zorunlu'),
(441, 'MKT3105', N'Akışkanlar Mekaniği', 50, 5, 4, N'Zorunlu'),
(442, 'MKT3103', N'Hidrolik ve Pnömatik Sistemleri', 150, 5, 4, N'Zorunlu'),
(443, 'CBU4403_MKR_3', N'İş Sağlığı ve Güvenliği I (Mekatronik) ', 60, 5, 4, N'Zorunlu'),
(444, 'MKT3104', N'Algılayıcılar ve Aktüatörler II', 50, 6, 4, N'Zorunlu'),
(445, 'MKT3110', N'Endüstriyel Otomasyon Sistemleri', 150, 6, 4, N'Zorunlu'),
(446, 'MKT3108', N'Bilgisayar Destekli Üretim', 60, 6, 4, N'Zorunlu'),
(447, 'MKT3106', N'Termodinamik ve Isı Transferi', 150, 6, 4, N'Zorunlu'),
(448, 'MKT3102', N'Otomatik Kontrol II', 50, 6, 4, N'Zorunlu'),
(449, 'MKT3112', N'Robotik', 150, 6, 4, N'Zorunlu'),
(450, 'CBU4403_MKR_4', N'İş Sağlığı ve Güvenliği II (Mekatronik) ', 60, 6, 4, N'Zorunlu'),

-- 4. Sınıf Güz / Bahar
(451, 'MKT4235', N'Üretim Yöntemleri', 60, 7, 4, N'Seçmeli'),
(452, 'MKT4219', N'Sayısal İşaret İşleme', 60, 7, 4, N'Seçmeli'),
(453, 'MKT4232', N'Kompozit Yapılar', 60, 7, 4, N'Seçmeli'),
(454, 'MKT4224', N'Bilgisayar Destekli Optimizasyon', 60, 7, 4, N'Seçmeli'),
(455, 'MKT4230', N'Otomotiv Mekatroniği', 60, 7, 4, N'Seçmeli'),
(456, 'MKT4204', N'Alternatif Enerji Sistemleri', 60, 8, 4, N'Seçmeli'),
(457, 'MKT4207', N'Tersine Müh. ve Hızlı Prototipleme', 60, 8, 4, N'Seçmeli');

-- ==========================================
-- 4.5. ENERJİ SİSTEMLERİ MÜHENDİSLİĞİ DERSLERİ (GÜZ & BAHAR)
-- ==========================================
INSERT INTO dbo.Dersler (DersID, DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID, DersTuru) VALUES 
-- 1. Sınıf Güz / Bahar
(501, 'ESM1109', N'Kariyer Planlama (Enerji)', 60, 1, 5, N'Zorunlu'),
(502, 'FIZ1301_ESM', N'Fizik I (Enerji)', 60, 1, 5, N'Zorunlu'),
(503, 'MAT1301_ESM', N'Matematik I (Enerji)', 60, 1, 5, N'Zorunlu'),
(504, 'ESM1103', N'Enerji Sistemleri Mühendisliğine Giriş', 60, 1, 5, N'Zorunlu'),
(505, 'KIM1311_ESM', N'Kimya (Enerji)', 60, 1, 5, N'Zorunlu'),
(506, 'ESM1107', N'Temel Bilgisayar Bilimleri (Enerji)', 60, 1, 5, N'Zorunlu'),
(507, 'ESM1102', N'Bilgisayar Destekli Teknik Resim', 50, 2, 5, N'Zorunlu'),
(508, 'ESM1302', N'Bilgisayar Bilimi ve Programlama', 60, 2, 5, N'Zorunlu'),
(509, 'ESM1108', N'Algoritma ve Programlamanın Temelleri', 60, 2, 5, N'Zorunlu'),
(510, 'ESM1104', N'Sosyal Sorumluluk Projesi', 80, 2, 5, N'Zorunlu'),
(511, 'MAT1302_ESM', N'Matematik II (Enerji)', 150, 2, 5, N'Zorunlu'),
(512, 'FIZ1302_ESM', N'Fizik II (Enerji)', 60, 2, 5, N'Zorunlu'),
(513, 'ESM1106', N'Elektrik Devreleri I (Enerji)', 60, 2, 5, N'Zorunlu'),

-- 2. Sınıf Güz / Bahar
(514, 'ESM2113', N'Elektromekanik Enerji Dönüşümü', 60, 3, 5, N'Zorunlu'),
(515, 'ESM2111', N'Elektrik Devreleri I (Enerji)', 150, 3, 5, N'Zorunlu'),
(516, 'ESM2121', N'Elektrik Devreleri II (Enerji)', 150, 3, 5, N'Zorunlu'), 
(517, 'ESM2107', N'Statik (Enerji)', 150, 3, 5, N'Zorunlu'),                
(518, 'ESM2205', N'Rüzgâr Enerjisi Teknolojileri', 60, 3, 5, N'Zorunlu'),
(519, 'ESM2013', N'Akışkanlar Mekaniği I', 60, 3, 5, N'Zorunlu'),
(520, 'ESM2019', N'Termodinamik I', 60, 3, 5, N'Zorunlu'),
(521, 'ESM2123', N'Temel Elektronik (Enerji)', 60, 3, 5, N'Zorunlu'),
(522, 'ESM2105', N'Malzeme Bilimi (Enerji)', 60, 3, 5, N'Zorunlu'),
(523, 'ESM2101', N'Mühendislik Matematiği (Enerji)', 60, 3, 5, N'Zorunlu'),
(524, 'ESM2207', N'Çevre ve Enerji', 60, 3, 5, N'Zorunlu'),
(525, 'ESM2106', N'Ölçme Tekniği (Enerji)', 60, 4, 5, N'Zorunlu'),
(526, 'ESM2116', N'Endüstriyel Ölçme ve Kontrol', 60, 4, 5, N'Zorunlu'),
(527, 'ESM2104', N'Mukavemet (Enerji)', 60, 4, 5, N'Zorunlu'),
(528, 'ESM2110', N'Termodinamik II', 60, 4, 5, N'Zorunlu'),
(529, 'ESM2108', N'Akışkanlar Mekaniği II', 60, 4, 5, N'Zorunlu'),
(530, 'ADS2208_ESM', N'Rapor Hazırlama Teknikleri', 60, 4, 5, N'Zorunlu'),
(531, 'ESM2102', N'Dinamik (Enerji)', 60, 4, 5, N'Zorunlu'),
(532, 'ESM2112', N'Elektrik Makineleri (Enerji)', 60, 4, 5, N'Zorunlu'),
(533, 'ESM2210', N'Petrol, Doğalgaz ve Bor Teknolojileri', 150, 4, 5, N'Zorunlu'),
(534, 'ESM2204_1', N'Güneş Enerjisi Sistemleri ve Tasarımı I', 150, 4, 5, N'Seçmeli'),

-- 3. Sınıf Güz / Bahar
(535, 'CBU4403_ESM_1', N'İş Sağlığı ve Güvenliği I (Enerji) ', 60, 5, 5, N'Zorunlu'),
(536, 'ESM3101', N'Rüzgar Enerjisi Teknolojileri', 60, 5, 5, N'Zorunlu'),
(537, 'ESM3105', N'Makine Elemanları', 150, 5, 5, N'Zorunlu'),
(538, 'ESM3107', N'Güç Elektroniği (Enerji)', 60, 5, 5, N'Zorunlu'),
(539, 'ESM3109', N'Enerji Mühendisliği Laboratuvarı I', 60, 5, 5, N'Zorunlu'),
(540, 'ESM3103', N'Kazanlar ve Yanma Teknolojileri', 60, 5, 5, N'Zorunlu'),
(541, 'ESM3113', N'Isı Transferi (Enerji)', 60, 5, 5, N'Zorunlu'),
(542, 'ESM2204_2', N'Güneş Enerjisi Sistemleri ve Tasarımı II', 150, 6, 5, N'Seçmeli'),
(543, 'ESM3106', N'Enerji İletimi ve Dağıtımı', 60, 6, 5, N'Zorunlu'),
(544, 'ESM3108', N'Güç Sistemleri Analizi', 60, 6, 5, N'Zorunlu'),
(545, 'ESM3104', N'Yenilenebilir Enerji Kaynakları', 60, 6, 5, N'Zorunlu'),
(546, 'ESM3110', N'Enerji Mühendisliği Laboratuvarı II', 60, 6, 5, N'Zorunlu'),
(547, 'ESM3102', N'Enerji Verimliliği ve Yönetimi', 60, 6, 5, N'Zorunlu'),
(548, 'ESM3112', N'Mühendislik Tasarımı (Enerji)', 60, 6, 5, N'Zorunlu'),
(549, 'ESM3202', N'Isı Değiştiriciler', 60, 6, 5, N'Seçmeli'),
(550, 'CBU4404_ESM', N'İş Sağlığı ve Güvenliği II (Enerji) ', 60, 6, 5, N'Zorunlu'),

-- 4. Sınıf Güz / Bahar
(551, 'ESM4211', N'Enerji Sistemlerinde Simülasyon', 60, 7, 5, N'Seçmeli'),
(552, 'ESM4227', N'İçten Yanmalı Motorlar', 60, 7, 5, N'Seçmeli'),
(553, 'ESM4215', N'Soğutma Tekniği ve Uygulamaları', 60, 7, 5, N'Seçmeli'),
(554, 'ESM4101', N'Mühendislikte Bilgisayar Uygulamaları', 60, 7, 5, N'Zorunlu'),
(555, 'ESM4203', N'Hidrojen Enerjisi ve Uygulamaları', 60, 7, 5, N'Seçmeli'),
(556, 'ESM4207', N'Enerji Kanunları ve Düzenlemeleri', 60, 8, 5, N'Zorunlu'),
(557, 'ESM4209', N'Petrol, Doğalgaz ve Bor Teknolojileri', 150, 8, 5, N'Zorunlu');

SET IDENTITY_INSERT dbo.Dersler OFF;

-- ========================================================
-- 5. PDF PROGRAMLARINDAN ALINAN GERÇEK AKADEMİK PERSONEL
-- ========================================================
SET IDENTITY_INSERT dbo.Personel ON;
INSERT INTO dbo.Personel (PersonelID, Unvan, Ad, Soyad, BolumID) VALUES 
-- Yazılım Mühendisliği Öğretim Üyeleri
(1, N'Prof. Dr.', N'Akın', N'Özçift', 1),
(2, N'Prof. Dr.', N'Ersin', N'Aslan', 1),
(3, N'Doç. Dr.', N'Emin', N'Borandağ', 1),
(4, N'Doç. Dr.', N'Osman', N'Altay', 1),
(5, N'Doç. Dr.', N'Fatih', N'Yücalar', 1),
(6, N'Doç. Dr.', N'Müge', N'Özçevik', 1),
(7, N'Doç. Dr.', N'Elif', N'Varol Altay', 1),
(8, N'Doç. Dr.', N'Yusuf', N'Özçevik', 1),
(9, N'Dr. Öğr. Üyesi', N'İrfan', N'Aygün', 1),
(10, N'Arş. Gör.', N'Elif Nur', N'Aygün', 1),
(11, N'Arş. Gör.', N'Güney', N'Kaya', 1),
(12, N'Arş. Gör.', N'Süleyman', N'Çetiner', 1),
(13, N'Arş. Gör.', N'Tuğba', N'Çelikten', 1),

-- Elektrik Mühendisliği Öğretim Üyeleri
(14, N'Doç. Dr.', N'Göksu', N'Görel', 2),
(15, N'Doç. Dr.', N'İsmail', N'Yabanova', 2),
(16, N'Prof. Dr.', N'Kıvanç', N'Başaran', 2),
(17, N'Dr. Öğr. Üyesi', N'Bayram Melih', N'Yılmaz', 2),
(18, N'Dr. Öğr. Üyesi', N'Yılmaz Seryar', N'Arıkuşu', 2),

-- Makine Mühendisliği Öğretim Üyeleri
(131, N'Doç. Dr.', N'Fikret', N'Sönmez', 3),
(141, N'Dr. Öğr. Üyesi', N'Hamza', N'Taş', 3),
(151, N'Dr. Öğr. Üyesi', N'Ayşegül G.', N'Çelik', 3),
(161, N'Dr. Öğr. Üyesi', N'Deniz Ç.', N'Özkan', 3),
(171, N'Dr. Öğr. Üyesi', N'Mehmet Mert', N'İlman', 3),
(181, N'Prof. Dr.', N'Ahmet Murat', N'Pınar', 3),
(201, N'Prof. Dr.', N'Mustafa', N'Aydın', 3),
(202, N'Dr. Öğr. Üyesi', N'Selda', N'Kayral', 3),
(203, N'Doç. Dr.', N'Serkan', N'Çaşka', 3),
(204, N'Dr. Öğr. Üyesi', N'Recep Onur', N'Uzun', 3),
(205, N'Arş. Gör.', N'Ömer', N'İlhan', 3),
(206, N'Arş. Gör.', N'Büşranur', N'Keser', 3),

-- Mekatronik Mühendisliği Öğretim Üyeleri
(211, N'Doç. Dr.', N'Ali', N'Uysal', 4),
(221, N'Prof. Dr.', N'Mehmet', N'Ayvacıklı', 4),
(231, N'Prof. Dr.', N'İbrahim Fadıl', N'Soykök', 4),
(241, N'Dr. Öğr. Üyesi', N'Nilay', N'Küçükdoğan Öztürk', 4),
(242, N'Dr. Öğr. Üyesi', N'Alkın Yılmaz', N'Akter', 4),
(243, N'Dr. Öğr. Üyesi', N'Ethem', N'Kelekçi', 4),
(244, N'Arş. Gör. Dr.', N'Seda', N'Vatan Can', 4),
(245, N'Arş. Gör.', N'Kübra', N'Tural', 4),

-- Enerji Sistemleri Mühendisliği Öğretim Üyeleri
(271, N'Dr. Öğr. Üyesi', N'Özgür', N'Solmaz', 5),
(281, N'Prof. Dr.', N'Eşref', N'Baysal', 5),
(291, N'Dr. Öğr. Üyesi', N'Ayşe Bilgen', N'Aksoy', 5),
(301, N'Doç. Dr.', N'Mustafa', N'Akkaya', 5),
(311, N'Dr. Öğr. Üyesi', N'Nezir Yağız', N'Çam', 5),
(321, N'Arş. Gör. Dr.', N'Elif Merve', N'Bahar', 5),
(331, N'Arş. Gör.', N'Menal', N'İlhan', 5),
(341, N'Arş. Gör.', N'Mert', N'Ökten', 5);

SET IDENTITY_INSERT dbo.Personel OFF;

-- ========================================================
-- 6. "IZINLI/MAZERETLI" GÜN KURALI TEST KAYITLARI
-- ========================================================
SET IDENTITY_INSERT dbo.Personel_Durum ON;
INSERT INTO dbo.Personel_Durum (DurumID, PersonelID, Tarih, OturumID, Uygun, MazeretTuru) VALUES
-- Ersin Aslan hocayı sınav günü 2. oturumda izinli yapıyoruz. Algoritma bunu atamamalı!
(1, 2, '2026-06-15', 2, 0, N'İzinli / Mazeretli'),
-- Fatih Yücalar hocayı 3. oturumda mazeretli yapıyoruz.
(2, 1, '2026-06-15', 3, 0, N'Danışmanlık Saati');
SET IDENTITY_INSERT dbo.Personel_Durum OFF;

-- ========================================================
-- 7. SUNUM ANINDA OTOMATİK ATANACAK SINAV PROGRAMI HAVUZU
-- ========================================================
SET IDENTITY_INSERT dbo.Sinavlar ON;
-- 15 Haziran 2026 Pazartesi Günü Planlanan Sınavlar
INSERT INTO dbo.Sinavlar (SinavID, DersID, Tarih, OturumID) VALUES 
-- Test Senaryosu 1: Dönem/Yarıyıl Çakışması Kontrolü
(1, 120, '2026-06-15', 2),   -- YZM2126 (Veritabanı Sistemlerine Giriş) -> 150 Kişi (En az 3 Büyük Amfi ister)
(2, 131, '2026-06-15', 4),   -- YZM3112 (Algoritma Analizi ve Tasarımı) -> 150 Kişi

-- Test Senaryosu 2: Ortak Havuz Sistemini Zorlama (Kendi hoca sayısı yetmeyecek)
(3, 118, '2026-06-15', 4);   -- YZM2118 (Yazılım Mimarisi ve Tasarımı) -> 150 Kişi
SET IDENTITY_INSERT dbo.Sinavlar OFF;

-- ===================================================================
-- 8. MEVCUT CANLI ATAMA DURUMLARI (Sunum Başlangıç Kanıtı)
-- ===================================================================
SET IDENTITY_INSERT dbo.Sinav_Salonlari ON;
INSERT INTO dbo.Sinav_Salonlari (SinavSalonID, SinavID, DerslikID) VALUES
(1, 1, 11), -- 1 nolu sınava (Veritabanı) 209 nolu Amfi atandı
(2, 1, 12), -- 1 nolu sınava (Veritabanı) 210 nolu Amfi atandı
(3, 1, 13); -- 1 nolu sınava (Veritabanı) 310 nolu Amfi atandı
SET IDENTITY_INSERT dbo.Sinav_Salonlari OFF;

SET IDENTITY_INSERT dbo.Gozetmen_Atamalari ON;
INSERT INTO dbo.Gozetmen_Atamalari (GozetmenAtamaID, SinavSalonID, PersonelID, AtamaKaynak) VALUES
(1, 1, 4, N'Kendi Bölümü'), -- İrfan Aygün -> Amfi 209
(2, 2, 3, N'Kendi Bölümü'); -- Emin Borandağ -> Amfi 210

-- Ortak Havuz kuralını doğrulamak amacıyla Mekatronik hocasını 3. amfiye atıyoruz
INSERT INTO dbo.Gozetmen_Atamalari (GozetmenAtamaID, SinavSalonID, PersonelID, AtamaKaynak) VALUES
(3, 3, 211, N'Ortak Havuz'); -- Ali Uysal (Mekatronik Müh.) -> Amfi 310
SET IDENTITY_INSERT dbo.Gozetmen_Atamalari OFF;