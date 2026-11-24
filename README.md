# Elizan — Android Paketi (Capacitor)

Bu klasör, Elizan PWA'sını **Android uygulamasına** çevirmek için hazırlanmıştır.
APK, GitHub Actions sunucularında derlenir; yerel makinede Java/Android SDK gerekmez.

## Klasör yapısı

| Yol | Görev |
|---|---|
| `www/` | PWA dosyaları (index.html, prototype.html, ikonlar) |
| `capacitor.config.json` | Uygulama kimliği (`com.elizan.app`) ve web dizini |
| `package.json` | Capacitor bağımlılıkları |
| `assets/` | 1024 ikon + 2732 splash görselleri |
| `.github/workflows/android.yml` | Otomatik APK derleme hattı |

## GitHub üzerinden APK üretme

1. GitHub'da **yeni bir repo** oluşturun (public veya private, ikisi de olur).
2. **Bu klasörün içeriğini** repo köküne yükleyin
   (`.github`, `www`, `assets`, `package.json`, `capacitor.config.json` kökte olmalı).
3. `main` dalına push edin.
4. Repo → **Actions** sekmesi → *Build Android APK* çalışır (~5-8 dk).
5. Yeşil tik → **Artifacts** → `elizan-apk-<numara>` indirin.
6. ZIP içindeki `app-debug.apk` dosyasını telefona atıp kurun
   (Ayarlar → *Bilinmeyen kaynaklara izin ver*).

## Yüklemeden önce kontrol

Paket bütünlüğünü doğrulamak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dogrula.ps1
```

Tüm satırlar `[OK]` ise GitHub'a yüklemeye hazırsınız.

## Yerelde derlemek isterseniz (opsiyonel)

Gereksinimler: Node 20+, Java 21, Android Studio / SDK.

```bash
npm install
npx cap add android
npx cap sync android
npx capacitor-assets generate --android
cd android && ./gradlew assembleDebug
```

Çıktı: `android/app/build/outputs/apk/debug/app-debug.apk`

## Notlar

- `android/` klasörü CI'da otomatik üretilir, repoya eklemeyin (`.gitignore`'da).
- Play Store için `assembleDebug` yerine imzalı `bundleRelease` (AAB) gerekir;
  bunun için keystore + GitHub Secrets tanımlanmalıdır.
- Web içeriği güncellenince yeni APK derlemek gerekir (TWA'dan farkı budur).
