# Project structure

```
lib/
├── main.dart                 # Entry → MobileApp
├── app/
│   ├── app.dart              # MaterialApp, theme, routes
│   └── routes.dart           # AppRoutes
├── core/
│   ├── constants/            # api_constants, app_colors
│   ├── network/              # BeBlogHttp, BeBlogResponseParser
│   ├── navigation/           # MainShell (tab shell)
│   └── widgets/              # Shared UI (app bar, bottom nav, …)
├── data/
│   ├── models/dtos.dart      # API DTOs
│   ├── repositories/         # REST repositories
│   ├── auth/                 # AuthRepository + login/register models
│   └── data.dart             # Barrel export
└── features/
    ├── auth/screens/
    ├── home/screens/           # Home tab
    ├── posts/screens/          # Post detail, create post
    ├── search/screens/
    ├── reading_list/screens/
    ├── settings/screens/
    ├── review/screens/         # Book/review detail, create review
    └── developer/screens/
```

Import style: `package:mobile/...` (package name from `pubspec.yaml`).
