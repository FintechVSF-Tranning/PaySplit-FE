# 💸 PaySplit – Smart Bill Splitter & Settlement

PaySplit is a mobile-first solution that takes the awkwardness and math out of group expenses. By combining AI OCR with Dynamic VietQR, it automates receipt parsing, bill splitting, and debt reminders.

## 🚀 Core Features (MVP)

- **Smart OCR:** Instantly scan receipts to extract items, prices, and auto-calculate VAT/service fees.
- **Dynamic VietQR:** Generate user-specific QR codes for precise payment amounts.
- **Smart Reminders:** Automated, friendly notifications sent via chat platforms to debtors.
- **1-Click Settlement:** Tap to pay instantly without manual data entry.

## 🛠 Tech Stack

- **Mobile Client:** Flutter (Dart) - Cross-platform UI.
- **Backend API:** Go (Golang) with Gin/Fiber - High-performance REST & WebSocket server.
- **Database:** PostgreSQL.
- **Real-time:** WebSockets (Gorilla WebSocket) for instant payment status updates.
- **AI/Integration:** OCR processing & VietQR API.

---

## 📱 Kiến trúc Frontend (Flutter)

Dự án đi theo **Clean Architecture + feature-first** — cách tổ chức phổ biến ở các repo Flutter quy mô lớn. Mỗi feature sở hữu trọn vẹn 3 tầng `data → domain → presentation`, nên có thể test độc lập, xoá hoặc tách ra thành package riêng mà không kéo theo feature khác.

### Cây thư mục

```
lib/
├── main.dart                  # entry mặc định của `flutter run` (= flavor development)
├── main_development.dart      # entry point theo từng flavor
├── main_staging.dart
├── main_production.dart
├── bootstrap.dart             # khởi động dùng chung: EnvConfig → DI → runApp
├── app/
│   ├── app.dart               # widget gốc MaterialApp.router
│   ├── router/                # cấu hình go_router + hằng số route
│   └── theme/                 # theme Material 3 sáng/tối
├── core/                      # hạ tầng dùng chung cho mọi feature
│   ├── config/                # EnvConfig, enum Flavor
│   ├── constants/             # ApiEndpoints, StorageKeys
│   ├── error/                 # Failure (tầng domain) + Exception (tầng data)
│   ├── network/               # Dio module, interceptor, TokenStorage
│   └── usecase/               # lớp nền UseCase<ReturnType, Params>
├── di/                        # wiring get_it + injectable
└── features/
    └── <tên_feature>/
        ├── data/              # model (freezed+json), datasource (retrofit), repository impl
        ├── domain/            # entity, interface repository, usecase
        └── presentation/      # provider riverpod, page, widget
```

### Nguyên tắc phụ thuộc

```
presentation ──→ domain ←── data
```

Tầng **domain** không phụ thuộc vào bất cứ thứ gì (không biết Dio, không biết JSON). Tầng **data** hiện thực hoá các interface do domain định nghĩa. Cụ thể trong code: một `Page` chỉ được import _entity_ và _usecase_ — không bao giờ import `Dio` hay `Model`.

Đây là lý do khi đổi backend (REST → GraphQL) hay đổi thư viện HTTP, bạn chỉ sửa tầng `data/`, toàn bộ `domain/` và `presentation/` giữ nguyên.

---

## 🧩 Chi tiết từng phần đã dựng

### 1. Tầng `core/` — hạ tầng dùng chung

| File                                                                                                   | Nhiệm vụ                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [core/error/failures.dart](lib/core/error/failures.dart)                                               | Định nghĩa `Failure` (dựa trên `Equatable`) và các lớp con: `ServerFailure`, `NetworkFailure`, `CacheFailure`, `UnauthorizedFailure`, `ValidationFailure`, `UnexpectedFailure`. Đây là "lỗi" mà tầng domain/UI nhìn thấy. |
| [core/error/exceptions.dart](lib/core/error/exceptions.dart)                                           | Các `Exception` mà tầng data ném ra. Tách riêng khỏi `Failure` để domain không phụ thuộc chi tiết kỹ thuật.                                                                                                               |
| [core/network/dio_failure_mapper.dart](lib/core/network/dio_failure_mapper.dart)                       | Hàm `mapDioError()` — **nơi duy nhất** dịch `DioException` sang `Failure`. Timeout → `NetworkFailure`, 401/403 → `UnauthorizedFailure`, 400/422 → `ValidationFailure`, còn lại → `ServerFailure`.                         |
| [core/network/dio_client.dart](lib/core/network/dio_client.dart)                                       | `@module NetworkModule` cung cấp instance `Dio` duy nhất: baseUrl lấy từ `EnvConfig`, timeout 15s, gắn `AuthInterceptor`, và chỉ bật `PrettyDioLogger` khi **không** phải bản production.                                 |
| [core/network/interceptors/auth_interceptor.dart](lib/core/network/interceptors/auth_interceptor.dart) | Tự động gắn header `Authorization: Bearer <token>` vào mọi request; khi nhận 401 thì xoá token đã hết hạn.                                                                                                                |
| [core/network/token_storage.dart](lib/core/network/token_storage.dart)                                 | Bọc `flutter_secure_storage` để lưu access/refresh token. Đặt ở `core` để cả interceptor lẫn repository auth đều dùng được mà không phụ thuộc lẫn nhau.                                                                   |
| [core/network/network_info.dart](lib/core/network/network_info.dart)                                   | Kiểm tra kết nối mạng qua `connectivity_plus` (interface + impl để dễ mock khi test).                                                                                                                                     |
| [core/network/third_party_module.dart](lib/core/network/third_party_module.dart)                       | Đăng ký các class của thư viện ngoài (`FlutterSecureStorage`, `Connectivity`) cho injectable — vì không thể gắn annotation `@injectable` vào code của package bên thứ ba.                                                 |
| [core/config/env_config.dart](lib/core/config/env_config.dart)                                         | Enum `Flavor` (development / staging / production) và `EnvConfig` giữ `apiBaseUrl`, `appName`.                                                                                                                            |
| [core/constants/api_endpoints.dart](lib/core/constants/api_endpoints.dart)                             | Tập trung toàn bộ đường dẫn API, tránh rải chuỗi "magic string" khắp datasource.                                                                                                                                          |
| [core/constants/storage_keys.dart](lib/core/constants/storage_keys.dart)                               | Các key dùng cho secure storage / shared preferences.                                                                                                                                                                     |
| [core/usecase/usecase.dart](lib/core/usecase/usecase.dart)                                             | Lớp nền `UseCase<ReturnType, Params>` — mọi usecase là một object có thể gọi như hàm, luôn trả `Future<Either<Failure, T>>`. Kèm `NoParams` cho usecase không cần tham số.                                                |

### 2. Xử lý lỗi — không dùng try/catch ở tầng trên

Luồng lỗi đi như sau:

```
Datasource ném DioException
   └→ Repository bắt, gọi mapDioError() → trả Left(Failure)
        └→ UseCase trả nguyên Either lên
             └→ Controller/Provider đọc và đổi thành AsyncError
                  └→ UI hiện SnackBar
```

Điểm mấu chốt: **không có lớp nào phía trên repository dùng `try/catch`**. Lỗi được truyền đi như một _giá trị_ (`Either<Failure, T>` của `fpdart`), nên compiler bắt buộc bạn xử lý nhánh lỗi — không thể "quên" như với exception.

### 3. Quản lý state & Dependency Injection

Dự án dùng **song song 2 công cụ, mỗi cái một việc**:

- **`get_it` + `injectable`** → wiring tầng data (repository, datasource, usecase). Chạy lúc khởi động app, không liên quan widget tree.
- **`Riverpod`** → quản lý state của UI và trigger rebuild widget.

Điểm nối giữa 2 cái là ở controller: `AuthController` lấy usecase ra bằng `getIt<LoginUseCase>()` rồi bọc kết quả vào `AsyncValue`. Cách này giúp tầng data hoàn toàn không biết Riverpod tồn tại.

| File                                       | Nhiệm vụ                                                                                                                                                                      |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [di/injection.dart](lib/di/injection.dart) | `@InjectableInit` — build_runner quét mọi class có `@injectable` / `@lazySingleton` / `@module` và sinh ra `injection.config.dart`.                                           |
| [bootstrap.dart](lib/bootstrap.dart)       | Hàm khởi động dùng chung cho cả 3 flavor: khởi tạo binding → set `EnvConfig` → chạy DI → `runApp`. Nhờ vậy không phải copy-paste logic khởi động vào từng file `main_*.dart`. |

### 4. Flavor (môi trường dev / staging / production)

Ba file `main_*.dart` chỉ khác nhau ở tham số truyền vào `bootstrap()`. `apiBaseUrl` ưu tiên đọc từ `--dart-define=API_BASE_URL=...`, nếu không có thì dùng giá trị mặc định của flavor đó — tiện khi cần trỏ về Go API chạy local.

### 5. Điều hướng & luồng đăng nhập

| File                                                         | Nhiệm vụ                                                |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| [app/router/app_routes.dart](lib/app/router/app_routes.dart) | Hằng số đường dẫn (`/splash`, `/login`, `/`, `/bills`). |
| [app/router/app_router.dart](lib/app/router/app_router.dart) | Cấu hình `go_router` + logic `redirect` bảo vệ route.   |
| [app/app.dart](lib/app/app.dart)                             | `MaterialApp.router` gắn theme sáng/tối và router.      |

Luồng auth hoạt động như sau:

1. `AuthController.build()` chạy khi app mở, gọi `GetCurrentUserUseCase` để khôi phục phiên đăng nhập.
2. Trong lúc chờ, `redirect` giữ người dùng ở màn **Splash**.
3. Không có user → đẩy về **Login**. Có user → vào **Home**.
4. Sau khi login/logout, `_GoRouterRefreshNotifier` báo cho go_router chạy lại `redirect`.

> **Lưu ý kỹ thuật**: `_GoRouterRefreshNotifier` là cầu nối giữa Riverpod và go_router thông qua `refreshListenable`. Cách làm này giúp router _tính lại redirect_ mà **không tạo lại instance `GoRouter`** — nếu tạo lại, navigation stack sẽ bị reset mỗi lần đăng nhập/đăng xuất.

### 6. Feature `auth` — bản mẫu đầy đủ

```
features/auth/
├── domain/
│   ├── entities/user_entity.dart          # entity thuần, không có JSON
│   ├── repositories/auth_repository.dart  # interface (abstract)
│   └── usecases/                          # login, register, logout, getCurrentUser
├── data/
│   ├── models/user_model.dart             # freezed + fromJson + toEntity()
│   ├── models/auth_response_model.dart    # { access_token, refresh_token, user }
│   ├── datasources/auth_remote_datasource.dart  # interface @RestApi, retrofit tự sinh code
│   └── repositories/auth_repository_impl.dart   # hiện thực interface domain
└── presentation/
    ├── providers/auth_controller.dart     # @riverpod, giữ AsyncValue<UserEntity?>
    └── pages/login_page.dart              # form + validate + loading + SnackBar lỗi
```

Chú ý cách tách **Entity** và **Model**: `UserEntity` (domain) không có `fromJson`, còn `UserModel` (data) có `fromJson` và hàm `toEntity()`. Nhờ vậy khi backend đổi tên field JSON, bạn chỉ sửa `UserModel`, phần còn lại của app không bị ảnh hưởng.

### 7. Feature `bills` — bản mẫu tối giản để nhân bản

Cùng cấu trúc như `auth` nhưng chỉ có 1 usecase (`GetBillsUseCase`). Đây là template ngắn nhất để bạn copy khi thêm feature mới. `BillsPage` minh hoạ pattern `AsyncValue.when()` xử lý đủ 3 trạng thái loading / error / data, kèm pull-to-refresh và định dạng tiền VNĐ bằng `intl`.

### 8. Test mẫu

| File                                                                                     | Kiểm tra điều gì                                                                                    |
| ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [test/features/auth/login_usecase_test.dart](test/features/auth/login_usecase_test.dart) | Unit test usecase với `mocktail` mock repository — chứng minh domain test được mà không cần server. |
| [test/widget_test.dart](test/widget_test.dart)                                           | Widget test `LoginPage` render đúng form.                                                           |

---

## ⚠️ Những điểm bạn nên kiểm tra lại

1. **Hợp đồng API với backend Go.** Tôi đặt giả định theo quy ước `snake_case`, bạn cần đối chiếu với API thật:
   - `POST /auth/login` nhận `{email, password}` → trả `{access_token, refresh_token, user: {id, name, email, avatar_url, phone_number}}`
   - `GET /auth/me` → object user như trên
   - `GET /bills` → mảng `{id, title, total_amount, status, created_at}`, trong đó `status` phải là chuỗi `"pending"` hoặc `"settled"` (khớp tên enum `BillStatus`)
2. **Chưa chạy thử trên máy/emulator thật.** Mới verify bằng `flutter analyze` (sạch) và `flutter test` (pass).
3. **`retrofit` đang bị ghim ở bản `4.7.3`.** Bản 4.9.x thêm enum `Parser.DartMappable` mà `retrofit_generator` 9.x chưa xử lý; còn generator 10.x lại xung đột version `build` với `freezed` 2.x. Khi nào nâng lên `freezed` 3.x thì có thể gỡ ghim này.
4. **Refresh token chưa được hiện thực.** `AuthInterceptor` mới chỉ xoá token khi gặp 401. Logic gọi `/auth/refresh` rồi retry request cũ nên đặt ở repository, không nên nhét vào interceptor.

---

## 🚀 Bắt đầu chạy

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # BẮT BUỘC: sinh *.g.dart / *.freezed.dart

flutter run                                     # flavor development
flutter run -t lib/main_staging.dart            # flavor staging
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1   # trỏ về Go API chạy local

or

flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/v1
```

> `10.0.2.2` là địa chỉ để Android emulator gọi về `localhost` của máy host. Nếu dùng máy thật, thay bằng IP LAN của máy bạn.

### Chạy trong Android Studio

1. `File → Open` → chọn thư mục gốc `PaySplit-FE` (không phải thư mục `android/`).
2. Chọn device ở thanh trên, rồi chọn run configuration `main.dart` → bấm ▶.
3. Muốn chạy flavor khác: `Run → Edit Configurations → Dart entrypoint` trỏ tới `lib/main_staging.dart`, và thêm `--dart-define=API_BASE_URL=...` vào ô _Additional run args_.

### Cấu hình Android đã xử lý sẵn

| Việc                          | Nơi cấu hình                                                           | Lý do                                                                                                                                                                         |
| ----------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Quyền `INTERNET`              | [main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)   | Manifest debug của Flutter đã có sẵn quyền này cho hot reload, nhưng **bản release thì không** — thiếu là app release không gọi được API nào.                                 |
| `usesCleartextTraffic="true"` | [debug/AndroidManifest.xml](android/app/src/debug/AndroidManifest.xml) | Android 9+ chặn HTTP không mã hoá, nên gọi `http://10.0.2.2:8080` sẽ fail. Chỉ bật cho **debug** — file này không được merge vào bản release, nên release vẫn bắt buộc HTTPS. |

Khi đang sửa model/provider, nên bật codegen chạy nền:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## ➕ Cách thêm một feature mới

Copy theo `lib/features/bills/` — đây là bản tham chiếu tối giản. Thứ tự làm từ trong ra ngoài (domain trước, UI sau):

1. `domain/entities/` — entity freezed, **không** có JSON.
2. `domain/repositories/` — interface abstract, trả `Either<Failure, T>`.
3. `domain/usecases/` — mỗi thao tác một class `@injectable`.
4. `data/models/` — model freezed có `fromJson` + `toEntity()`.
5. `data/datasources/` — interface retrofit `@RestApi() @injectable`.
6. `data/repositories/` — impl gắn `@LazySingleton(as: YourRepository)`.
7. `presentation/providers/` — controller `@riverpod` gọi `getIt<YourUseCase>()`.
8. Khai báo route mới trong `app/router/`.
9. Chạy lại `build_runner`.
