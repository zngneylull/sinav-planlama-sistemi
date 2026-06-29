🚀 Sınav Planlama Sistemi



Bu proje; eğitim kurumlarında sınav takvimlerinin, salon kapasitelerinin ve gözetmen atamalarının çakışmasız, otomatik ve optimize bir şekilde yönetilmesini sağlayan dinamik bir Sınav Planlama Sistemi platformudur. 



Proje, modern ve performanslı bir backend mimarisi (FastAPI) ile güçlü bir ilişkisel veri tabanı yönetim sistemini (MS SQL Server) bir araya getirerek veri tutarlılığını iş mantığı (business logic) seviyesinde korur.



\---



🛠️ Kullanılan Teknolojiler ve Mimari



Backend: FastAPI (Python) - Asenkron, yüksek performanslı ve otomatik Swagger/OpenAPI dökümantasyonlu API katmanı.

Database: MS SQL Server - İlişkisel veri yönetimi, ACID uyumluluğu.

Database Logic: SQL Triggers \& Functions - Çakışma kontrolleri, kapasite limitleri ve otomatik atamalar veri tabanı seviyesinde tetikleyicilerle yönetilir.

Frontend: HTML5, CSS3, JavaScript - Kullanıcı dostu, temiz ve responsive yönetim arayüzü.



\---



✨ Öne Çıkan Özellikler



Akıllı Sınav Ataması: Salon kapasitelerine ve öğrenci sayılarına göre otomatik dağıtım.

Gözetmen Çakışma Önleme: Aynı gözetmenin aynı saatte farklı iki sınava atanmasını engelleyen veri tabanı mimarisi.

Gelişmiş SQL Tetikleyicileri (Triggers): Sınav veya atama güncellendiğinde/silindiğinde otomatik çalışan veri doğrulama kuralları.

Modern API Dökümantasyonu: Swagger entegrasyonu sayesinde tüm endpoint'lerin interaktif takibi.



\---



📁 Proje Yapısı



```text

├── frontend/             # Kullanıcı arayüzü dosyaları (HTML, CSS, JS)

├── sql\_scripts/          # SQL Server Tablo, Trigger ve Function şemaları

├── database.py           # Veri tabanı bağlantı ve session yönetimi

├── main.py               # FastAPI uygulamasının ana giriş noktası (Entry Point)

├── planlama.py           # Planlama ve dağıtım algoritmalarının iş mantığı

├── sql\_service.py        # Veri tabanı sorguları ve CRUD operasyonları

└── requirements.txt      # Projenin Python bağımlılıkları

