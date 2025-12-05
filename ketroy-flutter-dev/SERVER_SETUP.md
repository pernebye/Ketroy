# Настройка сервера для Deep Linking

## Обзор

Для работы Universal Links (iOS) и App Links (Android) необходимо настроить сервер `app.ketroy-shop.kz`.

---

## 1. Настройка DNS

✅ **Уже выполнено**: Субдомен `app.ketroy-shop.kz` зарегистрирован и добавлен в DNS.

---

## 2. Файлы верификации

### 2.1 Apple App Site Association (для iOS)

Создайте файл по пути: `/.well-known/apple-app-site-association`

**URL:** `https://app.ketroy-shop.kz/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.kz.ketroy.shop",
        "paths": [
          "/invite/*",
          "/product/*",
          "/gift/*",
          "/profile/*",
          "/discount/*",
          "/promo/*",
          "/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["TEAM_ID.kz.ketroy.shop"]
  }
}
```

> ⚠️ **ВАЖНО:** Замените `TEAM_ID` на ваш Apple Developer Team ID (например: `ABC123XYZ.kz.ketroy.shop`)

**Как найти Team ID:**
1. Откройте [Apple Developer Portal](https://developer.apple.com)
2. Перейдите в Account → Membership
3. Скопируйте Team ID

### 2.2 Asset Links (для Android)

Создайте файл по пути: `/.well-known/assetlinks.json`

**URL:** `https://app.ketroy-shop.kz/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "kz.ketroy.shop",
      "sha256_cert_fingerprints": [
        "SHA256_FINGERPRINT_HERE"
      ]
    }
  }
]
```

> ⚠️ **ВАЖНО:** Замените `SHA256_FINGERPRINT_HERE` на SHA-256 отпечаток вашего ключа подписи.

**Как получить SHA-256 fingerprint:**

```bash
# Для debug ключа:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Для release ключа (замените путь на ваш keystore):
keytool -list -v -keystore path/to/your/keystore.jks -alias your_alias
```

Найдите строку `SHA256:` и скопируйте fingerprint в формате:
`AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99`

---

## 3. Настройка веб-сервера

### Требования к серверу:

1. **HTTPS обязателен** - файлы должны быть доступны только по HTTPS
2. **Content-Type**: `application/json`
3. **Без редиректов** - файлы должны отдаваться напрямую (без 301/302)
4. **Доступность** - файлы должны быть публично доступны без авторизации

### Пример для Nginx:

```nginx
server {
    listen 443 ssl;
    server_name app.ketroy-shop.kz;

    # SSL сертификаты
    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    # Обработка .well-known
    location /.well-known/ {
        root /var/www/app.ketroy-shop.kz;
        default_type application/json;
        add_header Content-Type application/json;
        
        # Отключаем кэширование для отладки
        add_header Cache-Control "no-cache, no-store";
    }

    # Обработка deep links - редирект на магазины приложений
    location /invite {
        # Определяем платформу и редиректим
        set $redirect_url "https://ketroy-shop.kz"; # fallback
        
        if ($http_user_agent ~* "iPhone|iPad|iPod") {
            set $redirect_url "https://apps.apple.com/app/ketroy-shop/id6743387498";
        }
        if ($http_user_agent ~* "Android") {
            set $redirect_url "https://play.google.com/store/apps/details?id=kz.ketroy.shop";
        }
        
        return 302 $redirect_url;
    }

    # Другие deep link пути
    location ~ ^/(product|gift|profile|discount|promo)/ {
        # Аналогичный редирект или обработка на бэкенде
        return 302 https://ketroy-shop.kz;
    }

    # Основной сайт (если нужен)
    location / {
        root /var/www/app.ketroy-shop.kz;
        index index.html;
    }
}
```

### Пример для Node.js/Express:

```javascript
const express = require('express');
const path = require('path');
const app = express();

// Apple App Site Association
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.sendFile(path.join(__dirname, '.well-known', 'apple-app-site-association'));
});

// Android Asset Links
app.get('/.well-known/assetlinks.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.sendFile(path.join(__dirname, '.well-known', 'assetlinks.json'));
});

// Обработка deep links
app.get('/invite', (req, res) => {
  const refCode = req.query.ref;
  const userAgent = req.get('User-Agent') || '';
  
  // Сохраняем ref код (опционально)
  if (refCode) {
    console.log(`Referral visit: ${refCode}`);
    // TODO: Сохранить в базу данных
  }
  
  // Редирект на магазин
  if (/iPhone|iPad|iPod/i.test(userAgent)) {
    res.redirect('https://apps.apple.com/app/ketroy-shop/id6743387498');
  } else if (/Android/i.test(userAgent)) {
    res.redirect('https://play.google.com/store/apps/details?id=kz.ketroy.shop');
  } else {
    // Десктоп или неизвестный агент - показываем страницу
    res.redirect('https://ketroy-shop.kz');
  }
});

app.listen(3000);
```

---

## 4. Проверка настройки

### Проверка iOS (Apple):

1. Откройте в браузере:
   ```
   https://app-site-association.cdn-apple.com/a/v1/app.ketroy-shop.kz
   ```
2. Или используйте инструмент Apple:
   ```
   https://search.developer.apple.com/appsearch-validation-tool/
   ```

### Проверка Android (Google):

1. Используйте Digital Asset Links API:
   ```
   https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://app.ketroy-shop.kz&relation=delegate_permission/common.handle_all_urls
   ```

### Проверка через curl:

```bash
# iOS
curl -I https://app.ketroy-shop.kz/.well-known/apple-app-site-association

# Android  
curl -I https://app.ketroy-shop.kz/.well-known/assetlinks.json
```

Ожидаемый ответ:
- HTTP/2 200
- Content-Type: application/json

---

## 5. Структура URL deep links

| Тип ссылки | URL формат | Параметры |
|------------|-----------|-----------|
| Приглашение/Промокод | `/invite?ref=PROMO_CODE` | `ref` - промокод пользователя |
| Товар | `/product/{id}` | `id` - ID товара |
| Подарок | `/gift/{id}` | `id` - ID подарка |
| Профиль | `/profile/{userId}` | `userId` - ID пользователя |
| Скидка | `/discount` | - |

**Примеры:**
- `https://app.ketroy-shop.kz/invite?ref=ABC123`
- `https://app.ketroy-shop.kz/product/12345`
- `https://app.ketroy-shop.kz/gift/567`

---

## 6. Обработка промокодов при установке

### Сценарий "Deferred Deep Link":

1. Пользователь переходит по ссылке `app.ketroy-shop.kz/invite?ref=ABC123`
2. Приложение не установлено → редирект в App Store/Google Play
3. Пользователь устанавливает приложение
4. При первом запуске приложение получает параметр `ref=ABC123`
5. Промокод автоматически применяется при регистрации

### Реализация на сервере (опционально):

Для отслеживания deferred deep links можно:

1. **Сохранять IP + fingerprint** при переходе по ссылке
2. **Проверять при первом запуске** приложения через API
3. **Возвращать сохранённый промокод** если IP совпадает

```javascript
// Пример API endpoint
app.post('/api/deferred-deep-link', (req, res) => {
  const { deviceId, ip } = req.body;
  
  // Ищем сохранённый промокод по IP (в течение 24 часов)
  const savedPromo = findSavedPromo(ip, deviceId);
  
  if (savedPromo) {
    res.json({ ref: savedPromo.refCode });
    // Удаляем после использования
    deleteSavedPromo(savedPromo.id);
  } else {
    res.json({ ref: null });
  }
});
```

---

## 7. Чек-лист

- [ ] Создан файл `/.well-known/apple-app-site-association`
- [ ] Создан файл `/.well-known/assetlinks.json`
- [ ] Заменён `TEAM_ID` на реальный Apple Team ID
- [ ] Заменён `SHA256_FINGERPRINT_HERE` на реальный fingerprint
- [ ] Файлы доступны по HTTPS
- [ ] Content-Type: application/json
- [ ] Проверено через Apple/Google валидаторы
- [ ] Настроен редирект `/invite` на магазины приложений
- [ ] Протестировано на реальных устройствах

---

## 8. Troubleshooting

### iOS: Universal Links не работают

1. **Проверьте формат AASA файла** - должен быть валидный JSON
2. **Убедитесь что HTTPS** - HTTP не поддерживается
3. **Проверьте Team ID** - должен совпадать с Apple Developer Portal
4. **Переустановите приложение** - iOS кэширует AASA
5. **Подождите** - Apple кэширует файл, обновление может занять время

### Android: App Links не работают

1. **Проверьте SHA256 fingerprint** - должен совпадать с ключом подписи
2. **Убедитесь в autoVerify** - в AndroidManifest.xml должно быть `android:autoVerify="true"`
3. **Проверьте package_name** - должен точно совпадать
4. **Очистите данные приложения** или переустановите

### Общие проблемы

- **Редиректы** - файлы должны отдаваться без редиректов
- **Кэширование** - отключите кэш для отладки
- **CORS** - не требуется для этих файлов

