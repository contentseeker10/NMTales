# ⚡ Бекенд NMTales

Ласкаво просимо до бекенд-сервісу **NMTales**. Це високопродуктивний RESTful Web API, побудований на базі **.NET 8**, який забезпечує автентифікацію користувачів, відстеження прогресу, збереження навчальних питань та інтеграцію з ШІ-тьютором для ігрової платформи NMTales.

---

## 🚀 Особливості

- **⚡ Легкий та швидкий**: Створений за допомогою ASP.NET Core Minimal APIs & Controllers.
- **🔐 Безпечна авторизація**: JWT Bearer автентифікація та сучасне хешування паролів за допомогою **BCrypt** (вхід за юзернеймом).
- **🐘 Повноцінна БД PostgreSQL**: Використання PostgreSQL для збереження даних з підтримкою автоматичних міграцій Entity Framework Core.
- **🐳 Контейнеризація бази даних**: Швидкий локальний запуск бази даних в один клік через **Docker Compose**.
- **🤖 Інтеграція з ШІ**: Підключення до моделей Gemini (через `GeminiService`) для інтерактивної взаємодії.
- **📚 Інтерактивна документація API**: Інтеграція зі Swagger UI «з коробки» для зручного тестування ендпоінтів.

---

## 🛠️ Системні вимоги

Для локального запуску бекенду переконайтеся, що у вас встановлено:
* [**.NET 8.0 SDK**](https://dotnet.microsoft.com/download/dotnet/8.0) або новішої версії.
* [**Docker Desktop**](https://www.docker.com/products/docker-desktop/) для запуску локальної бази даних.

---

## 🏃 Швидкий старт

### 1. Запуск бази даних (PostgreSQL)
Перейдіть до директорії бекенду та запустіть контейнер бази даних за допомогою Docker Compose:
```bash
cd game/backend
docker compose up -d
```
Це розгорне контейнер PostgreSQL на стандартному порту `5432` з базою даних `nmtales`.

### 2. Відновлення та збірка проєкту
Перейдіть до папки самого веб-додатку та відновіть залежності:
```bash
cd NMTales.Backend
dotnet restore
dotnet build
```

### 3. Запуск сервера
Запустіть сервер у режимі розробки:
```bash
dotnet run
```
При першому запуску сервер автоматично виявить підключення до PostgreSQL, створить необхідні таблиці (застосує міграції) та наповнить базу початковими даними (Seed).

За замовчуванням сервер запуститься на:
* **HTTPS**: `https://localhost:7142`
* **HTTP**: `http://localhost:5142`

---

## 🔍 Тестування API

### Swagger UI (Тестування у браузері)
Коли сервер запущено, відкрийте браузер та перейдіть за адресою:
```
http://localhost:5142/swagger
```
Тут ви можете детально вивчити всі доступні ендпоінти (`/api/auth`, `/api/question` тощо) та протестувати їх.

### Файл HTTP-запитів
Ви також можете скористатися файлом [NMTales.Backend.http](file:///d:/Development/GameDev/NMTales/game/backend/NMTales.Backend/NMTales.Backend.http) у вашому IDE для швидкого надсилання готових запитів на реєстрацію, вхід та отримання статусу.

---

## ⚙️ Конфігурація та секрети

Налаштування підключення до локальної БД знаходяться в [appsettings.Development.json](file:///d:/Development/GameDev/NMTales/game/backend/NMTales.Backend/appsettings.Development.json):
```json
"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Database=nmtales;Username=postgres;Password=nmtales_password;Ssl Mode=Prefer;"
}
```

> [!IMPORTANT]
> Якщо ви раніше використовували хмарну базу даних (наприклад, Neon) та зберігали рядок підключення у **User Secrets**, він перекриє локальні налаштування. Щоб використовувати локальну БД у Docker, видаліть перекриття командою:
> ```bash
> dotnet user-secrets remove ConnectionStrings:DefaultConnection
> ```

---

## 💾 Робота з міграціями (EF Core)

Якщо ви змінили C# моделі в коді та хочете оновити схему бази даних:

1. Створіть нову міграцію:
   ```bash
   dotnet ef migrations add <НазваМіграції>
   ```
2. Оновіть базу даних вручну (або просто перезапустіть додаток):
   ```bash
   dotnet ef database update
   ```

---

## 🏗️ Архітектура проєкту

* **`Controllers/`**: Ендпоінти API (`AuthController`, `QuestionController` тощо).
* **`DTO/`**: Об'єкти передачі даних для запитів та відповідей.
* **`Models/`**: Сутності бази даних (`User`, `Question`, `PlayerStats`).
* **`Services/`**: Шар бізнес-логики (`AuthService`, `GeminiService`).
* **`Data/`**: Контекст бази даних (`ApplicationDbContext`) та наповнювач початковими даними (`DbSeeder`).
