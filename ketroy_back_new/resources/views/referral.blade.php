<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Переход в приложение</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8fafc, #e2e8f0);
            color: #1a202c;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            flex-direction: column;
            text-align: center;
        }

        .container {
            background: white;
            padding: 2rem 2.5rem;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
            max-width: 400px;
            width: 100%;
            animation: fadeIn 0.6s ease-out;
        }

        .spinner {
            margin: 1.5rem auto;
            width: 40px;
            height: 40px;
            border: 4px solid #cbd5e0;
            border-top-color: #3182ce;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        a.button {
            display: inline-block;
            margin-top: 1rem;
            padding: 0.75rem 1.5rem;
            background-color: #3182ce;
            color: white;
            border-radius: 8px;
            text-decoration: none;
            transition: background-color 0.2s ease-in-out;
        }

        a.button:hover {
            background-color: #2b6cb0;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Почти готово...</h2>
        <p>Вы будете перенаправлены в магазин приложений</p>
        <div class="spinner"></div>
        <a id="store-link" href="#" class="button">Перейти вручную</a>
    </div>

    <script>
        // Определяем платформу (iOS/Android) и URL
        let storeUrl = '{{ $defaultUrl ?? "https://google.com" }}';
        const ua = navigator.userAgent || navigator.vendor || window.opera;

        if (/android/i.test(ua)) {
            storeUrl = '{{ $androidUrl ?? "https://play.google.com/store/apps/details?id=com.yourapp" }}';
        } else if (/iPad|iPhone|iPod/.test(ua) && !window.MSStream) {
            storeUrl = '{{ rtrim($iosUrl ?? "https://apps.apple.com/app/ketroy-app/id6745003121", "?&") }}?ref={{ $token }}';
        }

        // Установка ссылки
        document.getElementById('store-link').href = storeUrl;

        // Автоматическая переадресация через 2 секунды
        setTimeout(() => {
            window.location.href = storeUrl;
        }, 2000);
    </script>
</body>
</html>
