"""
sql_service.py
Bu dosya SQL Server işlemlerini CANLI olarak yönetir.
"""

from database import get_sql_connection


def fetch_all(query: str, params: tuple = ()):
    """SELECT sorguları ve View'lar için kullanılır."""
    conn = get_sql_connection()
    if not conn:
        return []
    try:
        cursor = conn.cursor()
        cursor.execute(query, params)
        # Sütun isimlerini alıp sözlük (dict) yapısına çeviriyoruz (FastAPI için)
        columns = [column[0] for column in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return results
    except Exception as e:
        print(f"SQL Fetch Hatası: {e}")
        # Boş liste dönmek yerine hatayı yukarı fırlatıyoruz ki Swagger'da ne olduğunu görelim!
        raise Exception(f"Veritabanından Veri Çekilemedi: {str(e)}")
    finally:
        conn.close()


def execute_command(query: str, params: tuple = ()):
    """INSERT / UPDATE / DELETE komut sorguları için kullanılır."""
    conn = get_sql_connection()
    if not conn:
        return False
    try:
        cursor = conn.cursor()
        cursor.execute(query, params)
        conn.commit()
        return True
    except Exception as e:
        print(f"SQL Komut Hatası: {e}")
        raise Exception(f"SQL Motoru Hatası: {str(e)}")
    finally:
        conn.close()


# sql_service.py içindeki execute_stored_procedure fonksiyonunu şu şekilde güncelle:
def execute_stored_procedure(procedure_name: str, params: tuple = ()):
    conn = get_sql_connection()
    if not conn:
        raise Exception("Veritabanı bağlantısı kurulamadı.")
    try:
        cursor = conn.cursor()
        param_placeholders = ", ".join(["?"] * len(params))
        sql_query = f"EXEC {procedure_name} {param_placeholders}"
        
        cursor.execute(sql_query, params)
        conn.commit()
        return True
    except Exception as e:
        # Hata mesajını burada temizliyoruz
        hata_mesaji = str(e)
        if len(e.args) > 1:
            hata_mesaji = e.args[1]
        
        # HATA YUTMA, SADECE DÖNDÜR! 
        # Burada raise etmiyoruz ki FastAPI çökmesin
        return {"error": True, "message": hata_mesaji}
    finally:
        conn.close()

def fetch_view(view_name: str):
    """View'dan veri çekmek için kullanılır. Tip uyuşmazlığını önlemek için verileri metin olarak çeker."""
    # Sütunları tek tek string (VARCHAR) formatına cast ederek çekiyoruz
    query = """
        SELECT 
            CAST(SinavID AS VARCHAR(50)) AS sinav_id,
            CAST(Tarih AS VARCHAR(50)) AS tarih,
            CAST(Oturum AS VARCHAR(50)) AS oturum,
            CAST(SaatAraligi AS VARCHAR(50)) AS saat_araligi,
            CAST(DersKodu AS VARCHAR(50)) AS ders_kodu,
            CAST(DersAdi AS VARCHAR(250)) AS ders,
            CAST(Derslik AS VARCHAR(50)) AS derslikler,
            CAST(Kapasite AS VARCHAR(50)) AS kapasite,
            CAST(Gozetmen AS VARCHAR(250)) AS gozetmenler,
            CAST(AtamaKaynak AS VARCHAR(100)) AS atama_kaynak
        FROM dbo.vw_SinavProgrami WITH (NOLOCK)
    """
    return fetch_all(query)