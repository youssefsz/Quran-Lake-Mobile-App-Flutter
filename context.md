# Website Functional Analysis & Mobile App Blueprint

## 1. Screen-Based Breakdown

### Screen 1: Home Dashboard
*   **Purpose**: Central hub for quick access to daily content and prayer times.
*   **Functionalities**:
    *   **Ayah of the Day**: Displays a random verse (Arabic text, Surah name, Ayah number).
    *   **Quick Prayer Status**: Horizontal scroll or grid showing 5 daily prayers with the "Next Prayer" highlighted and a countdown.
    *   **Surah Grid**: Full list of 114 Surahs for quick playback using the default reciter.
*   **User Actions**:
    *   Tap "Listen Now" on the Hero section (navigates to Reciters).
    *   Tap "Full Schedule" (navigates to Prayer Times).
    *   Tap any Surah card to immediately start playing (uses default reciter).
*   **Data Displayed**: Random Ayah, Current/Next Prayer times, Surah list (Number, Name, Meaning, Ayah count, Type: Meccan/Medinan).
*   **Navigation**: Leads to `Reciters List`, `Prayer Times`, or opens `Audio Player`.

### Screen 2: Prayer Times
*   **Purpose**: Detailed prayer schedule and location management.
*   **Functionalities**:
    *   **Live Countdown**: Prominent timer counting down to the next prayer.
    *   **Full Schedule**: List of all prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) for the current day.
    *   **Location Detection**: Automatically detects and displays the user's City and Country.
    *   **Adhan Player**: Plays audio notification at prayer time.
*   **User Actions**:
    *   Grant/Deny Location Permissions.
    *   Refresh Location/Times.
    *   Clear Cache (for troubleshooting).
*   **Data Displayed**: City, Country, Date (Gregorian & Hijri), 6 Prayer Times, "Next" indicator.

### Screen 3: Reciters Directory
*   **Purpose**: Browse and search for specific Quran reciters.
*   **Functionalities**:
    *   **Reciter List**: Grid/List of all available reciters.
    *   **Search**: Real-time filtering of reciters by name.
    *   **Favorites (Implicit)**: Potential to add "favorite" functionality here in a mobile app context.
*   **User Actions**: Scroll list, Type in search bar, Tap reciter card.
*   **Data Displayed**: Reciter Name, Reciter Photo/Icon (if available), Style/Riwaya.
*   **Navigation**: Tapping a reciter leads to `Reciter Detail`.

### Screen 4: Reciter Detail
*   **Purpose**: Select specific content (Surah) for a chosen reciter.
*   **Functionalities**:
    *   **Moshaf Selection**: Toggle between different recitation styles (e.g., Hafs, Warsh) if the reciter offers multiple.
    *   **Surah Search**: Filter Surahs within this reciter's list.
    *   **Surah List**: List of available audio tracks for this reciter.
*   **User Actions**: Select Moshaf type, Search Surah, Tap Surah to Play.
*   **Data Displayed**: Reciter Name, Available Moshafs, List of Surahs.
*   **Navigation**: Tapping a Surah triggers the `Audio Player`.

### Screen 5: Audio Player (Overlay/Modal)
*   **Purpose**: Control audio playback.
*   **Functionalities**:
    *   **Playback Controls**: Play/Pause, Next Track, Previous Track.
    *   **Progress**: Seek bar (scrubber), Current Time, Total Duration.
    *   **Context**: Displays current Surah Name and Reciter Name.
    *   **Reciter Switcher**: Dropdown to change the reciter on the fly without leaving the screen.
    *   **Background Play**: (Mobile specific requirement) Audio continues when app is minimized.
*   **User Actions**: Scrub audio, toggle play/pause, skip tracks, change volume, minimize player.

### Screen 6: Settings (Floating/Modal)
*   **Purpose**: Global app preferences.
*   **Functionalities**:
    *   **Theme**: Toggle between Light and Dark mode.
    *   **Language**: Toggle between Arabic and English (RTL/LTR layout changes).
*   **User Actions**: Toggle switches.

---

## 2. Navigation Structure

*   **Main Navigation (Bottom Tab Bar)**:
    1.  **Home**: Dashboard.
    2.  **Reciters**: Directory of reciters.
    3.  **Prayer Times**: Schedule & Location.
    4.  **Settings**: Preferences (or placed in a top header/drawer).
*   **Secondary Navigation (Stack)**:
    *   *Reciters Tab* -> *Reciter Detail Screen*.
*   **Persistent Overlay**:
    *   **Audio Player**: Appears as a "Mini Player" bar at the bottom (above tabs) when audio is active. Tapping it expands to a full-screen modal.

---

## 3. Feature Categorization

| Category | Features |
| :--- | :--- |
| **Core Features** | Audio Streaming (Quran), Prayer Times Calculation, Reciter Browsing. |
| **Content Features** | 114 Surahs Database, Multi-Moshaf Support (Hafs, Warsh, etc.), Reciter Profiles. |
| **Interactive Features** | Search (Reciters & Surahs), Audio Scrubber, Next/Prev Track, Location-based updates. |
| **System Features** | Geolocation (GPS), Local Caching (Offline support), Theme Switching (Dark/Light), Localization (Ar/En). |
| **User Account** | *None currently implemented* (No login/signup required). |

---

## 4. Functional Details

### Audio Playback Flow
*   **Inputs**: User taps a Surah.
*   **State Changes**:
    *   Global `AudioContext` updates `currentSurah`, `currentReciter`, and `serverURL`.
    *   Player Overlay appears (status: `isPlaying = true`).
    *   Media Session API updates (lock screen controls).
*   **Dependencies**: Requires active internet connection (files are streamed from remote servers).

### Prayer Times Flow
*   **Inputs**: GPS Coordinates (Latitude/Longitude).
*   **Process**:
    1.  App requests Location Permission.
    2.  If granted: Fetches coordinates -> Calls Aladhan API -> Calls BigDataCloud API (Reverse Geocode).
    3.  If denied/error: Shows error state or falls back to default/cached location.
*   **Outputs**: Prayer times list, City Name, "Next Prayer" countdown.
*   **Refresh**: Auto-refreshes daily or on manual "Refresh" pull.

### Search Functionality
*   **Inputs**: Text string.
*   **Process**: Client-side filtering of the pre-loaded arrays (Reciters list or Surah list).
*   **Outputs**: Filtered list updating in real-time as user types.
