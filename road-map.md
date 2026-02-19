# Mobile App Development Roadmap (Flutter Edition)

This document outlines the step-by-step implementation plan for the **Quran Lake** mobile application using **Flutter**.

## 🛠 Tech Stack & Requirements
*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Local Data (Complex)**: SQLite (`sqflite`) - *For caching Surahs, Reciters, Prayer Times.*
*   **Local Data (Simple)**: Shared Preferences (`shared_preferences`) - *For User Settings, Theme, Locale.*
*   **Networking**: Dio or Http - *For API calls.*
*   **Localization**: `flutter_localizations` + `intl` - *For Arabic/English support.*
*   **Design System**: **STRICT ADHERENCE** to the provided design system (to be supplied).

---

## 🟢 Phase 1: Foundation & Architecture
**Goal:** Set up the Flutter project, architecture, and essential libraries.

- [ ] **Project Initialization**
    - [ ] `flutter create quran_lake`
    - [ ] Set up folder structure:
        - `lib/core` (constants, theme, utils)
        - `lib/data` (models, repositories, local_db, api)
        - `lib/providers` (state management)
        - `lib/ui/screens` (Pages)
        - `lib/ui/widgets` (Reusable Components)
    - [ ] **Dependency Installation**:
        - `provider` (State Management)
        - `sqflite` & `path` (Database)
        - `shared_preferences` (Settings)
        - `dio` (Networking)
        - `flutter_localizations` & `intl` (i18n)
        - `just_audio` (Audio Streaming)
        - `geolocator` (Location)
        - `permission_handler` (Permissions)
        - `shimmer` (Loading Animations)

- [ ] **Design System & Theme Setup**
    - [ ] Create `AppTheme` class.
    - [ ] Define `lightTheme` and `darkTheme` based on the Design System specs (Colors, Typography, Shapes).
    - [ ] **Instruction**: Do not hardcode colors/fonts in widgets; always use `Theme.of(context)`.

- [ ] **Navigation & Routing Setup**
    - [ ] Create `MainScreen` (Scaffold with `BottomNavigationBar`).
    - [ ] Create placeholder screens for Tabs:
        - `HomeScreen`
        - `RecitersScreen`
        - `PrayerTimesScreen`
        - `SettingsScreen`
    - [ ] Set up Named Routes or `GoRouter` for deep navigation (e.g., `/reciter_details`, `/player`).

- [ ] **Localization Setup**
    - [ ] Configure `MaterialApp` with `localizationsDelegates`.
    - [ ] Create ARB files (`intl_en.arb`, `intl_ar.arb`).
    - [ ] Verify RTL (Right-to-Left) layout switching works.

---

## 🟡 Phase 2: Core Data & Audio (Provider Implementation)
**Goal:** Implement the "Listen" features using Provider and API.

- [ ] **API Layer**
    - [ ] Create `DioClient` with interceptors (logging, error handling).
    - [ ] Implement `RecitersRepository`: Fetch list from MP3Quran API.
    - [ ] Implement `SurahRepository`: Fetch Surah names/metadata.

- [ ] **State Management (Provider)**
    - [ ] Create `ReciterProvider`: Handles fetching, loading states, and error messages.
        - [ ] **Optimization**: Implement Lazy Loading / Pagination logic (load data in chunks if API permits, or render efficiently).
    - [ ] Create `AudioProvider`: Handles playlist management, current track, and playback state.

- [ ] **Audio Player Implementation**
    - [ ] Integrate `just_audio` service.
    - [ ] Implement background audio support (`audio_service` might be needed for lock screen controls).
    - [ ] Create the **Mini Player** widget (floating bottom bar).
    - [ ] Create the **Full Player** screen (Modal Bottom Sheet or Full Page).

- [ ] **UI Implementation (Follow Design System)**
    - [ ] **Loading States**: Implement **Shimmer Skeleton** loaders for all lists (Reciters, Surahs) instead of standard spinners.
    - [ ] **Reciters List Screen**:
        - [ ] Grid/List view using `ReciterProvider`.
        - [ ] Implement **Infinite Scroll** (fetch/render more as user scrolls to bottom).
    - [ ] **Reciter Details Screen**: 
        - [ ] List of Surahs for selected reciter.
        - [ ] Implement Search within the list.

---

## 🟠 Phase 3: Prayer Times & Local Storage (SQLite)
**Goal:** Implement offline-first prayer times and location logic.

- [x] **Database Setup (SQLite)**
    - [x] Initialize `DatabaseHelper`.
    - [x] Create tables: `prayer_times_cache`, `location_cache`.

- [x] **Location & Prayer Logic**
    - [x] Implement `LocationService` using `geolocator`.
    - [x] Implement `PrayerTimeRepository`:
        1.  Check SQLite for today's data.
        2.  If missing, fetch from Aladhan API.
        3.  Save to SQLite.

- [x] **Prayer Times Provider**
    - [x] Create `PrayerProvider`: Manage current prayer, next prayer countdown, and location state.
    - [x] Implement "Time Until Next Prayer" timer (updates every minute).

- [x] **UI Implementation**
    - [x] **Prayer Times Screen**: Display schedule and countdown.
    - [x] **Home Dashboard Screen**: 
        - [x] Integrate "Next Prayer" widget.
        - [x] Integrate "Ayah of the Day" widget.
        - [x] Integrate "Quick Surah" grid.

---

## 🔵 Phase 4: Settings & Preferences (SharedPrefs)
**Goal:** Manage user preferences and persistence.

- [ ] **Settings Provider**
    - [ ] Create `SettingsProvider`.

    - [ ] Implement `Locale` switching (Ar/En).
    - [ ] Persist choices using `shared_preferences`.

- [ ] **Settings Screen UI**
    - [ ] Build UI for Language and Theme toggles.
    - [ ] Add "Clear Cache" button (for troubleshooting).

- [ ] **Search Feature**
    - [ ] Implement client-side search logic in `ReciterProvider`.
    - [ ] Add Search Bar to Reciters Screen.

---

## 🚀 Phase 5: Testing & Release
- [ ] **Testing**
    - [ ] Unit Test: Test `PrayerTime` calculation logic.
    - [ ] Widget Test: Verify critical UI components match Design System.
    - [ ] Integration Test: Full flow (Open App -> Select Reciter -> Play Audio).
- [ ] **Optimization**
    - [ ] Check for memory leaks (dispose providers/controllers).
    - [ ] Verify app size and performance.
