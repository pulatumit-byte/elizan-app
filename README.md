# Elizan PWA — Kurulabilir Demo

Elizan temizlik ve apartman yönetimi uygulamasının **telefona kurulabilir** demo sürümü.

## İçerik

| Dosya | Görev |
|---|---|
| `index.html` | Açılış ekranı (animasyon + pırıltı sesi + "Ana ekrana ekle") |
| `prototype.html` | 18 ekranlık tasarım demosu (mobil uyumlu) |
| `manifest.webmanifest` | Uygulama adı, ikonlar, renkler, kısayollar |
| `sw.js` | Service worker — çevrimdışı çalışma |
| `icons/` | 192 / 512 / Apple 180 ikonları + SVG |
| `make-icons.ps1` | İkonları yeniden üretme betiği |

## Telefona kurulum (en kolay yol: Netlify Drop)

1. Tarayıcıda **https://app.netlify.com/drop** adresini açın.
2. `elizan-pwa` **klasörünü** sürükleyip bırakın (dosyaları değil, klasörü).
3. Size `https://xxxx.netlify.app` gibi bir adres verir.
4. Bu adresi **telefonunuzda** açın.
5. **Android/Chrome:** Menü (⋮) → **“Uygulamayı yükle”** ya da ekrandaki **“Ana ekrana ekle”** düğmesi.
6. **iPhone/Safari:** Paylaş (□↑) → **“Ana Ekrana Ekle”**.

Kurulduktan sonra simge ana ekranda görünür, tam ekran açılır ve çevrimdışı çalışır.

## Yerelde test

Service worker yalnızca **https://** veya **http://localhost** üzerinde çalışır.

- **VS Code** kullanıyorsanız: “Live Server” eklentisi → `index.html` → *Go Live*.
- Ya da herhangi bir statik sunucu (Node/Python kuruluysa):

```bash
npx serve .        # Node
python -m http.server 8080   # Python
```

Ardından `http://localhost:8080` adresini açın.

> Not: Bu makinede Node ve Python kurulu değil; telefon testi için Netlify Drop en pratik yol.

## Güncelleme

Dosyaları değiştirdikten sonra `sw.js` içindeki sürümü artırın:

```js
const CACHE = 'elizan-v2';
```

Aksi halde telefon eski sürümü önbellekten gösterebilir.

## Sınırlar

- Bu bir **tasarım demosudur**; giriş, ödeme ve veritabanı bağlantısı yoktur.
- Gerçek uygulama için sıradaki adım: **React + Vite + Tailwind + Firebase** ile çalışan sürüm.
