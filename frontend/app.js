const API = "http://127.0.0.1:8000/api";

let bolumlerCache = [];
let derslerCache = [];
let oturumlarCache = [];
let dersliklerCache = [];

// ========================
// YARDIMCI FONKSİYONLAR
// ========================

async function apiGet(endpoint) {
  const res = await fetch(API + endpoint);
  const json = await res.json();

  if (!res.ok) {
    throw new Error(json.detail || json.message || `${endpoint} yüklenemedi.`);
  }

  if (Array.isArray(json)) return json;
  if (json.data !== undefined) return json.data;

  return json;
}

async function apiPost(endpoint, body) {
  const res = await fetch(API + endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  const json = await res.json();

  if (!res.ok) {
    throw new Error(json.detail || json.message || "İşlem başarısız.");
  }

  if (json.status === "error") {
    throw new Error(json.message || "İşlem reddedildi.");
  }

  return json;
}

function getValue(obj, ...keys) {
  for (const key of keys) {
    if (obj && obj[key] !== undefined && obj[key] !== null) {
      return obj[key];
    }
  }
  return "";
}

function getSelectNumber(id) {
  const value = document.getElementById(id)?.value;
  return value ? Number(value) : null;
}

function safeText(value, key = "") {
  if (value === null || value === undefined || value === "") {
    return '<span style="color:var(--text-muted)">—</span>';
  }

  const normalizedKey = String(key).toLowerCase();

  if (normalizedKey === "aktif") {
    if (value === true || value === 1) {
      return '<span class="badge badge-green">✓ Aktif</span>';
    }

    if (value === false || value === 0) {
      return '<span class="badge badge-red">✗ Pasif</span>';
    }
  }

  return String(value);
}

function escapeForOnclick(value) {
  return String(value).replaceAll("\\", "\\\\").replaceAll("'", "\\'");
}

function formatDateTR(value) {
  if (!value) return "";

  const dateOnly = String(value).split("T")[0];
  const parts = dateOnly.split("-");

  if (parts.length !== 3) return value;

  return `${parts[2]}.${parts[1]}.${parts[0]}`;
}

// ========================
// SAYFA YÖNETİMİ
// ========================

function showPage(id) {
  document.querySelectorAll(".page").forEach(page => {
    page.classList.remove("active");
  });

  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.classList.remove("active");
  });

  const page = document.getElementById("page-" + id);
  if (page) page.classList.add("active");

  const activeBtn = [...document.querySelectorAll(".nav-btn")]
    .find(btn => btn.getAttribute("onclick")?.includes(`showPage('${id}')`));

  if (activeBtn) activeBtn.classList.add("active");

  if (id === "dashboard") {
    loadDashboard();
  }

  if (id === "sinavlar") {
    loadLookuplar();
    loadTablo("/sinavlar", "tablo-sinavlar");

    const yonetim = document.getElementById("sinav-atama-yonetim");
    if (yonetim) yonetim.innerHTML = "";
  }

  if (id === "dersler") {
    loadLookuplar();
    loadTablo("/dersler", "tablo-dersler");
  }

  if (id === "derslikler") {
    loadDerslikler();
  }

  if (id === "personeller") {
    loadLookuplar();
    loadTablo("/personeller", "tablo-personeller");
  }

  if (id === "salon-atama") {
    loadDersliklerCache();
  }

  if (id === "gozetmen-atama") {
    loadLookuplar();
    fillPersonelSelect("manual-personel-id");
  }

  if (id === "loglar") {
    loadLoglar();
  }
}

function toggleForm(id) {
  const form = document.getElementById(id);
  if (!form) return;

  form.classList.toggle("hidden");
  loadLookuplar();
}

// ========================
// LOOKUP / SELECT DOLDURMA
// ========================

async function loadLookuplar() {
  try {
    const [bolumler, dersler, oturumlar] = await Promise.all([
      apiGet("/bolumler"),
      apiGet("/dersler"),
      apiGet("/oturumlar")
    ]);

    bolumlerCache = bolumler;
    derslerCache = dersler;
    oturumlarCache = oturumlar;

    fillSelect(
      "sinav-ders-id",
      derslerCache,
      item => getValue(item, "DersID", "ders_id"),
      item => {
        const id = getValue(item, "DersID", "ders_id");
        const kod = getValue(item, "DersKodu", "ders_kodu");
        const ad = getValue(item, "Ad", "ad", "DersAdi", "ders_adi");
        const ogrenci = getValue(item, "OgrenciSayisi", "ogrenci_sayisi");
        return `${id} - ${kod} / ${ad} (${ogrenci} öğrenci)`;
      },
      "Ders seçiniz"
    );

    fillSelect(
      "sinav-oturum-id",
      oturumlarCache,
      item => getValue(item, "OturumID", "oturum_id"),
      item => {
        const id = getValue(item, "OturumID", "oturum_id");
        const tanim = getValue(item, "Tanim", "tanim");
        const baslangic = getValue(item, "baslangic_saat", "BaslangicSaat");
        const bitis = getValue(item, "bitis_saat", "BitisSaat");
        return `${id} - ${tanim} (${baslangic} - ${bitis})`;
      },
      "Oturum seçiniz"
    );

    fillSelect(
      "guncelle-oturum-id",
      oturumlarCache,
      item => getValue(item, "OturumID", "oturum_id"),
      item => {
        const id = getValue(item, "OturumID", "oturum_id");
        const tanim = getValue(item, "Tanim", "tanim");
        const baslangic = getValue(item, "baslangic_saat", "BaslangicSaat");
        const bitis = getValue(item, "bitis_saat", "BitisSaat");
        return `${id} - ${tanim} (${baslangic} - ${bitis})`;
      },
      "Oturum seçiniz"
    );

    fillBolumSelect("ders-bolum-id");
    fillBolumSelect("personel-bolum");
    fillBolumSelect("gozetmen-bolum-id");

  } catch (err) {
    console.error("Lookup verileri yüklenemedi:", err);
  }
}

async function loadDersliklerCache() {
  try {
    dersliklerCache = await apiGet("/derslikler");
    fillDerslikSelect("ata-derslik-idler");
  } catch (err) {
    console.error("Derslik cache yüklenemedi:", err);
  }
}

function fillBolumSelect(selectId) {
  fillSelect(
    selectId,
    bolumlerCache,
    item => getValue(item, "BolumID", "bolum_id"),
    item => getValue(item, "BolumAdi", "bolum_adi"),
    "Bölüm seçiniz"
  );
}

function fillSelect(selectId, data, valueFn, labelFn, placeholder) {
  const select = document.getElementById(selectId);
  if (!select) return;

  const oldValue = select.value;
  select.innerHTML = `<option value="">${placeholder}</option>`;

  data.forEach(item => {
    const value = valueFn(item);

    if (value === undefined || value === null || value === "") return;

    const option = document.createElement("option");
    option.value = value;
    option.textContent = labelFn(item);
    select.appendChild(option);
  });

  if (oldValue) {
    select.value = oldValue;
  }
}

function fillPersonelSelect(selectId) {
  const select = document.getElementById(selectId);
  if (!select) return;

  apiGet("/personeller")
    .then(personeller => {
      select.innerHTML = '<option value="">Personel seçiniz</option>';

      personeller.forEach(item => {
        const id = getValue(item, "PersonelID", "personel_id");
        const unvan = getValue(item, "Unvan", "unvan");
        const ad = getValue(item, "Ad", "ad");
        const soyad = getValue(item, "Soyad", "soyad");
        const bolum = getValue(item, "Bolum", "bolum");

        if (!id) return;

        const option = document.createElement("option");
        option.value = id;
        option.textContent = `${id} - ${unvan} ${ad} ${soyad} / ${bolum}`;
        select.appendChild(option);
      });
    })
    .catch(err => {
      console.error("Personel listesi yüklenemedi:", err);
    });
}

async function fillPersonelUygunlukSelect(selectId, tarih, oturumId) {
  const select = document.getElementById(selectId);
  if (!select) return;

  select.innerHTML = '<option value="">Personeller yükleniyor...</option>';

  try {
    const personeller = await apiGet(`/personeller/uygunluk?tarih=${tarih}&oturum_id=${oturumId}`);

    select.innerHTML = '<option value="">Personel seçiniz</option>';

    personeller.forEach(item => {
      const id = getValue(item, "PersonelID", "personel_id");
      const unvan = getValue(item, "Unvan", "unvan");
      const ad = getValue(item, "Ad", "ad");
      const soyad = getValue(item, "Soyad", "soyad");
      const bolum = getValue(item, "Bolum", "bolum");
      const musaitMi = Number(getValue(item, "MusaitMi", "musait_mi"));

      if (!id) return;

      const durumYazisi = musaitMi === 1 ? "Müsait" : "Müsait Değil";

      const option = document.createElement("option");
      option.value = id;
      option.textContent = `${id} - ${unvan} ${ad} ${soyad} / ${bolum} / ${durumYazisi}`;

      if (musaitMi !== 1) {
        option.disabled = true;
        option.textContent += " (Seçilemez)";
      }

      select.appendChild(option);
    });

  } catch (err) {
    console.error("Personel uygunluk listesi alınamadı:", err);
    select.innerHTML = '<option value="">Personel listesi alınamadı</option>';
  }
}

function fillDerslikSelect(selectId) {
  const select = document.getElementById(selectId);
  if (!select) return;

  select.innerHTML = "";

  if (!dersliklerCache.length) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "Derslik verisi bulunamadı";
    select.appendChild(option);
    return;
  }

  dersliklerCache.forEach(item => {
    const id = getValue(item, "DerslikID", "derslik_id");
    const ad = getValue(item, "Ad", "ad");
    const kapasite = getValue(item, "Kapasite", "kapasite");
    const tip = getValue(item, "Tip", "tip");

    if (!id) return;

    const option = document.createElement("option");
    option.value = id;
    option.textContent = `${id} - ${ad} | Kapasite: ${kapasite} | ${tip}`;
    select.appendChild(option);
  });
}

// ========================
// DASHBOARD
// ========================

async function loadDashboard() {
  try {
    const [sinavlar, dersler, derslikler, personeller, mode] = await Promise.all([
      apiGet("/sinavlar"),
      apiGet("/dersler"),
      apiGet("/derslikler"),
      apiGet("/personeller"),
      fetch(API + "/app/mode").then(r => r.json())
    ]);

    const sinavCount = document.getElementById("count-sinavlar");
    const dersCount = document.getElementById("count-dersler");
    const derslikCount = document.getElementById("count-derslikler");
    const personelCount = document.getElementById("count-personel");
    const modeBox = document.getElementById("app-mode-box");

    if (sinavCount) sinavCount.textContent = sinavlar.length;
    if (dersCount) dersCount.textContent = dersler.length;
    if (derslikCount) derslikCount.textContent = derslikler.length;
    if (personelCount) personelCount.textContent = personeller.length;

    if (modeBox) {
      modeBox.textContent = `MOD: ${mode.mode} — ${mode.message}`;
    }

    const dot = document.getElementById("statusDot");
    const txt = document.getElementById("statusText");

    if (dot) dot.className = "status-dot online";
    if (txt) txt.textContent = "Backend aktif";

  } catch (err) {
    console.error("Dashboard yüklenemedi:", err);

    const dot = document.getElementById("statusDot");
    const txt = document.getElementById("statusText");
    const modeBox = document.getElementById("app-mode-box");

    if (dot) dot.className = "status-dot offline";
    if (txt) txt.textContent = "Backend kapalı";
    if (modeBox) modeBox.textContent = "Backend’e bağlanılamadı. uvicorn çalışıyor mu?";
  }
}

// ========================
// TABLO
// ========================

async function loadTablo(endpoint, hedef) {
  const el = document.getElementById(hedef);
  if (!el) return;

  el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Yükleniyor...</p>';

  try {
    const data = await apiGet(endpoint);

    if (!Array.isArray(data) || !data.length) {
      el.innerHTML = '<p style="color:var(--text-muted)">Kayıt bulunamadı.</p>';
      return;
    }

    el.innerHTML = buildTable(data, endpoint);

  } catch (err) {
    console.error(`${endpoint} yüklenemedi:`, err);
    el.innerHTML = `<p style="color:var(--danger)">Veri yüklenemedi: ${err.message}</p>`;
  }
}

async function loadDerslikler() {
  const el = document.getElementById("tablo-derslikler");
  if (!el) return;

  el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Derslikler yükleniyor...</p>';

  try {
    const derslikler = await apiGet("/derslikler");
    dersliklerCache = derslikler;

    if (!derslikler.length) {
      el.innerHTML = '<p style="color:var(--text-muted)">Derslik kaydı bulunamadı.</p>';
      return;
    }

    const sirali = [...derslikler].sort((a, b) => {
      const adA = Number(getValue(a, "Ad", "ad"));
      const adB = Number(getValue(b, "Ad", "ad"));
      return adA - adB;
    });

    el.innerHTML = `
      <div class="form-box" style="margin-bottom:16px">
        <h3>Resmi Derslik Kapasiteleri</h3>
        <p style="font-size:12px;color:var(--text-muted);line-height:1.7">
          Küçük sınıflar sınav salonu kapasitesi 36,
          309 kapasitesi 40,
          311 kapasitesi 50,
          büyük sınıflar sınav salonu kapasitesi 60 olarak kullanılır.
        </p>
      </div>
      ${buildTable(sirali, "/derslikler")}
    `;

  } catch (err) {
    console.error("Derslikler yüklenemedi:", err);
    el.innerHTML = `<p style="color:var(--danger)">Derslikler yüklenemedi: ${err.message}</p>`;
  }
}

function getVisibleKeys(endpoint, data) {
  if (!Array.isArray(data) || !data.length) return [];

  if (endpoint === "/derslikler") {
    return ["DerslikID", "Ad", "Kapasite", "Tip", "Kat", "Aktif"];
  }

  if (endpoint === "/dersler") {
    return ["DersID", "DersKodu", "Ad", "DersTuru", "OgrenciSayisi", "Yariyil", "Bolum"];
  }

  if (endpoint === "/personeller") {
    return ["PersonelID", "Unvan", "Ad", "Soyad", "Bolum", "Aktif"];
  }

  if (endpoint === "/sinavlar") {
    const preferred = [
      "SinavID",
      "Tarih",
      "Oturum",
      "SaatAraligi",
      "DersKodu",
      "DersAdi",
      "DersTuru",
      "OgrenciSayisi",
      "Yariyil",
      "BolumAdi",
      "Derslik",
      "Derslikler",
      "Gozetmen",
      "Gozetmenler",
      "AtamaKaynak"
    ];

    return preferred.filter(key => Object.prototype.hasOwnProperty.call(data[0], key));
  }

  return Object.keys(data[0]).filter(key => !key.includes("_"));
}

function getColumnLabel(key) {
  const labels = {
    SinavID: "Sınav ID",
    DerslikID: "Derslik ID",
    DersID: "Ders ID",
    PersonelID: "Personel ID",
    DersKodu: "Ders Kodu",
    DersAdi: "Ders Adı",
    DersTuru: "Ders Türü",
    OgrenciSayisi: "Öğrenci Sayısı",
    Yariyil: "Yarıyıl",
    Bolum: "Bölüm",
    BolumAdi: "Bölüm",
    Ad: "Ad",
    Soyad: "Soyad",
    Unvan: "Ünvan",
    Kapasite: "Kapasite",
    Tip: "Tip",
    Kat: "Kat",
    Aktif: "Aktif",
    Tarih: "Tarih",
    Oturum: "Oturum",
    SaatAraligi: "Saat Aralığı",
    Derslik: "Derslikler",
    Derslikler: "Derslikler",
    Gozetmen: "Gözetmenler",
    Gozetmenler: "Gözetmenler",
    AtamaKaynak: "Atama Kaynak"
  };

  return labels[key] || key;
}

function buildTable(data, endpoint = "") {
  if (!Array.isArray(data) || !data.length) {
    return '<p style="color:var(--text-muted)">Kayıt bulunamadı.</p>';
  }

  const keys = getVisibleKeys(endpoint, data);

  const silinebilirMi = [
    "/dersler",
    "/sinavlar",
    "/derslikler",
    "/personeller"
  ].includes(endpoint);

  let html = '<div style="overflow-x:auto"><table><thead><tr>';

  keys.forEach(key => {
    html += `<th>${getColumnLabel(key)}</th>`;
  });

  if (silinebilirMi) {
    html += "<th>İşlem</th>";
  }

  html += "</tr></thead><tbody>";

  data.forEach(row => {
    html += "<tr>";

    keys.forEach(key => {
      html += `<td>${safeText(row[key], key)}</td>`;
    });

    if (silinebilirMi) {
      const deleteInfo = getDeleteInfo(endpoint, row);

      if (deleteInfo) {
        if (endpoint === "/sinavlar") {
          html += `
            <td>
              <button
                class="btn-secondary"
                onclick="sinavAtamalariniGoster(${deleteInfo.id})"
                style="margin-right:6px"
              >
                Atamaları Yönet
              </button>

              <button
                class="btn-secondary"
                onclick="kayitSil('${endpoint}', ${deleteInfo.id}, '${escapeForOnclick(deleteInfo.label)}')"
              >
                Sınavı Sil
              </button>
            </td>
          `;
        } else {
          html += `
            <td>
              <button
                class="btn-secondary"
                onclick="kayitSil('${endpoint}', ${deleteInfo.id}, '${escapeForOnclick(deleteInfo.label)}')"
              >
                Sil
              </button>
            </td>
          `;
        }
      } else {
        html += '<td><span style="color:var(--text-muted)">—</span></td>';
      }
    }

    html += "</tr>";
  });

  html += "</tbody></table></div>";
  return html;
}

// ========================
// SİLME
// ========================

function getDeleteInfo(endpoint, row) {
  if (endpoint === "/dersler") {
    const id = getValue(row, "DersID", "ders_id");
    const kod = getValue(row, "DersKodu", "ders_kodu");
    const ad = getValue(row, "Ad", "ad", "DersAdi", "ders_adi");
    return id ? { id, label: `${kod} - ${ad}` } : null;
  }

  if (endpoint === "/sinavlar") {
    const id = getValue(row, "SinavID", "sinav_id");
    const ders = getValue(row, "DersAdi", "ders", "DersKodu", "ders_kodu");
    const tarih = getValue(row, "Tarih", "tarih");
    return id ? { id, label: `${ders} ${tarih}` } : null;
  }

  if (endpoint === "/derslikler") {
    const id = getValue(row, "DerslikID", "derslik_id");
    const ad = getValue(row, "Ad", "ad");
    return id ? { id, label: ad } : null;
  }

  if (endpoint === "/personeller") {
    const id = getValue(row, "PersonelID", "personel_id");
    const unvan = getValue(row, "Unvan", "unvan");
    const ad = getValue(row, "Ad", "ad");
    const soyad = getValue(row, "Soyad", "soyad");
    return id ? { id, label: `${unvan} ${ad} ${soyad}` } : null;
  }

  return null;
}

function getDeleteUrl(endpoint, id) {
  if (endpoint === "/dersler") return `/dersler/${id}`;
  if (endpoint === "/sinavlar") return `/sinavlar/${id}`;
  if (endpoint === "/derslikler") return `/derslikler/${id}`;
  if (endpoint === "/personeller") return `/personeller/${id}`;
  return null;
}

async function kayitSil(endpoint, id, label) {
  const url = getDeleteUrl(endpoint, id);

  if (!url) {
    alert("Bu kayıt türü için silme işlemi tanımlı değil.");
    return;
  }

  const onay = confirm(
    `${label} kaydını silmek istediğine emin misin?\n\n` +
    "Bu işlem veritabanından kalıcı olarak silinir."
  );

  if (!onay) return;

  try {
    const res = await fetch(API + url, {
      method: "DELETE"
    });

    const json = await res.json();

    if (!res.ok) {
      alert(json.detail || "Silme işlemi başarısız.");
      return;
    }

    alert(json.message || "Kayıt silindi.");

    if (endpoint === "/dersler") {
      loadTablo("/dersler", "tablo-dersler");
      loadLookuplar();
    }

    if (endpoint === "/sinavlar") {
      loadTablo("/sinavlar", "tablo-sinavlar");
      const yonetim = document.getElementById("sinav-atama-yonetim");
      if (yonetim) yonetim.innerHTML = "";
    }

    if (endpoint === "/derslikler") {
      loadDerslikler();
      loadDersliklerCache();
    }

    if (endpoint === "/personeller") {
      loadTablo("/personeller", "tablo-personeller");
      loadLookuplar();
    }

    loadDashboard();

  } catch (err) {
    console.error("Silme hatası:", err);
    alert("Backend bağlantısı kurulamadı.");
  }
}

// ========================
// SINAV ATAMA YÖNETİMİ
// ========================

async function sinavAtamalariniGoster(sinavId) {
  const el = document.getElementById("sinav-atama-yonetim");

  if (!el) {
    alert("sinav-atama-yonetim alanı bulunamadı. index.html kontrol et.");
    return;
  }

  el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Atamalar yükleniyor...</p>';

  try {
    const res = await fetch(`${API}/sinav-atamalari/${sinavId}`);
    const data = await res.json();

    if (!res.ok) {
      throw new Error(data.detail || "Atamalar yüklenemedi.");
    }

    const salonlar = data.salonlar || [];
    const gozetmenler = data.gozetmenler || [];

    let salonHtml = "";

    if (salonlar.length) {
      salonHtml = `
        <table>
          <thead>
            <tr>
              <th>Sınav Salon ID</th>
              <th>Derslik</th>
              <th>Kapasite</th>
              <th>Tip</th>
              <th>İşlem</th>
            </tr>
          </thead>
          <tbody>
            ${salonlar.map(salon => `
              <tr>
                <td>${salon.SinavSalonID}</td>
                <td>${salon.DerslikAdi}</td>
                <td>${salon.Kapasite}</td>
                <td>${salon.Tip}</td>
                <td>
                  <button class="btn-secondary" onclick="sinavSalonuSil(${salon.SinavSalonID}, ${sinavId})">
                    Salon Atamasını Sil
                  </button>
                </td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      `;
    } else {
      salonHtml = '<p style="color:var(--text-muted)">Bu sınava ait salon ataması yok.</p>';
    }

    let gozetmenHtml = "";

    if (gozetmenler.length) {
      gozetmenHtml = `
        <table>
          <thead>
            <tr>
              <th>Gözetmen Atama ID</th>
              <th>Salon</th>
              <th>Gözetmen</th>
              <th>Kaynak</th>
              <th>İşlem</th>
            </tr>
          </thead>
          <tbody>
            ${gozetmenler.map(g => `
              <tr>
                <td>${g.GozetmenAtamaID}</td>
                <td>${g.DerslikAdi}</td>
                <td>${g.Gozetmen}</td>
                <td>${g.AtamaKaynak || "—"}</td>
                <td>
                  <button class="btn-secondary" onclick="gozetmenAtamasiSil(${g.GozetmenAtamaID}, ${sinavId})">
                    Gözetmeni Sil
                  </button>
                </td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      `;
    } else {
      gozetmenHtml = '<p style="color:var(--text-muted)">Bu sınava ait gözetmen ataması yok.</p>';
    }

    el.innerHTML = `
      <div class="form-box" style="margin-top:24px; border-color:var(--accent)">
        <h3 style="color:var(--accent)">Sınav ${sinavId} Atama Yönetimi</h3>

        <button
          class="btn-secondary"
          onclick="tumSinavAtamalariniSil(${sinavId})"
          style="margin-bottom:18px; background:rgba(248,113,113,0.12); border-color:var(--danger); color:var(--danger)"
        >
          Bu Sınavın Tüm Salon ve Gözetmen Atamalarını Sil
        </button>

        <h3>Salon Atamaları</h3>
        ${salonHtml}

        <h3 style="margin-top:24px">Gözetmen Atamaları</h3>
        ${gozetmenHtml}
      </div>
    `;

    el.scrollIntoView({ behavior: "smooth", block: "start" });

  } catch (err) {
    el.innerHTML = `<p style="color:var(--danger)">Atamalar yüklenemedi: ${err.message}</p>`;
  }
}

async function gozetmenAtamasiSil(gozetmenAtamaId, sinavId) {
  const onay = confirm("Bu gözetmen atamasını silmek istediğine emin misin?");
  if (!onay) return;

  try {
    const res = await fetch(`${API}/gozetmen-atamalari/${gozetmenAtamaId}`, {
      method: "DELETE"
    });

    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Gözetmen ataması silinemedi.");
    }

    alert(json.message || "Gözetmen ataması silindi.");
    sinavAtamalariniGoster(sinavId);
    loadTablo("/sinavlar", "tablo-sinavlar");

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

async function sinavSalonuSil(sinavSalonId, sinavId) {
  const onay = confirm(
    "Bu salon atamasını silmek istediğine emin misin?\n\n" +
    "Bu salona bağlı gözetmen atamaları da silinir."
  );

  if (!onay) return;

  try {
    const res = await fetch(`${API}/sinav-salonlari/${sinavSalonId}`, {
      method: "DELETE"
    });

    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Salon ataması silinemedi.");
    }

    alert(json.message || "Salon ataması silindi.");
    sinavAtamalariniGoster(sinavId);
    loadTablo("/sinavlar", "tablo-sinavlar");

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

async function tumSinavAtamalariniSil(sinavId) {
  const onay = confirm(
    "Bu sınava ait TÜM salon ve gözetmen atamalarını silmek istediğine emin misin?"
  );

  if (!onay) return;

  try {
    const res = await fetch(`${API}/sinav-atamalari/${sinavId}`, {
      method: "DELETE"
    });

    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Atamalar silinemedi.");
    }

    alert(json.message || "Tüm atamalar silindi.");
    sinavAtamalariniGoster(sinavId);
    loadTablo("/sinavlar", "tablo-sinavlar");

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

// ========================
// SINAV EKLE
// ========================

async function sinavEkle() {
  const dersId = getSelectNumber("sinav-ders-id");
  const oturumId = getSelectNumber("sinav-oturum-id");
  const tarih = document.getElementById("sinav-tarih")?.value;

  if (!dersId || !tarih || !oturumId) {
    alert("Ders, tarih ve oturum seçmelisin.");
    return;
  }

  try {
    const json = await apiPost("/sinavlar", {
      ders_id: dersId,
      tarih,
      oturum_id: oturumId
    });

    alert(json.message || "Sınav kaydedildi.");

    toggleForm("sinav-form");
    loadTablo("/sinavlar", "tablo-sinavlar");
    loadDashboard();

  } catch (err) {
    alert(err.message || "Sınav eklenemedi.");
  }
}

// ========================
// DERS EKLE
// ========================

async function dersEkle() {
  const body = {
    ders_kodu: document.getElementById("ders-kodu")?.value.trim(),
    ad: document.getElementById("ders-adi")?.value.trim(),
    ders_turu: document.getElementById("ders-turu")?.value,
    ogrenci_sayisi: Number(document.getElementById("ders-ogrenci")?.value),
    yariyil: Number(document.getElementById("ders-yariyil")?.value),
    bolum_id: getSelectNumber("ders-bolum-id")
  };

  if (!body.ders_kodu || !body.ad || !body.ders_turu || !body.ogrenci_sayisi || !body.yariyil || !body.bolum_id) {
    alert("Ders kodu, ders adı, ders türü, öğrenci sayısı, yarıyıl ve bölüm zorunludur.");
    return;
  }

  try {
    const json = await apiPost("/dersler", body);

    alert(json.message || "Ders kaydedildi.");

    toggleForm("ders-form");
    loadTablo("/dersler", "tablo-dersler");
    loadLookuplar();
    loadDashboard();

  } catch (err) {
    alert(err.message || "Ders eklenemedi.");
  }
}

// ========================
// PERSONEL EKLE
// ========================

async function personelEkle() {
  const body = {
    unvan: document.getElementById("personel-unvan")?.value.trim(),
    ad: document.getElementById("personel-ad")?.value.trim(),
    soyad: document.getElementById("personel-soyad")?.value.trim(),
    bolum_id: getSelectNumber("personel-bolum"),
    aktif: true
  };

  if (!body.unvan || !body.ad || !body.soyad || !body.bolum_id) {
    alert("Unvan, ad, soyad ve bölüm zorunludur.");
    return;
  }

  try {
    const json = await apiPost("/personeller", body);

    alert(json.message || "Personel kaydedildi.");

    toggleForm("personel-form");
    loadTablo("/personeller", "tablo-personeller");
    loadLookuplar();
    loadDashboard();

  } catch (err) {
    alert(err.message || "Personel eklenemedi.");
  }
}

// ========================
// SALON ÖNERİSİ
// ========================

async function salonOneri() {
  const ogrenci = Number(document.getElementById("salon-ogrenci")?.value);

  if (!ogrenci) {
    alert("Öğrenci sayısı girmelisin.");
    return;
  }

  const el = document.getElementById("salon-oneri-sonuc");

  if (el) {
    el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Salon önerisi alınıyor...</p>';
  }

  try {
    const json = await apiPost("/salon-atama/oneri", {
      ogrenci_sayisi: ogrenci
    });

    if (!el) return;

    const salonlar = json.onerilen_salonlar ?? [];

    const durum = json.yeterli_mi
      ? '<span class="badge badge-green">Kapasite yeterli</span>'
      : '<span class="badge badge-red">Kapasite yetersiz</span>';

    el.innerHTML = `
      <div class="form-box">
        <p style="margin-bottom:12px;color:var(--text-muted);font-size:12px">
          ÖNERİLEN SALONLAR —
          Öğrenci sayısı:
          <span style="color:var(--accent)">${json.ogrenci_sayisi}</span>
          |
          Toplam kapasite:
          <span style="color:var(--accent)">${json.toplam_kapasite}</span>
          ${durum}
        </p>
        ${salonlar.length ? buildTable(salonlar, "/derslikler") : '<p style="color:var(--text-muted)">Salon önerisi bulunamadı.</p>'}
      </div>
    `;

  } catch (err) {
    if (el) {
      el.innerHTML = `<p style="color:var(--danger)">Öneri alınamadı: ${err.message}</p>`;
    }
  }
}

// ========================
// SALON ATAMA
// ========================

async function salonAta() {
  const sinavId = getSelectNumber("ata-sinav-id");
  const derslikSelect = document.getElementById("ata-derslik-idler");

  const secilenDerslikler = derslikSelect
    ? [...derslikSelect.selectedOptions].map(option => option.value).filter(value => value !== "")
    : [];

  if (!sinavId || secilenDerslikler.length === 0) {
    alert("Sınav ID ve en az bir derslik seçmelisin.");
    return;
  }

  try {
    const json = await apiPost("/salon-atama/ata", {
      sinav_id: sinavId,
      derslik_idleri: secilenDerslikler
    });

    alert(json.message || "Salon ataması kaydedildi.");

    document.getElementById("ata-sinav-id").value = "";
    if (derslikSelect) {
      [...derslikSelect.options].forEach(option => option.selected = false);
    }

    loadTablo("/sinavlar", "tablo-sinavlar");
    loadDashboard();

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

async function sinavBilgisiGoster() {
  const input = document.getElementById("ata-sinav-id");
  const bilgi = document.getElementById("ata-sinav-bilgi");

  if (!input || !bilgi) return;

  const sinavId = input.value;

  if (!sinavId) {
    bilgi.textContent = "Sınav ID girince sınav adı burada görünecek.";
    bilgi.style.color = "var(--text-muted)";
    return;
  }

  try {
    const sinavlar = await apiGet("/sinavlar");

    const secilen = sinavlar.find(item => {
      const id = getValue(item, "SinavID", "sinav_id");
      return String(id) === String(sinavId);
    });

    if (!secilen) {
      bilgi.textContent = "Bu ID'ye ait sınav bulunamadı.";
      bilgi.style.color = "var(--danger)";
      return;
    }

    const dersKodu = getValue(secilen, "DersKodu", "ders_kodu");
    const dersAdi = getValue(secilen, "DersAdi", "ders", "Ad", "ad");
    const ogrenciSayisi = getValue(secilen, "OgrenciSayisi", "ogrenci_sayisi");
    const tarih = getValue(secilen, "Tarih", "tarih");
    const oturum = getValue(secilen, "Oturum", "oturum");
    const saat = getValue(secilen, "SaatAraligi", "saat_araligi");

    bilgi.textContent = `Seçilen sınav: ${dersKodu} - ${dersAdi} | Öğrenci: ${ogrenciSayisi} | ${formatDateTR(tarih)} | ${oturum} ${saat ? "(" + saat + ")" : ""}`;
    bilgi.style.color = "var(--accent)";

  } catch (err) {
    bilgi.textContent = "Sınav bilgisi alınamadı.";
    bilgi.style.color = "var(--danger)";
  }
}

// ========================
// GÖZETMEN ÖNERİSİ / ATAMA
// ========================

async function gozetmenOneri() {
  const bolumId = getSelectNumber("gozetmen-bolum-id");

  if (!bolumId) {
    alert("Bölüm seçmelisin.");
    return;
  }

  const el = document.getElementById("gozetmen-oneri-sonuc");

  if (el) {
    el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Gözetmen önerisi alınıyor...</p>';
  }

  try {
    const json = await apiPost("/gozetmen-atama/oneri", {
      bolum_id: bolumId
    });

    if (!el) return;

    const kendiBolumu = json.once_kendi_bolumu ?? [];
    const ortakHavuz = json.yetersizse_ortak_havuz ?? [];

    el.innerHTML = `
      <div class="form-box">
        <p style="margin-bottom:12px;color:var(--text-muted);font-size:12px">KENDİ BÖLÜMÜ</p>
        ${kendiBolumu.length ? buildTable(kendiBolumu) : '<p style="color:var(--text-muted)">Kendi bölümünde uygun personel bulunamadı.</p>'}

        <p style="margin:16px 0 12px;color:var(--text-muted);font-size:12px">ORTAK HAVUZ</p>
        ${ortakHavuz.length ? buildTable(ortakHavuz) : '<p style="color:var(--text-muted)">Ortak havuzda uygun personel bulunamadı.</p>'}
      </div>
    `;

  } catch (err) {
    if (el) {
      el.innerHTML = `<p style="color:var(--danger)">Gözetmen önerisi alınamadı: ${err.message}</p>`;
    }
  }
}

async function gozetmenAta() {
  const sinavId = getSelectNumber("goz-ata-sinav-id");

  if (!sinavId) {
    alert("Lütfen bir Sınav ID giriniz.");
    return;
  }

  try {
    const json = await apiPost("/gozetmen-atama/ata", {
      sinav_id: sinavId
    });

    alert(json.message || "Gözetmen ataması başarıyla yapıldı.");
    document.getElementById("goz-ata-sinav-id").value = "";

    loadTablo("/sinavlar", "tablo-sinavlar");
    loadDashboard();

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

async function manuelSinavSalonlariniYukle() {
  const sinavId = document.getElementById("manual-sinav-id")?.value;
  const salonSelect = document.getElementById("manual-sinav-salon-id");
  const bilgi = document.getElementById("manual-sinav-bilgi");
  const personelSelect = document.getElementById("manual-personel-id");

  if (!salonSelect) return;

  if (!sinavId) {
    salonSelect.innerHTML = '<option value="">Önce sınav ID giriniz</option>';

    if (personelSelect) {
      personelSelect.innerHTML = '<option value="">Önce sınav ID giriniz</option>';
    }

    if (bilgi) {
      bilgi.textContent = "Sınav ID girince o sınava ait salonlar ve uygun personeller listelenecek.";
      bilgi.style.color = "var(--text-muted)";
    }

    return;
  }

  try {
    const salonlar = await apiGet(`/sinav-salonlari/${sinavId}`);

    salonSelect.innerHTML = "";

    if (!Array.isArray(salonlar) || !salonlar.length) {
      salonSelect.innerHTML = '<option value="">Bu sınava ait salon bulunamadı</option>';

      if (personelSelect) {
        personelSelect.innerHTML = '<option value="">Önce sınava salon atanmalı</option>';
      }

      if (bilgi) {
        bilgi.textContent = "Bu sınava henüz salon atanmamış.";
        bilgi.style.color = "var(--danger)";
      }

      return;
    }

    salonSelect.innerHTML = '<option value="">Sınav salonu seçiniz</option>';

    salonlar.forEach(item => {
      const sinavSalonId = getValue(item, "SinavSalonID", "sinav_salon_id");
      const derslikAdi = getValue(item, "DerslikAdi", "derslik_adi");
      const kapasite = getValue(item, "Kapasite", "kapasite");
      const tip = getValue(item, "Tip", "tip");

      const option = document.createElement("option");
      option.value = sinavSalonId;
      option.textContent = `${sinavSalonId} - ${derslikAdi} / Kapasite: ${kapasite} / ${tip}`;
      salonSelect.appendChild(option);
    });

    const ilk = salonlar[0];

    const dersKodu = getValue(ilk, "DersKodu", "ders_kodu");
    const dersAdi = getValue(ilk, "DersAdi", "ders_adi", "DersAdi");
    const tarih = getValue(ilk, "Tarih", "tarih");
    const oturum = getValue(ilk, "Oturum", "oturum");
    const oturumId = getValue(ilk, "OturumID", "oturum_id");

    if (bilgi) {
      bilgi.textContent = `Seçilen sınav: ${dersKodu} - ${dersAdi} | ${formatDateTR(tarih)} | ${oturum}`;
      bilgi.style.color = "var(--accent)";
    }

    await fillPersonelUygunlukSelect("manual-personel-id", tarih, oturumId);

  } catch (err) {
    console.error("Sınav salonları alınamadı:", err);

    salonSelect.innerHTML = '<option value="">Salonlar yüklenemedi</option>';

    if (personelSelect) {
      personelSelect.innerHTML = '<option value="">Personel listesi alınamadı</option>';
    }

    if (bilgi) {
      bilgi.textContent = "Sınav salonları alınamadı.";
      bilgi.style.color = "var(--danger)";
    }
  }
}

const manuelsinavSalonlariniYukle = manuelSinavSalonlariniYukle;

async function manuelGozetmenAta() {
  const sinavSalonId = getSelectNumber("manual-sinav-salon-id");
  const personelId = getSelectNumber("manual-personel-id");

  if (!sinavSalonId || !personelId) {
    alert("Sınav salonu ve personel seçimi zorunludur.");
    return;
  }

  try {
    const json = await apiPost("/gozetmen-atama/manual", {
      sinav_salon_id: sinavSalonId,
      personel_id: personelId
    });

    alert(json.message || "Manuel gözetmen ataması yapıldı.");

    document.getElementById("manual-personel-id").value = "";

    loadTablo("/sinavlar", "tablo-sinavlar");
    loadDashboard();

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

// ========================
// SINAV GÜNCELLE
// ========================

async function sinavGuncelle() {
  const sinavId = getSelectNumber("guncelle-sinav-id");
  const tarih = document.getElementById("guncelle-tarih")?.value;
  const oturumId = getSelectNumber("guncelle-oturum-id");

  if (!sinavId || !tarih || !oturumId) {
    alert("Sınav ID, Yeni Tarih ve Yeni Oturum zorunludur.");
    return;
  }

  try {
    const res = await fetch(`${API}/sinavlar/${sinavId}/saat-guncelle`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ yeni_tarih: tarih, yeni_oturum_id: oturumId })
    });

    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Güncelleme başarısız.");
    }

    alert(json.message || "Sınav başarıyla güncellendi.");

    document.getElementById("guncelle-sinav-id").value = "";
    document.getElementById("guncelle-tarih").value = "";

    loadTablo("/sinavlar", "tablo-sinavlar");

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

// ========================
// PERSONEL MÜSAİTLİK
// ========================

async function personelIzinEkle() {
  const personelId = document.getElementById("izin-personel-id")?.value;
  const tarih = document.getElementById("izin-tarih")?.value;
  const oturumId = document.getElementById("izin-oturum-id")?.value;
  const uygunValue = document.getElementById("izin-uygun")?.value;

  if (!personelId || !tarih || !oturumId || uygunValue === "") {
    alert("Personel ID, tarih, oturum ve durum alanlarını doldurmalısın.");
    return;
  }

  const uygunMu = uygunValue === "1";

  const payload = {
    PersonelID: parseInt(personelId),
    Tarih: tarih,
    OturumID: parseInt(oturumId),
    MazeretTuru: uygunMu ? "Müsait" : "Müsait Değil",
    Uygun: uygunMu
  };

  try {
    const json = await apiPost("/personel-durum", payload);

    alert(json.message || "Personel müsaitlik durumu kaydedildi.");

    document.getElementById("izin-personel-id").value = "";
    document.getElementById("izin-tarih").value = "";
    document.getElementById("izin-oturum-id").value = "";
    document.getElementById("izin-uygun").value = "";

  } catch (err) {
    alert("HATA: " + err.message);
  }
}

// ========================
// RAPORLAR
// ========================

async function rapor(tip) {
  const el = document.getElementById("rapor-sonuc");
  if (!el) return;

  el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Yükleniyor...</p>';

  try {
    const res = await fetch(API + "/raporlar/" + tip);
    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Rapor yüklenemedi.");
    }

    const data = json.data ?? json;
    const list = Array.isArray(data) ? data : [data];

    el.innerHTML = `
      <div class="form-box">
        <p style="margin-bottom:12px;color:var(--text-muted);font-size:11px;font-family:monospace;text-transform:uppercase">
          SQL VIEW: ${json.sql_view ?? tip}
        </p>
        ${list.length ? buildTable(list) : '<p style="color:var(--text-muted)">Rapor kaydı bulunamadı.</p>'}
      </div>
    `;

  } catch (err) {
    el.innerHTML = `<p style="color:var(--danger)">Rapor yüklenemedi: ${err.message}</p>`;
  }
}

// ========================
// LOGLAR
// ========================

async function loadLoglar() {
  const el = document.getElementById("tablo-loglar");
  if (!el) return;

  el.innerHTML = '<p style="color:var(--text-muted);font-family:monospace">Yükleniyor...</p>';

  try {
    const res = await fetch(API + "/loglar");
    const json = await res.json();

    if (!res.ok) {
      throw new Error(json.detail || "Loglar yüklenemedi.");
    }

    el.innerHTML = `
      <div class="form-box" style="margin-bottom:16px">
        <p style="font-size:11px;font-family:monospace;color:var(--text-muted)">
          Trigger ve backend işlemleri log kayıtlarını burada gösterir.
        </p>
      </div>
      ${buildTable(json.data ?? [])}
    `;

  } catch (err) {
    el.innerHTML = `<p style="color:var(--danger)">Loglar yüklenemedi: ${err.message}</p>`;
  }
}

// ========================
// BAŞLANGIÇ
// ========================

document.addEventListener("DOMContentLoaded", () => {
  loadDashboard();
  loadLookuplar();
  loadDersliklerCache();
  fillPersonelSelect("manual-personel-id");
});

// ========================
// GLOBAL BAĞLANTILAR
// ========================

window.showPage = showPage;
window.toggleForm = toggleForm;

window.sinavEkle = sinavEkle;
window.dersEkle = dersEkle;
window.personelEkle = personelEkle;
window.kayitSil = kayitSil;

window.salonOneri = salonOneri;
window.salonAta = salonAta;
window.sinavBilgisiGoster = sinavBilgisiGoster;

window.gozetmenOneri = gozetmenOneri;
window.gozetmenAta = gozetmenAta;

window.manuelSinavSalonlariniYukle = manuelSinavSalonlariniYukle;
window.manuelsinavSalonlariniYukle = manuelSinavSalonlariniYukle;
window.fillPersonelUygunlukSelect = fillPersonelUygunlukSelect;
window.manuelGozetmenAta = manuelGozetmenAta;

window.sinavAtamalariniGoster = sinavAtamalariniGoster;
window.gozetmenAtamasiSil = gozetmenAtamasiSil;
window.sinavSalonuSil = sinavSalonuSil;
window.tumSinavAtamalariniSil = tumSinavAtamalariniSil;

window.sinavGuncelle = sinavGuncelle;
window.personelIzinEkle = personelIzinEkle;
window.rapor = rapor;