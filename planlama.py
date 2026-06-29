from fastapi import APIRouter, Body, HTTPException
from database import get_connection_info, is_mock_mode, get_sql_connection

router = APIRouter()


# =========================================================
# ORTAK SQL YARDIMCI FONKSIYONLAR
# =========================================================

def sql_hatasini_temizle(e: Exception) -> str:
    hata = str(e)
    if hasattr(e, 'args') and len(e.args) > 1:
        hata = e.args[1]
    if "[SQL Server]" in hata:
        # Karmaşık ODBC kısımlarını atıp sadece senin RAISERROR metnini alır
        hata = hata.split("[SQL Server]")[-1].split("(")[0].strip()
    return hata

def _row_to_dict(cursor, row):
    columns = [col[0] for col in cursor.description]
    return {columns[i]: row[i] for i in range(len(columns))}


def _fetch_all(query, params=None):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()
        cursor.execute(query, params or [])
        if cursor.description is None:
            return []
        rows = cursor.fetchall()
        return [_row_to_dict(cursor, row) for row in rows]
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


def _fetch_one(query, params=None):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()
        cursor.execute(query, params or [])
        row = cursor.fetchone()
        if not row:
            return None
        return _row_to_dict(cursor, row)
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


def _execute_non_query(query, params=None):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()
        cursor.execute(query, params or [])
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


def _execute_returning(query, params=None):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()
        cursor.execute(query, params or [])
        rows = []
        if cursor.description is not None:
            rows = [_row_to_dict(cursor, row) for row in cursor.fetchall()]
        conn.commit()
        return rows
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


def _get(data, *keys, default=None):
    """Frontend farklı isimlerle veri gönderebilir; hepsini destekler."""
    for key in keys:
        if key in data and data[key] is not None and data[key] != "":
            return data[key]
    return default


def _require(value, message):
    if value is None or value == "":
        raise HTTPException(status_code=400, detail=message)
    return value


# =========================================================
# RESMI DERSLIK / OTURUM / DERS KONTENJAN KURALLARI
# =========================================================

KUCUK_SINIFLAR = {"205", "206", "207", "208", "305", "306", "307", "308"}
ORTA_SINIF_KONTENJANLARI = {"309": 80, "311": 50}
BUYUK_SINIFLAR = {"209", "210", "310", "409", "410"}

OTURUM_KURALLARI = [
    {"oturum_id": 1, "tanim": "Sabah-1", "baslangic_saat": "09:00", "bitis_saat": "10:00"},
    {"oturum_id": 2, "tanim": "Sabah-2", "baslangic_saat": "10:30", "bitis_saat": "11:30"},
    {"oturum_id": 3, "tanim": "Öğle", "baslangic_saat": "12:00", "bitis_saat": "13:00"},
    {"oturum_id": 4, "tanim": "Öğleden Sonra-1", "baslangic_saat": "13:45", "bitis_saat": "14:45"},
    {"oturum_id": 5, "tanim": "Öğleden Sonra-2", "baslangic_saat": "15:15", "bitis_saat": "16:30"},
]


def resmi_ders_kontenjani_hesapla(derslik_adi):
    """Dersin işlendiği sınıfa göre resmi ders öğrenci kontenjanını döndürür."""
    ad = str(derslik_adi).strip()

    if ad in KUCUK_SINIFLAR:
        return 60
    if ad in ORTA_SINIF_KONTENJANLARI:
        return ORTA_SINIF_KONTENJANLARI[ad]
    if ad in BUYUK_SINIFLAR:
        return 150

    return None


# =========================================================
# SISTEM / KONTROL
# =========================================================
@router.get("/sinav-salonlari/{sinav_id}")
def get_sinav_salonlari(sinav_id: int):
    return _fetch_all("""
        SELECT
            SS.SinavSalonID,
            SS.SinavID,
            SS.DerslikID,
            DL.Ad AS DerslikAdi,
            DL.Kapasite,
            DL.Tip,
            S.Tarih,
            S.OturumID,
            O.Tanim AS Oturum,
            D.DersKodu,
            D.Ad AS DersAdi
        FROM dbo.Sinav_Salonlari SS
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
        INNER JOIN dbo.Oturumlar O ON S.OturumID = O.OturumID
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        WHERE SS.SinavID = ?
        ORDER BY SS.SinavSalonID
    """, [sinav_id])

@router.get("/health")
def health_check():
    return {
        "status": "ok",
        "message": "Backend çalışıyor"
    }


@router.get("/db/status")
def db_status():
    return get_connection_info()


@router.get("/app/mode")
def app_mode():
    return {
        "use_mock": is_mock_mode(),
        "mode": "MOCK" if is_mock_mode() else "DATABASE",
        "message": (
            "Uygulama şu an mock verilerle çalışıyor."
            if is_mock_mode()
            else "Uygulama gerçek SQL Server bağlantısı ile çalışıyor."
        )
    }


@router.get("/db/service-status")
def db_service_status():
    return {
        "message": "SQL servis katmanı aktif.",
        "durum": "Bu dosyada ekleme/güncelleme/atama işlemleri SQL Server'a yazacak şekilde düzenlendi.",
        "database": get_connection_info()
    }


@router.get("/resmi-kurallar")
def resmi_kurallar():
    return {
        "sinav_salonlari": {
            "kucuk_siniflar": {"salon_kapasitesi": 36, "derslikler": sorted(KUCUK_SINIFLAR)},
            "orta_siniflar": [
                {"derslik": "309", "salon_kapasitesi": 40},
                {"derslik": "311", "salon_kapasitesi": 50}
            ],
            "buyuk_siniflar": {"salon_kapasitesi": 60, "derslikler": sorted(BUYUK_SINIFLAR)}
        },
        "ders_kontenjanlari": {
            "kucuk_siniflarda_islenen_dersler": 60,
            "309da_islenen_dersler": 80,
            "311de_islenen_dersler": 50,
            "buyuk_siniflarda_islenen_dersler": 150
        },
        "oturumlar": OTURUM_KURALLARI,
        "not": "Dersler tablosunda DerslikID yoktur. Ders kontenjanı Dersler.OgrenciSayisi alanında tutulur. Sınav salon kapasitesi Derslikler.Kapasite alanındadır."
    }


@router.get("/dersler/kontenjan-hesapla")
def ders_kontenjan_hesapla(derslik_adi: str):
    ders_kontenjani = resmi_ders_kontenjani_hesapla(derslik_adi)
    if ders_kontenjani is None:
        raise HTTPException(status_code=400, detail="Bu derslik için resmi ders kontenjanı tanımlı değil.")

    salon = _fetch_one("""
        SELECT TOP 1 DerslikID, Ad, Kapasite, Tip, Kat, Aktif
        FROM dbo.Derslikler
        WHERE Ad = ?
    """, [derslik_adi])

    return {
        "derslik": derslik_adi,
        "sinav_salon_kapasitesi": salon["Kapasite"] if salon else None,
        "ders_kontenjani": ders_kontenjani,
        "not": "Salon kapasitesi sınavda kullanılacak kapasitedir; ders kontenjanı Dersler.OgrenciSayisi alanına yazılır."
    }


@router.get("/sql/eslesmeler")
def sql_eslesmeleri():
    return {
        "crud_endpointleri": {
            "GET /api/bolumler": "SELECT FROM dbo.Bolumler",
            "POST /api/bolumler": "INSERT INTO dbo.Bolumler",
            "GET /api/dersler": "SELECT FROM dbo.Dersler",
            "POST /api/dersler": "INSERT INTO dbo.Dersler",
            "GET /api/derslikler": "SELECT FROM dbo.Derslikler",
            "POST /api/derslikler": "INSERT INTO dbo.Derslikler",
            "GET /api/oturumlar": "SELECT FROM dbo.Oturumlar",
            "POST /api/oturumlar": "INSERT INTO dbo.Oturumlar",
            "GET /api/personeller": "SELECT FROM dbo.Personel",
            "POST /api/personeller": "INSERT INTO dbo.Personel",
            "GET /api/personel-durum": "SELECT FROM dbo.Personel_Durum",
            "POST /api/personel-durum": "INSERT INTO dbo.Personel_Durum"
        },
        "stored_procedure_endpointleri": {
            "POST /api/sinavlar": "EXEC dbo.sp_SinavOlustur",
            "POST /api/salon-atama/ata": "EXEC dbo.sp_SalonAtamaYap",
            "POST /api/gozetmen-atama/ata": "EXEC dbo.sp_GozetmenAta",
            "PUT /api/sinavlar/{sinav_id}/saat-guncelle": "EXEC dbo.sp_SinavSaatiGuncelle",
            "POST /api/backup/yedek-al": "EXEC dbo.sp_VeritabaniYedekAl"
        },
        "view_endpointleri": {
            "GET /api/sinavlar": "SELECT FROM dbo.vw_SinavProgrami",
            "GET /api/raporlar/sinav-programi": "SELECT FROM dbo.vw_SinavProgrami",
            "GET /api/raporlar/gozetmen-gorev-dagilimi": "SELECT FROM dbo.vw_GozetmenGorevDagilimi",
            "GET /api/raporlar/derslik-kullanim": "SELECT FROM dbo.vw_DerslikKullanimRaporu",
            "GET /api/raporlar/bolum-sinav-yogunlugu": "SELECT FROM dbo.vw_BolumSinavYogunlugu"
        }
    }


@router.get("/isterler/backend-kontrol-listesi")
def backend_kontrol_listesi():
    return {
        "api_isterleri": [
            "Bölümler API",
            "Dersler API",
            "Derslikler API",
            "Oturumlar API",
            "Personel API",
            "Personel durum / mazeret API",
            "Sınav API",
            "Salon atama API",
            "Gözetmen atama API",
            "Rapor API",
            "Log API",
            "Güvenlik / roller API",
            "Backup API"
        ],
        "sql_isterleri": {
            "stored_procedures": [
                "sp_SinavOlustur",
                "sp_SalonAtamaYap",
                "sp_GozetmenAta",
                "sp_SinavSaatiGuncelle",
                "sp_VeritabaniYedekAl"
            ],
            "udf_functions": [
                "fn_GozetmenMusaitMi",
                "fn_ArdisikOturumUygunMu",
                "fn_GozetmenGorevSayisi",
                "fn_SalonMusaitMi",
                "fn_ToplamSalonKapasitesi",
                "fn_GunlukSinavSayisi"
            ],
            "views": [
                "vw_SinavProgrami",
                "vw_GozetmenGorevDagilimi",
                "vw_DerslikKullanimRaporu",
                "vw_BolumSinavYogunlugu"
            ],
            "triggers": [
                "trg_SinavSaatDegisikligi_Log",
                "trg_GozetmenAtama_Log",
                "trg_SalonAtama_Log"
            ]
        }
    }


# =========================================================
# TEMEL CRUD ENDPOINTLERI - SQL SERVER
# =========================================================

@router.get("/bolumler")
def get_bolumler():
    return _fetch_all("""
        SELECT
            B.BolumID,
            B.BolumAdi,
            B.Fakulte,
            B.BolumID AS bolum_id,
            B.BolumAdi AS bolum_adi,
            B.Fakulte AS fakulte
        FROM dbo.Bolumler B
        ORDER BY B.BolumID
    """)


@router.post("/bolumler")
def add_bolum(data: dict = Body(...)):
    bolum_adi = _require(_get(data, "BolumAdi", "bolum_adi"), "BolumAdi / bolum_adi zorunludur.")
    fakulte = _get(data, "Fakulte", "fakulte", default="Mühendislik Fakültesi")

    rows = _execute_returning("""
        INSERT INTO dbo.Bolumler (BolumAdi, Fakulte)
        OUTPUT INSERTED.BolumID, INSERTED.BolumAdi, INSERTED.Fakulte
        VALUES (?, ?)
    """, [bolum_adi, fakulte])

    return {"message": "Bölüm veritabanına eklendi.", "data": rows[0] if rows else None}


@router.get("/dersler")
def get_dersler():
    return _fetch_all("""
        SELECT
            D.DersID,
            D.DersKodu,
            D.DersTuru,
            D.Ad,
            D.OgrenciSayisi,
            D.Yariyil,
            D.BolumID,
            B.BolumAdi AS Bolum,
            D.DersID AS ders_id,
            D.DersKodu AS ders_kodu,
            D.DersTuru AS ders_turu,
            D.Ad AS ad,
            D.OgrenciSayisi AS ogrenci_sayisi,
            D.Yariyil AS yariyil,
            D.BolumID AS bolum_id,
            B.BolumAdi AS bolum
        FROM dbo.Dersler D
        INNER JOIN dbo.Bolumler B ON D.BolumID = B.BolumID
        ORDER BY D.DersID
    """)


@router.post("/dersler")
def add_ders(data: dict = Body(...)):
    ders_kodu = _require(_get(data, "DersKodu", "ders_kodu"), "DersKodu / ders_kodu zorunludur.")
    ders_turu = _require(_get(data, "DersTuru", "ders_turu"), "DersTuru / ders_turu zorunludur.")
    ad = _require(_get(data, "Ad", "ad"), "Ad / ad zorunludur.")
    ogrenci_sayisi = _require(_get(data, "OgrenciSayisi", "ogrenci_sayisi"), "OgrenciSayisi / ogrenci_sayisi zorunludur.")
    yariyil = _require(_get(data, "Yariyil", "yariyil"), "Yariyil / yariyil zorunludur.")
    bolum_id = _require(_get(data, "BolumID", "bolum_id"), "BolumID / bolum_id zorunludur.")

    rows = _execute_returning("""
        INSERT INTO dbo.Dersler (DersKodu, DersTuru, Ad, OgrenciSayisi, Yariyil, BolumID)
        OUTPUT INSERTED.DersID, INSERTED.DersKodu, INSERTED.DersTuru, INSERTED.Ad,
               INSERTED.OgrenciSayisi, INSERTED.Yariyil, INSERTED.BolumID
        VALUES (?, ?, ?, ?, ?, ?)
    """, [ders_kodu, ders_turu, ad, ogrenci_sayisi, yariyil, bolum_id])

    return {
        "message": "Ders veritabanına eklendi. Ders kontenjanı OgrenciSayisi alanında tutulur.",
        "data": rows[0] if rows else None
    }


@router.get("/oturumlar")
def get_oturumlar():
    return _fetch_all("""
        SELECT
            O.OturumID,
            O.Tanim,
            O.BaslangicSaat,
            O.BitisSaat,
            O.OturumID AS oturum_id,
            O.Tanim AS tanim,
            CONVERT(VARCHAR(5), O.BaslangicSaat, 108) AS baslangic_saat,
            CONVERT(VARCHAR(5), O.BitisSaat, 108) AS bitis_saat
        FROM dbo.Oturumlar O
        ORDER BY O.OturumID
    """)


@router.post("/oturumlar")
def add_oturum(data: dict = Body(...)):
    tanim = _require(_get(data, "Tanim", "tanim"), "Tanim / tanim zorunludur.")
    baslangic_saat = _require(_get(data, "BaslangicSaat", "baslangic_saat"), "BaslangicSaat / baslangic_saat zorunludur.")
    bitis_saat = _require(_get(data, "BitisSaat", "bitis_saat"), "BitisSaat / bitis_saat zorunludur.")

    rows = _execute_returning("""
        INSERT INTO dbo.Oturumlar (Tanim, BaslangicSaat, BitisSaat)
        OUTPUT INSERTED.OturumID, INSERTED.Tanim, INSERTED.BaslangicSaat, INSERTED.BitisSaat
        VALUES (?, ?, ?)
    """, [tanim, baslangic_saat, bitis_saat])

    return {"message": "Oturum veritabanına eklendi.", "data": rows[0] if rows else None}


@router.get("/derslikler")
def get_derslikler():
    return _fetch_all("""
        SELECT
            DL.DerslikID,
            DL.Ad,
            DL.Kapasite,
            DL.Tip,
            DL.Kat,
            DL.Aktif,
            DL.DerslikID AS derslik_id,
            DL.Ad AS ad,
            DL.Kapasite AS kapasite,
            DL.Tip AS tip,
            DL.Kat AS kat,
            DL.Aktif AS aktif
        FROM dbo.Derslikler DL
        ORDER BY TRY_CONVERT(INT, DL.Ad), DL.Ad
    """)


@router.get("/derslikler/aktif")
def get_aktif_derslikler():
    return _fetch_all("""
        SELECT
            DL.DerslikID,
            DL.Ad,
            DL.Kapasite,
            DL.Tip,
            DL.Kat,
            DL.Aktif,
            DL.DerslikID AS derslik_id,
            DL.Ad AS ad,
            DL.Kapasite AS kapasite,
            DL.Tip AS tip,
            DL.Kat AS kat,
            DL.Aktif AS aktif
        FROM dbo.Derslikler DL
        WHERE DL.Aktif = 1
        ORDER BY DL.Kapasite DESC, DL.DerslikID
    """)


@router.post("/derslikler")
def add_derslik(data: dict = Body(...)):
    ad = _require(_get(data, "Ad", "ad"), "Ad / ad zorunludur.")
    kapasite = _require(_get(data, "Kapasite", "kapasite"), "Kapasite / kapasite zorunludur.")
    tip = _require(_get(data, "Tip", "tip"), "Tip / tip zorunludur. Geçerli değerler: Sınıf, Amfi, Lab")
    kat = _get(data, "Kat", "kat")
    aktif = _get(data, "Aktif", "aktif", default=True)

    rows = _execute_returning("""
        INSERT INTO dbo.Derslikler (Ad, Kapasite, Tip, Kat, Aktif)
        OUTPUT INSERTED.DerslikID, INSERTED.Ad, INSERTED.Kapasite, INSERTED.Tip, INSERTED.Kat, INSERTED.Aktif
        VALUES (?, ?, ?, ?, ?)
    """, [ad, kapasite, tip, kat, 1 if aktif else 0])

    return {"message": "Derslik veritabanına eklendi.", "data": rows[0] if rows else None}


@router.get("/personeller")
def get_personeller():
    return _fetch_all("""
        SELECT
            P.PersonelID,
            P.Unvan,
            P.Ad,
            P.Soyad,
            P.BolumID,
            P.Aktif,
            B.BolumAdi AS Bolum,
            P.PersonelID AS personel_id,
            P.Unvan AS unvan,
            P.Ad AS ad,
            P.Soyad AS soyad,
            P.BolumID AS bolum_id,
            P.Aktif AS aktif,
            B.BolumAdi AS bolum
        FROM dbo.Personel P
        INNER JOIN dbo.Bolumler B ON P.BolumID = B.BolumID
        ORDER BY P.PersonelID
    """)




@router.get("/personeller/uygunluk")
def personel_uygunluk(tarih: str, oturum_id: int):
    """
    Frontend manuel gözetmen atama ekranı için personellerin seçilen
    tarih ve oturumdaki durumunu döndürür.

    MusaitMi = 1 ise personel seçilebilir.
    MusaitMi = 0 ise personel seçilemez.
    """
    return _fetch_all("""
        SELECT
            P.PersonelID,
            P.Unvan,
            P.Ad,
            P.Soyad,
            B.BolumAdi AS Bolum,
            P.Aktif,

            CASE
                WHEN P.Aktif = 0 THEN N'Pasif'
                WHEN dbo.fn_GozetmenMusaitMi(P.PersonelID, ?, ?) = 1 THEN N'Müsait'
                ELSE N'Müsait Değil'
            END AS Durum,

            CASE
                WHEN dbo.fn_GozetmenMusaitMi(P.PersonelID, ?, ?) = 1 THEN 1
                ELSE 0
            END AS MusaitMi

        FROM dbo.Personel P
        INNER JOIN dbo.Bolumler B ON P.BolumID = B.BolumID
        ORDER BY
            CASE
                WHEN dbo.fn_GozetmenMusaitMi(P.PersonelID, ?, ?) = 1 THEN 0
                ELSE 1
            END,
            P.PersonelID
    """, [
        tarih, oturum_id,
        tarih, oturum_id,
        tarih, oturum_id
    ])

@router.post("/personeller")
def add_personel(data: dict = Body(...)):
    unvan = _require(_get(data, "Unvan", "unvan"), "Unvan / unvan zorunludur.")
    ad = _require(_get(data, "Ad", "ad"), "Ad / ad zorunludur.")
    soyad = _require(_get(data, "Soyad", "soyad"), "Soyad / soyad zorunludur.")
    bolum_id = _require(_get(data, "BolumID", "bolum_id"), "BolumID / bolum_id zorunludur.")
    aktif = _get(data, "Aktif", "aktif", default=True)

    rows = _execute_returning("""
        INSERT INTO dbo.Personel (Unvan, Ad, Soyad, BolumID, Aktif)
        OUTPUT INSERTED.PersonelID, INSERTED.Unvan, INSERTED.Ad, INSERTED.Soyad, INSERTED.BolumID, INSERTED.Aktif
        VALUES (?, ?, ?, ?, ?)
    """, [unvan, ad, soyad, bolum_id, 1 if aktif else 0])

    return {"message": "Personel veritabanına eklendi.", "data": rows[0] if rows else None}


@router.get("/personel-durum")
def get_personel_durumlari():
    return _fetch_all("""
        SELECT
            PD.DurumID,
            PD.PersonelID,
            P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS Personel,
            PD.Tarih,
            PD.OturumID,
            O.Tanim AS Oturum,
            PD.MazeretTuru,
            PD.Uygun,
            PD.DurumID AS durum_id,
            PD.PersonelID AS personel_id,
            PD.Tarih AS tarih,
            PD.OturumID AS oturum_id,
            PD.MazeretTuru AS mazeret_turu,
            PD.Uygun AS uygun
        FROM dbo.Personel_Durum PD
        INNER JOIN dbo.Personel P ON PD.PersonelID = P.PersonelID
        INNER JOIN dbo.Oturumlar O ON PD.OturumID = O.OturumID
        ORDER BY PD.DurumID
    """)


@router.post("/personel-durum")
def add_personel_durum(data: dict = Body(...)):
    personel_id = _require(_get(data, "PersonelID", "personel_id"), "PersonelID / personel_id zorunludur.")
    tarih = _require(_get(data, "Tarih", "tarih"), "Tarih / tarih zorunludur.")
    oturum_id = _require(_get(data, "OturumID", "oturum_id"), "OturumID / oturum_id zorunludur.")
    mazeret_turu = _require(_get(data, "MazeretTuru", "mazeret_turu"), "MazeretTuru / mazeret_turu zorunludur.")
    uygun = _get(data, "Uygun", "uygun", default=False)

    rows = _execute_returning("""
        INSERT INTO dbo.Personel_Durum (PersonelID, Tarih, OturumID, MazeretTuru, Uygun)
        OUTPUT INSERTED.DurumID, INSERTED.PersonelID, INSERTED.Tarih, INSERTED.OturumID,
               INSERTED.MazeretTuru, INSERTED.Uygun
        VALUES (?, ?, ?, ?, ?)
    """, [personel_id, tarih, oturum_id, mazeret_turu, 1 if uygun else 0])

    return {"message": "Personel durum / mazeret veritabanına eklendi.", "data": rows[0] if rows else None}


# =========================================================
# SINAV ENDPOINTLERI - SP + VIEW
# =========================================================

@router.get("/sinavlar")
def get_sinavlar():
    return _fetch_all("""
        SELECT *
        FROM dbo.vw_SinavProgrami
        ORDER BY Tarih, Oturum, SinavID
    """)


@router.post("/sinavlar")
def add_sinav(data: dict = Body(...)):
    ders_id = _require(_get(data, "DersID", "ders_id"), "DersID / ders_id zorunludur.")
    tarih = _require(_get(data, "Tarih", "tarih"), "Tarih / tarih zorunludur.")
    oturum_id = _require(_get(data, "OturumID", "oturum_id"), "OturumID / oturum_id zorunludur.")

    try:
        # 1. ADIM: Dersin öğrenci sayısını veritabanından çek
        ders_info = _fetch_one(
            "SELECT OgrenciSayisi FROM dbo.Dersler WHERE DersID = ?",
            [ders_id]
        )

        ogrenci_sayisi = ders_info["OgrenciSayisi"] if ders_info else 0

        # 2. ADIM: Sınavı oluştur
        rows = _execute_returning("""
            EXEC dbo.sp_SinavOlustur
                @DersID = ?,
                @Tarih = ?,
                @OturumID = ?
        """, [ders_id, tarih, oturum_id])

        # SQL bazen SinavID döndürmeyebilir, bu yüzden güvenli şekilde tekrar çekiyoruz
        sinav_id = None

        if rows and isinstance(rows[0], dict):
            sinav_id = rows[0].get("SinavID") or rows[0].get("sinav_id")

        if not sinav_id:
            son_sinav = _fetch_one("""
                SELECT TOP 1 SinavID
                FROM dbo.Sinavlar
                WHERE DersID = ? AND Tarih = ? AND OturumID = ?
                ORDER BY SinavID DESC
            """, [ders_id, tarih, oturum_id])

            if son_sinav:
                sinav_id = son_sinav.get("SinavID") or son_sinav.get("sinav_id")

        # Eğer sınav oluşmadıysa başarı dönme, son kural logunu göster
        if not sinav_id:
            son_log = _fetch_one("""
                SELECT TOP 1 Aciklama
                FROM dbo.Loglar
                WHERE IslemTuru = N'KURAL'
                ORDER BY LogID DESC
            """)

            mesaj = son_log["Aciklama"] if son_log else "Sınav oluşturulamadı. Kural ihlali olabilir."

            return {
                "status": "error",
                "message": f"İşlem reddedildi: {mesaj}",
                "data": None
            }

        # 3. ADIM: Sınav başarıyla eklendiyse otomatik salon ve gözetmen ata
        if sinav_id and ogrenci_sayisi > 0:
            try:
                aktif_salonlar = _fetch_all("""
                    SELECT DerslikID, Kapasite
                    FROM dbo.Derslikler
                    WHERE Aktif = 1
                    ORDER BY Kapasite DESC
                """)

                secilen_salonlar = []
                toplam_kapasite = 0

                for salon in aktif_salonlar:
                    secilen_salonlar.append(str(salon["DerslikID"]))
                    toplam_kapasite += salon["Kapasite"]

                    if toplam_kapasite >= ogrenci_sayisi:
                        break

                derslik_id_list = ",".join(secilen_salonlar)

                if toplam_kapasite >= ogrenci_sayisi:
                    _execute_non_query("EXEC dbo.sp_SalonAtamaYap ?, ?", [sinav_id, derslik_id_list])
                    _execute_non_query("EXEC dbo.sp_GozetmenAta ?", [sinav_id])
                else:
                    print(f"BİLGİ: Okuldaki tüm aktif salonların toplamı bile {ogrenci_sayisi} öğrenciye yetmiyor!")

            except Exception as atama_hatasi:
                print(f"BİLGİ: Otomatik atama yapılamadı: {atama_hatasi}")

        return {
            "status": "success",
            "message": "Sınav listeye başarıyla kaydedildi.",
            "data": {
                "SinavID": sinav_id,
                "DersID": ders_id,
                "Tarih": tarih,
                "OturumID": oturum_id
            }
        }

    except Exception as e:
        hata_mesaji = sql_hatasini_temizle(e)
        return {
            "status": "error",
            "message": f"İşlem reddedildi: {hata_mesaji}",
            "data": None
        }


@router.put("/sinavlar/{sinav_id}/saat-guncelle")
def sinav_saati_guncelle(sinav_id: int, data: dict = Body(...)):
    yeni_tarih = _require(_get(data, "YeniTarih", "Tarih", "yeni_tarih", "tarih"), "YeniTarih / Tarih zorunludur.")
    yeni_oturum_id = _require(_get(data, "YeniOturumID", "OturumID", "yeni_oturum_id", "oturum_id"), "YeniOturumID / OturumID zorunludur.")

    rows = _execute_returning("""
        EXEC dbo.sp_SinavSaatiGuncelle
            @SinavID = ?,
            @YeniTarih = ?,
            @YeniOturumID = ?
    """, [sinav_id, yeni_tarih, yeni_oturum_id])

    return {
        "message": "Sınav saati/tarihi SQL Server'da güncellendi. Trigger log kaydı oluşturur.",
        "sql_sp": "sp_SinavSaatiGuncelle",
        "sql_trigger": "trg_SinavSaatDegisikligi_Log",
        "data": rows[0] if rows else None
    }


# =========================================================
# KONTROL ENDPOINTLERI / UDF
# =========================================================

@router.get("/kontroller/gozetmen-musait-mi")
def gozetmen_musait_mi(personel_id: int, tarih: str, oturum_id: int):
    rows = _fetch_all("SELECT dbo.fn_GozetmenMusaitMi(?, ?, ?) AS Sonuc", [personel_id, tarih, oturum_id])
    sonuc = rows[0]["Sonuc"] if rows else 0
    return {"personel_id": personel_id, "musait": bool(sonuc), "kaynak": "SQL Server UDF"}


@router.get("/kontroller/gozetmen-ardisik-kontrol")
def gozetmen_ardisik_kontrol(personel_id: int, tarih: str, oturum_id: int):
    rows = _fetch_all("SELECT dbo.fn_ArdisikOturumUygunMu(?, ?, ?) AS Sonuc", [personel_id, tarih, oturum_id])
    sonuc = rows[0]["Sonuc"] if rows else 0
    return {"personel_id": personel_id, "tarih": tarih, "oturum_id": oturum_id, "uygun": bool(sonuc), "kaynak": "SQL Server UDF"}


@router.get("/kontroller/gozetmen-gorev-yuku")
def gozetmen_gorev_yuku(personel_id: int):
    rows = _fetch_all("SELECT dbo.fn_GozetmenGorevSayisi(?) AS GorevSayisi", [personel_id])
    gorev_sayisi = rows[0]["GorevSayisi"] if rows else 0
    return {"personel_id": personel_id, "gorev_sayisi": gorev_sayisi, "kaynak": "SQL Server UDF"}


@router.get("/kontroller/salon-musait-mi")
def salon_musait_mi(derslik_id: int, tarih: str, oturum_id: int):
    rows = _fetch_all("SELECT dbo.fn_SalonMusaitMi(?, ?, ?) AS Sonuc", [derslik_id, tarih, oturum_id])
    sonuc = rows[0]["Sonuc"] if rows else 0
    return {"derslik_id": derslik_id, "tarih": tarih, "oturum_id": oturum_id, "musait": bool(sonuc), "kaynak": "SQL Server UDF"}


@router.post("/kontroller/kapasite-kontrol")
def kapasite_kontrol(data: dict = Body(...)):
    sinav_id = _get(data, "SinavID", "sinav_id")
    derslik_idleri = _get(data, "DerslikIDleri", "derslik_idleri", "derslikler", default=[])
    ogrenci_sayisi = _get(data, "OgrenciSayisi", "ogrenci_sayisi", default=0)

    if sinav_id:
        rows = _fetch_all("SELECT dbo.fn_ToplamSalonKapasitesi(?) AS ToplamKapasite", [sinav_id])
        toplam_kapasite = rows[0]["ToplamKapasite"] if rows else 0
        return {"sinav_id": sinav_id, "toplam_kapasite": toplam_kapasite, "kaynak": "SQL Server UDF"}

    if not isinstance(derslik_idleri, list):
        raise HTTPException(status_code=400, detail="derslik_idleri liste olmalıdır. Örn: [1,2,3]")

    toplam = 0
    if derslik_idleri:
        placeholders = ",".join(["?"] * len(derslik_idleri))
        rows = _fetch_all(f"SELECT SUM(Kapasite) AS ToplamKapasite FROM dbo.Derslikler WHERE DerslikID IN ({placeholders})", derslik_idleri)
        toplam = rows[0]["ToplamKapasite"] if rows and rows[0]["ToplamKapasite"] is not None else 0

    return {
        "ogrenci_sayisi": ogrenci_sayisi,
        "toplam_kapasite": toplam,
        "yeterli_mi": int(toplam) >= int(ogrenci_sayisi or 0)
    }


@router.get("/kontroller/gunluk-sinav-limiti")
def gunluk_sinav_limiti(tarih: str, yariyil: int):
    rows = _fetch_all("SELECT dbo.fn_GunlukSinavSayisi(?, ?) AS GunlukSinavSayisi", [tarih, yariyil])
    sayi = rows[0]["GunlukSinavSayisi"] if rows else 0
    return {"tarih": tarih, "yariyil": yariyil, "gunluk_sinav_sayisi": sayi, "uyari": sayi > 2, "kaynak": "SQL Server UDF"}


# =========================================================
# SALON ATAMA - SQL
# =========================================================

@router.post("/salon-atama/oneri")
def salon_atama_oneri(data: dict = Body(...)):
    ogrenci_sayisi = int(_get(data, "OgrenciSayisi", "ogrenci_sayisi", default=0))

    if ogrenci_sayisi <= 0:
        raise HTTPException(status_code=400, detail="Öğrenci sayısı 0'dan büyük olmalıdır.")

    aktif_salonlar = _fetch_all("""
        SELECT
            DL.DerslikID,
            DL.Ad,
            DL.Kapasite,
            DL.Tip,
            DL.Kat,
            DL.Aktif,
            DL.DerslikID AS derslik_id,
            DL.Ad AS ad,
            DL.Kapasite AS kapasite,
            DL.Tip AS tip,
            DL.Kat AS kat,
            DL.Aktif AS aktif
        FROM dbo.Derslikler DL
        WHERE DL.Aktif = 1
        ORDER BY DL.Kapasite ASC, DL.DerslikID
    """)

    if not aktif_salonlar:
        return {
            "message": "Aktif salon bulunamadı.",
            "ogrenci_sayisi": ogrenci_sayisi,
            "onerilen_salonlar": [],
            "toplam_kapasite": 0,
            "bos_kapasite": 0,
            "yeterli_mi": False
        }

    en_iyi_kombinasyon = None
    en_iyi_toplam = None
    en_az_bosluk = None

    salon_sayisi = len(aktif_salonlar)

    for maske in range(1, 2 ** salon_sayisi):
        kombinasyon = []
        toplam_kapasite = 0

        for i in range(salon_sayisi):
            if maske & (1 << i):
                salon = aktif_salonlar[i]
                kombinasyon.append(salon)
                toplam_kapasite += int(salon["Kapasite"])

        if toplam_kapasite >= ogrenci_sayisi:
            bos_kapasite = toplam_kapasite - ogrenci_sayisi

            if (
                en_iyi_kombinasyon is None
                or bos_kapasite < en_az_bosluk
                or (
                    bos_kapasite == en_az_bosluk
                    and len(kombinasyon) < len(en_iyi_kombinasyon)
                )
            ):
                en_iyi_kombinasyon = kombinasyon
                en_iyi_toplam = toplam_kapasite
                en_az_bosluk = bos_kapasite

    if en_iyi_kombinasyon is None:
        toplam_tum_salonlar = sum(int(salon["Kapasite"]) for salon in aktif_salonlar)

        return {
            "message": "Toplam aktif salon kapasitesi öğrenci sayısını karşılamıyor.",
            "ogrenci_sayisi": ogrenci_sayisi,
            "onerilen_salonlar": aktif_salonlar,
            "toplam_kapasite": toplam_tum_salonlar,
            "bos_kapasite": toplam_tum_salonlar - ogrenci_sayisi,
            "yeterli_mi": False,
            "algoritma": "En verimli salon kombinasyonu arandı fakat kapasite yetersiz kaldı."
        }

    return {
        "message": "En verimli salon kombinasyonu oluşturuldu.",
        "ogrenci_sayisi": ogrenci_sayisi,
        "onerilen_salonlar": en_iyi_kombinasyon,
        "toplam_kapasite": en_iyi_toplam,
        "bos_kapasite": en_az_bosluk,
        "yeterli_mi": True,
        "algoritma": "Tüm aktif salon kombinasyonları denenerek öğrenci sayısını karşılayan ve en az boş kapasite bırakan kombinasyon seçildi."
    }

@router.post("/salon-atama/ata")
def salon_atama_yap(data: dict = Body(...)):
    sinav_id = _require(_get(data, "SinavID", "sinav_id"), "SinavID / sinav_id zorunludur.")
    derslik_idleri = _get(data, "DerslikIDleri", "derslik_idleri", "derslikler", "DerslikIDList")

    if isinstance(derslik_idleri, list):
        derslik_id_list = ",".join(str(x) for x in derslik_idleri)
    elif isinstance(derslik_idleri, str):
        derslik_id_list = derslik_idleri
    else:
        raise HTTPException(
            status_code=400,
            detail="DerslikIDleri / derslik_idleri zorunludur. Örn: [11,12] veya '11,12'"
        )

    derslik_id_listesi = [
        int(x.strip())
        for x in derslik_id_list.split(",")
        if x.strip().isdigit()
    ]

    if not derslik_id_listesi:
        raise HTTPException(status_code=400, detail="Geçerli Derslik ID girilmelidir.")

    # 1) Sınav + ders + öğrenci sayısı bilgisini çek
    sinav = _fetch_one("""
        SELECT
            S.SinavID,
            S.Tarih,
            S.OturumID,
            D.DersID,
            D.DersKodu,
            D.Ad AS DersAdi,
            D.OgrenciSayisi
        FROM dbo.Sinavlar S
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        WHERE S.SinavID = ?
    """, [sinav_id])

    if not sinav:
        raise HTTPException(status_code=400, detail="Sınav bulunamadı.")

    ogrenci_sayisi = int(sinav["OgrenciSayisi"])

    # 2) Seçilen dersliklerin toplam kapasitesini hesapla
    placeholders = ",".join(["?"] * len(derslik_id_listesi))

    kapasite_sonuc = _fetch_one(f"""
        SELECT SUM(Kapasite) AS ToplamKapasite
        FROM dbo.Derslikler
        WHERE DerslikID IN ({placeholders})
          AND Aktif = 1
    """, derslik_id_listesi)

    toplam_kapasite = kapasite_sonuc["ToplamKapasite"] if kapasite_sonuc else 0
    toplam_kapasite = int(toplam_kapasite or 0)

    if toplam_kapasite < ogrenci_sayisi:
        raise HTTPException(
            status_code=400,
            detail=f"Kapasite yetersiz. Seçilen salonların toplam kapasitesi {toplam_kapasite}, öğrenci sayısı {ogrenci_sayisi}."
        )

    # 3) Aynı tarih + aynı oturum + aynı derslik başka sınava atanmış mı?
    for derslik_id in derslik_id_listesi:
        cakisma = _fetch_one("""
            SELECT TOP 1
                SS.SinavSalonID,
                SS.SinavID,
                SS.DerslikID
            FROM dbo.Sinav_Salonlari SS
            INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
            WHERE SS.DerslikID = ?
              AND S.Tarih = ?
              AND S.OturumID = ?
              AND SS.SinavID <> ?
        """, [derslik_id, sinav["Tarih"], sinav["OturumID"], sinav_id])

        if cakisma:
            raise HTTPException(
                status_code=400,
                detail="Seçilen salon dolu. Aynı tarih ve aynı oturumda bu derslik başka bir sınava atanmış."
            )

    # 4) Her şey uygunsa SQL stored procedure çalışsın
    rows = _execute_returning("""
        EXEC dbo.sp_SalonAtamaYap
            @SinavID = ?,
            @DerslikIDList = ?
    """, [sinav_id, derslik_id_list])

    return {
        "message": "Salon ataması SQL Server'a kaydedildi.",
        "sql_sp": "sp_SalonAtamaYap",
        "kontrol": {
            "ogrenci_sayisi": ogrenci_sayisi,
            "toplam_kapasite": toplam_kapasite,
            "derslik_idleri": derslik_id_listesi
        },
        "data": rows[0] if rows else None
    }

@router.get("/salon-atama/{sinav_id}")
def get_salon_atamalari(sinav_id: int):
    return _fetch_all("""
        SELECT
            SS.SinavSalonID AS atama_id,
            SS.SinavSalonID,
            SS.SinavID,
            SS.DerslikID,
            DL.Ad AS Derslik,
            DL.Ad AS derslik,
            DL.Kapasite,
            DL.Kapasite AS kapasite,
            DL.Tip,
            DL.Kat
        FROM dbo.Sinav_Salonlari SS
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        WHERE SS.SinavID = ?
        ORDER BY SS.SinavSalonID
    """, [sinav_id])


# =========================================================
# GOZETMEN ATAMA - SQL
# =========================================================

@router.post("/gozetmen-atama/oneri")
def gozetmen_atama_oneri(data: dict = Body(...)):
    bolum_id = _get(data, "BolumID", "bolum_id")

    if bolum_id:
        ayni_bolum = _fetch_all("""
            SELECT PersonelID AS personel_id, Unvan AS unvan, Ad AS ad, Soyad AS soyad, BolumID AS bolum_id, Aktif AS aktif
            FROM dbo.Personel
            WHERE Aktif = 1 AND BolumID = ?
            ORDER BY PersonelID
        """, [bolum_id])
        ortak_havuz = _fetch_all("""
            SELECT PersonelID AS personel_id, Unvan AS unvan, Ad AS ad, Soyad AS soyad, BolumID AS bolum_id, Aktif AS aktif
            FROM dbo.Personel
            WHERE Aktif = 1 AND BolumID <> ?
            ORDER BY PersonelID
        """, [bolum_id])
    else:
        ayni_bolum = []
        ortak_havuz = _fetch_all("""
            SELECT PersonelID AS personel_id, Unvan AS unvan, Ad AS ad, Soyad AS soyad, BolumID AS bolum_id, Aktif AS aktif
            FROM dbo.Personel
            WHERE Aktif = 1
            ORDER BY PersonelID
        """)

    return {
        "message": "Gözetmen önerisi SQL Server'daki aktif personele göre oluşturuldu.",
        "once_kendi_bolumu": ayni_bolum,
        "yetersizse_ortak_havuz": ortak_havuz
    }


@router.post("/gozetmen-atama/ata")
def gozetmen_atama_yap(data: dict = Body(...)):
    sinav_id = _require(_get(data, "SinavID", "sinav_id"), "SinavID / sinav_id zorunludur.")

    rows = _execute_returning("""
        EXEC dbo.sp_GozetmenAta
            @SinavID = ?
    """, [sinav_id])

    return {
        "message": "Gözetmen ataması SQL Server'a kaydedildi.",
        "sql_sp": "sp_GozetmenAta",
        "data": rows[0] if rows else None
    }
@router.post("/gozetmen-atama/manual")
def gozetmen_manual_atama(data: dict = Body(...)):
    sinav_salon_id = _require(
        _get(data, "SinavSalonID", "sinav_salon_id"),
        "SinavSalonID / sinav_salon_id zorunludur."
    )

    personel_id = _require(
        _get(data, "PersonelID", "personel_id"),
        "PersonelID / personel_id zorunludur."
    )

    # 1. Sınav salon bilgisi var mı?
    sinav_salon = _fetch_one("""
        SELECT
            SS.SinavSalonID,
            SS.SinavID,
            SS.DerslikID,
            S.Tarih,
            S.OturumID,
            D.BolumID,
            DL.Ad AS Derslik
        FROM dbo.Sinav_Salonlari SS
        INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
        INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        WHERE SS.SinavSalonID = ?
    """, [sinav_salon_id])

    if not sinav_salon:
        raise HTTPException(status_code=400, detail="Sınav salon kaydı bulunamadı.")

    # 2. Personel aktif mi?
    personel = _fetch_one("""
        SELECT PersonelID, Unvan, Ad, Soyad, BolumID, Aktif
        FROM dbo.Personel
        WHERE PersonelID = ?
    """, [personel_id])

    if not personel:
        raise HTTPException(status_code=400, detail="Personel bulunamadı.")

    if not personel["Aktif"]:
        raise HTTPException(status_code=400, detail="Seçilen personel aktif değil.")

    # 3. Bu salonda zaten gözetmen var mı?
    mevcut = _fetch_one("""
        SELECT TOP 1 GozetmenAtamaID
        FROM dbo.Gozetmen_Atamalari
        WHERE SinavSalonID = ?
    """, [sinav_salon_id])

    if mevcut:
        raise HTTPException(status_code=400, detail="Bu sınav salonuna zaten gözetmen atanmış.")

    # 4. Aynı tarih + aynı oturumda bu personel başka salonda görevli mi?
    cakisma = _fetch_one("""
        SELECT TOP 1
            GA.GozetmenAtamaID,
            SS.SinavSalonID,
            SS.SinavID
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
        WHERE GA.PersonelID = ?
          AND S.Tarih = ?
          AND S.OturumID = ?
          AND SS.SinavSalonID <> ?
    """, [personel_id, sinav_salon["Tarih"], sinav_salon["OturumID"], sinav_salon_id])

    if cakisma:
        raise HTTPException(
            status_code=400,
            detail="Bu gözetmen aynı tarih ve aynı oturumda başka salonda zaten görevli."
        )

    # 5. Müsaitlik kontrolü: Personel_Durum, aynı oturum çakışması ve günlük limitler SQL UDF içinde kontrol edilir.
    musait = _fetch_one("""
        SELECT dbo.fn_GozetmenMusaitMi(?, ?, ?) AS Musait
    """, [personel_id, sinav_salon["Tarih"], sinav_salon["OturumID"]])

    if not musait or not bool(musait["Musait"]):
        raise HTTPException(
            status_code=400,
            detail="Bu öğretim elemanı bu tarih ve oturum için müsait değil."
        )

    # 6. Bir öğretim elemanı bir günde en fazla 4 farklı oturumda görev alabilir.
    gunluk_gorev = _fetch_one("""
        SELECT COUNT(DISTINCT S.OturumID) AS GorevSayisi
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
        WHERE GA.PersonelID = ?
          AND S.Tarih = ?
    """, [personel_id, sinav_salon["Tarih"]])

    gorev_sayisi = int(gunluk_gorev["GorevSayisi"] or 0) if gunluk_gorev else 0

    if gorev_sayisi >= 4:
        raise HTTPException(
            status_code=400,
            detail="Bu öğretim elemanı bir günde en fazla 4 oturumda görev alabilir."
        )

    # 7. Bir öğretim elemanı art arda en fazla 3 oturumda görev alabilir.
    mevcut_oturumlar = _fetch_all("""
        SELECT DISTINCT S.OturumID
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Sinavlar S ON SS.SinavID = S.SinavID
        WHERE GA.PersonelID = ?
          AND S.Tarih = ?
    """, [personel_id, sinav_salon["Tarih"]])

    oturumlar = [int(row["OturumID"]) for row in mevcut_oturumlar]
    yeni_oturum = int(sinav_salon["OturumID"])

    if yeni_oturum not in oturumlar:
        oturumlar.append(yeni_oturum)

    oturumlar = sorted(oturumlar)

    ardisik_sayi = 1
    max_ardisik = 1

    for i in range(1, len(oturumlar)):
        if oturumlar[i] == oturumlar[i - 1] + 1:
            ardisik_sayi += 1
            max_ardisik = max(max_ardisik, ardisik_sayi)
        else:
            ardisik_sayi = 1

    if max_ardisik > 3:
        raise HTTPException(
            status_code=400,
            detail="Bu öğretim elemanı art arda en fazla 3 oturumda görev alabilir."
        )

    # 8. Kaynak bilgisini belirle. Veritabanı CHECK constraint sadece bu iki değere izin veriyor.
    atama_kaynak = "Kendi Bölümü" if personel["BolumID"] == sinav_salon["BolumID"] else "Ortak Havuz"

    _execute_non_query("""
        INSERT INTO dbo.Gozetmen_Atamalari
        (
            SinavSalonID,
            PersonelID,
            AtamaKaynak
        )
        VALUES (?, ?, ?)
    """, [sinav_salon_id, personel_id, atama_kaynak])

    yeni_kayit = _fetch_one("""
        SELECT TOP 1
            GA.GozetmenAtamaID,
            GA.SinavSalonID,
            GA.PersonelID,
            GA.AtamaKaynak,
            P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS Gozetmen
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Personel P ON GA.PersonelID = P.PersonelID
        WHERE GA.SinavSalonID = ?
          AND GA.PersonelID = ?
        ORDER BY GA.GozetmenAtamaID DESC
    """, [sinav_salon_id, personel_id])

    return {
        "message": "Manuel gözetmen ataması başarıyla yapıldı.",
        "data": yeni_kayit
    }

@router.get("/gozetmen-atama/{sinav_id}")
def get_gozetmen_atamalari(sinav_id: int):
    return _fetch_all("""
        SELECT
            GA.GozetmenAtamaID AS atama_id,
            GA.GozetmenAtamaID,
            SS.SinavID,
            GA.SinavSalonID,
            SS.DerslikID,
            DL.Ad AS Derslik,
            GA.PersonelID,
            P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS Gozetmen,
            P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS gozetmen,
            GA.AtamaKaynak AS kaynak,
            GA.AtamaKaynak
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        INNER JOIN dbo.Personel P ON GA.PersonelID = P.PersonelID
        WHERE SS.SinavID = ?
        ORDER BY GA.GozetmenAtamaID
    """, [sinav_id])


# =========================================================
# RAPORLAR / VIEW
# =========================================================

@router.get("/raporlar/sinav-programi")
def sinav_programi_raporu():
    return {
        "sql_view": "vw_SinavProgrami",
        "data": _fetch_all("SELECT * FROM dbo.vw_SinavProgrami ORDER BY Tarih, Oturum, SinavID")
    }


@router.get("/raporlar/gozetmen-gorev-dagilimi")
def gozetmen_gorev_dagilimi():
    return {
        "sql_view": "vw_GozetmenGorevDagilimi",
        "data": _fetch_all("SELECT * FROM dbo.vw_GozetmenGorevDagilimi ORDER BY GorevSayisi DESC, PersonelID")
    }


@router.get("/raporlar/derslik-kullanim")
def derslik_kullanim_raporu():
    return {
        "sql_view": "vw_DerslikKullanimRaporu",
        "data": _fetch_all("SELECT * FROM dbo.vw_DerslikKullanimRaporu ORDER BY DerslikID")
    }


@router.get("/raporlar/bolum-sinav-yogunlugu")
def bolum_sinav_yogunlugu():
    return {
        "sql_view": "vw_BolumSinavYogunlugu",
        "data": _fetch_all("SELECT * FROM dbo.vw_BolumSinavYogunlugu ORDER BY Tarih, BolumID, Yariyil")
    }


# =========================================================
# SILME ENDPOINTLERI - FK SIRASINA DIKKAT EDILDI
# =========================================================

@router.delete("/dersler/{ders_id}")
def delete_ders(ders_id: int):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT DersID, DersKodu, Ad
            FROM dbo.Dersler
            WHERE DersID = ?
        """, [ders_id])
        ders = cursor.fetchone()

        if not ders:
            raise HTTPException(status_code=404, detail="Silinecek ders bulunamadı.")

        ders_kodu = ders[1]
        ders_adi = ders[2]

        cursor.execute("""
            SELECT SinavID
            FROM dbo.Sinavlar
            WHERE DersID = ?
        """, [ders_id])
        sinav_ids = [row[0] for row in cursor.fetchall()]

        if sinav_ids:
            placeholders = ",".join(["?"] * len(sinav_ids))

            cursor.execute(f"""
                DELETE GA
                FROM dbo.Gozetmen_Atamalari GA
                INNER JOIN dbo.Sinav_Salonlari SS
                    ON GA.SinavSalonID = SS.SinavSalonID
                WHERE SS.SinavID IN ({placeholders})
            """, sinav_ids)

            cursor.execute(f"""
                DELETE FROM dbo.Sinav_Salonlari
                WHERE SinavID IN ({placeholders})
            """, sinav_ids)

            cursor.execute(f"""
                DELETE FROM dbo.Sinavlar
                WHERE SinavID IN ({placeholders})
            """, sinav_ids)

        cursor.execute("""
            DELETE FROM dbo.Dersler
            WHERE DersID = ?
        """, [ders_id])

        cursor.execute("""
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
                N'DELETE',
                N'Dersler',
                ?,
                ?,
                NULL,
                SYSTEM_USER,
                GETDATE(),
                N'Ders ve derse bağlı sınav/salon/gözetmen kayıtları silindi.'
            )
        """, [ders_id, f"DersKodu: {ders_kodu}, DersAdi: {ders_adi}"])

        conn.commit()

        return {
            "message": "Ders ve derse bağlı sınav/salon/gözetmen kayıtları silindi.",
            "ders_id": ders_id,
            "ders": f"{ders_kodu} - {ders_adi}"
        }

    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()
@router.get("/sinav-atamalari/{sinav_id}")
def get_sinav_atamalari(sinav_id: int):
    salonlar = _fetch_all("""
        SELECT
            SS.SinavSalonID,
            SS.SinavID,
            SS.DerslikID,
            DL.Ad AS DerslikAdi,
            DL.Kapasite,
            DL.Tip
        FROM dbo.Sinav_Salonlari SS
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        WHERE SS.SinavID = ?
        ORDER BY SS.SinavSalonID
    """, [sinav_id])

    gozetmenler = _fetch_all("""
        SELECT
            GA.GozetmenAtamaID,
            GA.SinavSalonID,
            GA.PersonelID,
            P.Unvan,
            P.Ad,
            P.Soyad,
            P.Unvan + ' ' + P.Ad + ' ' + P.Soyad AS Gozetmen,
            DL.Ad AS DerslikAdi,
            GA.AtamaKaynak
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        INNER JOIN dbo.Derslikler DL ON SS.DerslikID = DL.DerslikID
        INNER JOIN dbo.Personel P ON GA.PersonelID = P.PersonelID
        WHERE SS.SinavID = ?
        ORDER BY GA.GozetmenAtamaID
    """, [sinav_id])

    return {
        "sinav_id": sinav_id,
        "salonlar": salonlar,
        "gozetmenler": gozetmenler
    }


@router.delete("/gozetmen-atamalari/{gozetmen_atama_id}")
def delete_gozetmen_atama(gozetmen_atama_id: int):
    _execute_non_query("""
        DELETE FROM dbo.Gozetmen_Atamalari
        WHERE GozetmenAtamaID = ?
    """, [gozetmen_atama_id])

    return {"message": "Gözetmen ataması silindi."}


@router.delete("/sinav-salonlari/{sinav_salon_id}")
def delete_sinav_salonu(sinav_salon_id: int):
    # Önce o salona bağlı gözetmenleri sil
    _execute_non_query("""
        DELETE FROM dbo.Gozetmen_Atamalari
        WHERE SinavSalonID = ?
    """, [sinav_salon_id])

    # Sonra salon atamasını sil
    _execute_non_query("""
        DELETE FROM dbo.Sinav_Salonlari
        WHERE SinavSalonID = ?
    """, [sinav_salon_id])

    return {"message": "Salon ataması ve bağlı gözetmenler silindi."}


@router.delete("/sinav-atamalari/{sinav_id}")
def delete_sinav_atamalari(sinav_id: int):
    # Önce sınava ait tüm gözetmen atamalarını sil
    _execute_non_query("""
        DELETE GA
        FROM dbo.Gozetmen_Atamalari GA
        INNER JOIN dbo.Sinav_Salonlari SS ON GA.SinavSalonID = SS.SinavSalonID
        WHERE SS.SinavID = ?
    """, [sinav_id])

    # Sonra sınava ait tüm salon atamalarını sil
    _execute_non_query("""
        DELETE FROM dbo.Sinav_Salonlari
        WHERE SinavID = ?
    """, [sinav_id])

    return {"message": "Bu sınava ait tüm salon ve gözetmen atamaları silindi."}

@router.delete("/sinavlar/{sinav_id}")
def delete_sinav(sinav_id: int):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT S.SinavID, D.DersKodu, D.Ad, S.Tarih, S.OturumID
            FROM dbo.Sinavlar S
            INNER JOIN dbo.Dersler D ON S.DersID = D.DersID
            WHERE S.SinavID = ?
        """, [sinav_id])
        sinav = cursor.fetchone()

        if not sinav:
            raise HTTPException(status_code=404, detail="Silinecek sınav bulunamadı.")

        eski_deger = (
            f"SinavID: {sinav[0]}, DersKodu: {sinav[1]}, "
            f"DersAdi: {sinav[2]}, Tarih: {sinav[3]}, OturumID: {sinav[4]}"
        )

        cursor.execute("""
            DELETE GA
            FROM dbo.Gozetmen_Atamalari GA
            INNER JOIN dbo.Sinav_Salonlari SS
                ON GA.SinavSalonID = SS.SinavSalonID
            WHERE SS.SinavID = ?
        """, [sinav_id])

        cursor.execute("""
            DELETE FROM dbo.Sinav_Salonlari
            WHERE SinavID = ?
        """, [sinav_id])

        cursor.execute("""
            DELETE FROM dbo.Sinavlar
            WHERE SinavID = ?
        """, [sinav_id])

        cursor.execute("""
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
                N'DELETE',
                N'Sinavlar',
                ?,
                ?,
                NULL,
                SYSTEM_USER,
                GETDATE(),
                N'Sınav ve sınava bağlı salon/gözetmen atamaları silindi.'
            )
        """, [sinav_id, eski_deger])

        conn.commit()
        return {"message": "Sınav ve sınava bağlı salon/gözetmen atamaları silindi.", "sinav_id": sinav_id}

    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


@router.delete("/derslikler/{derslik_id}")
def delete_derslik(derslik_id: int):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT DerslikID, Ad, Kapasite
            FROM dbo.Derslikler
            WHERE DerslikID = ?
        """, [derslik_id])
        derslik = cursor.fetchone()

        if not derslik:
            raise HTTPException(status_code=404, detail="Silinecek derslik bulunamadı.")

        eski_deger = f"DerslikID: {derslik[0]}, Ad: {derslik[1]}, Kapasite: {derslik[2]}"

        cursor.execute("""
            DELETE GA
            FROM dbo.Gozetmen_Atamalari GA
            INNER JOIN dbo.Sinav_Salonlari SS
                ON GA.SinavSalonID = SS.SinavSalonID
            WHERE SS.DerslikID = ?
        """, [derslik_id])

        cursor.execute("""
            DELETE FROM dbo.Sinav_Salonlari
            WHERE DerslikID = ?
        """, [derslik_id])

        cursor.execute("""
            DELETE FROM dbo.Derslikler
            WHERE DerslikID = ?
        """, [derslik_id])

        cursor.execute("""
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
                N'DELETE',
                N'Derslikler',
                ?,
                ?,
                NULL,
                SYSTEM_USER,
                GETDATE(),
                N'Derslik ve dersliğe bağlı salon/gözetmen atamaları silindi.'
            )
        """, [derslik_id, eski_deger])

        conn.commit()
        return {"message": "Derslik ve dersliğe bağlı salon/gözetmen atamaları silindi.", "derslik_id": derslik_id}

    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


@router.delete("/personeller/{personel_id}")
def delete_personel(personel_id: int):
    conn = get_sql_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı kurulamadı.")

    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT PersonelID, Unvan, Ad, Soyad
            FROM dbo.Personel
            WHERE PersonelID = ?
        """, [personel_id])
        personel = cursor.fetchone()

        if not personel:
            raise HTTPException(status_code=404, detail="Silinecek personel bulunamadı.")

        eski_deger = f"{personel[1]} {personel[2]} {personel[3]}"

        cursor.execute("""
            DELETE FROM dbo.Gozetmen_Atamalari
            WHERE PersonelID = ?
        """, [personel_id])

        cursor.execute("""
            DELETE FROM dbo.Personel_Durum
            WHERE PersonelID = ?
        """, [personel_id])

        cursor.execute("""
            DELETE FROM dbo.Personel
            WHERE PersonelID = ?
        """, [personel_id])

        cursor.execute("""
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
                N'DELETE',
                N'Personel',
                ?,
                ?,
                NULL,
                SYSTEM_USER,
                GETDATE(),
                N'Personel ve personele bağlı gözetmen/mazeret kayıtları silindi.'
            )
        """, [personel_id, eski_deger])

        conn.commit()
        return {"message": "Personel ve personele bağlı gözetmen/mazeret kayıtları silindi.", "personel_id": personel_id}

    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=sql_hatasini_temizle(e))
    finally:
        conn.close()


# =========================================================
# LOG / TRIGGER
# =========================================================

@router.get("/loglar")
def get_loglar():
    return {
        "message": "Bu kayıtlar SQL Server triggerları / işlemleri tarafından üretilir.",
        "data": _fetch_all("SELECT * FROM dbo.Loglar ORDER BY LogID DESC")
    }


# =========================================================
# GUVENLIK / ROLE BASED SECURITY
# =========================================================

@router.post("/auth/login")
def login(data: dict = Body(...)):
    kullanici_tipi = _get(data, "kullanici_tipi", "role", "Rol")

    if kullanici_tipi == "admin":
        return {
            "message": "Yönetici girişi başarılı.",
            "role": "App_Admin",
            "yetki": "SELECT, INSERT, UPDATE, DELETE"
        }

    if kullanici_tipi == "viewer":
        return {
            "message": "Gözetmen girişi başarılı.",
            "role": "App_Viewer",
            "yetki": "Sadece rapor/view okuma"
        }

    raise HTTPException(status_code=400, detail="Geçersiz kullanıcı tipi. admin veya viewer gönderilmeli.")


@router.get("/guvenlik/roller")
def get_guvenlik_rolleri():
    return {
        "roles": [
            {
                "role": "App_Admin",
                "yetki": "SELECT, INSERT, UPDATE, DELETE + stored procedure çalıştırma",
                "aciklama": "Tüm tablolara okuma/yazma yetkisi olan yönetici kullanıcı."
            },
            {
                "role": "App_Viewer",
                "yetki": "Sadece view/rapor SELECT",
                "aciklama": "Tablolara doğrudan erişemez; sadece raporları görebilir."
            }
        ]
    }


# =========================================================
# BACKUP BONUS
# =========================================================

@router.post("/backup/yedek-al")
def veritabani_yedek_al():
    rows = _execute_returning("EXEC dbo.sp_VeritabaniYedekAl")
    return {
        "message": "Backup stored procedure çalıştırıldı.",
        "sql_sp": "sp_VeritabaniYedekAl",
        "data": rows[0] if rows else None,
        "not": "Backup dosyası SQL Server'ın çalıştığı Windows makinede oluşur. C:\\Yedekler klasörü yoksa SQL Server hata verebilir."
    }
