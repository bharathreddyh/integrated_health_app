# CLAUDE.md

## Project
Flutter medical app (Dart ≥3.0). Screens for 3D anatomy models, canvas annotations, library, downloads, patient management.

## Stack
- **State**: `provider` + `ChangeNotifier`
- **DB**: `sqflite` (local), `cloud_firestore` (remote)
- **Persistence**: `shared_preferences`
- **Auth**: `UserService` (custom, `lib/services/user_service.dart`)

## Key Paths
| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry, initialization |
| `lib/config/model_3d_config.dart` | All 3D model/category definitions |
| `lib/services/` | Business logic (favorites, user, voice, models) |
| `lib/screens/home/home_screen.dart` | Main dashboard grid |
| `lib/screens/models_3d/` | 3D model browser + category view |
| `lib/screens/favorites/` | Favourites screen |

## Commands
```bash
flutter run                  # run on device
flutter build apk            # release build
flutter analyze              # lint
flutter test                 # tests
```

## Conventions
- Dark theme only: bg `0xFF0F172A`, card `0xFF1E293B`, border `0xFF334155`
- Screens are `StatefulWidget`; services are singletons via `.instance`
- Navigation: `Navigator.push` with `MaterialPageRoute` (no named routes for feature screens)
- Model cards use 4-column `GridView`
- New screens go in `lib/screens/<feature>/`
- New services go in `lib/services/`

## Active Branch
`claude/3d-model-viewer-firebase-9XboJ`
