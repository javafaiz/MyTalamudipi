# MY Talamudipi — మీ తలముడిపి

Telugu Voter Information Search App for Android.

Search voters from a Telugu PDF by **Name**, **Voter ID (EPIC)**, or **House Number**.

---

## Build Options

| Method | Requirements | Time |
|---|---|---|
| **GitHub Actions (cloud)** | GitHub account + internet | ~5 min |
| Local (Android Studio) | Android Studio + Flutter SDK | setup ~1 hr |
| Local (cmdline tools) | Flutter SDK + Android cmdline-tools | setup ~30 min |

> **Recommended if Android Studio is not installed:** use the GitHub Actions method below — the APK is built in the cloud and downloaded as an artifact.

---

## Option A — Build via GitHub Actions (No Android Studio Required)

This uses GitHub's free CI/CD runners. You need a free GitHub account.

### A1 — Push the project to GitHub

1. Go to https://github.com/new and create a **new private repository** (e.g. `MyTalamudipi`).
2. Install Git: https://git-scm.com/download/win  
3. Open PowerShell in the project folder and run:

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/MyTalamudipi.git
git push -u origin main
```

> Replace `YOUR_USERNAME` with your GitHub username.

### A2 — Extract voter data first (required for the APK to have data)

Before pushing, run the PDF extractor locally to create `app/assets/voters.db`:

```powershell
pip install pdfminer.six
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
python scripts\extract_voters.py
```

Then push the generated database to GitHub:

```powershell
git add app/assets/voters.db
git commit -m "Add voters database"
git push
```

> **Note:** If `voters.db` is larger than 100 MB, use [Git LFS](https://git-lfs.github.com/) to track it.

### A3 — Download the built APK

1. Go to your GitHub repository page.
2. Click **Actions** tab → select the latest **"Build Flutter APK"** workflow run.
3. Scroll down to **Artifacts** → click **`my-talamudipi-release-apk`** to download.
4. Unzip the downloaded file — `app-release.apk` is inside.

> The workflow file is already included at `.github/workflows/build-apk.yml`.  
> If no `voters.db` is committed, the workflow creates an empty schema-only database so the APK still builds and installs correctly (just shows no results until data is loaded).

---

## Option B — Local Build (with Android Studio)

## Prerequisites

Install the following before proceeding:

| Tool | Download Link | Version |
|---|---|---|
| Python 3.10+ | https://www.python.org/downloads/ | 3.10 or newer |
| Android Studio | https://developer.android.com/studio | Hedgehog or newer |
| Flutter SDK | https://docs.flutter.dev/get-started/install/windows | 3.24 or newer |
| Git | https://git-scm.com/download/win | Any recent |

> **Note:** During Python install, tick **"Add Python to PATH"**.

---

## Step 1 — Install Python Dependencies

Open PowerShell and run:

```powershell
pip install pdfminer.six
```

---

## Step 2 — Preview PDF Extraction (Optional but Recommended)

Before extracting all data, verify the Telugu text is read correctly:

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
python scripts\extract_voters.py --preview
```

This prints the first 100 raw lines from the PDF.  
- If you see Telugu text (e.g. `రాజు`, `మహేష్`) — you are good to go.  
- If you see garbled text (e.g. `ÃÂ`) — run `python scripts\check_cmap.py` and share the output.

---

## Step 3 — Extract Voter Data to Database

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
python scripts\extract_voters.py
```

This reads the PDF and creates:

```
app\assets\voters.db
```

For a large PDF (2–5 lakh records) this may take **10–30 minutes**.  
You will see progress printed in the terminal.

---

## Step 4 — Install Flutter SDK

1. Download the Flutter ZIP from https://docs.flutter.dev/get-started/install/windows  
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your Windows **PATH**:
   - Search → **Edit the system environment variables** → Environment Variables  
   - Under *User variables* → select **Path** → Edit → New → `C:\flutter\bin` → OK
4. Open a **new** PowerShell and verify:
   ```powershell
   flutter --version
   ```

---

## Step 5 — Install Android Studio and Set Up SDK

1. Download and install Android Studio from https://developer.android.com/studio
2. On first launch, complete the **Setup Wizard** — it installs the Android SDK automatically.
3. In Android Studio, go to:  
   **File → Settings → Languages & Frameworks → Android SDK**  
   Make sure **Android 14 (API 34)** is installed.
4. Accept licenses by running in PowerShell:
   ```powershell
   flutter doctor --android-licenses
   ```
   Type `y` and press Enter for each prompt.

---

## Step 6 — Install Flutter Plugin in Android Studio

1. Open Android Studio
2. Go to **File → Settings → Plugins**
3. Search **Flutter** → Install → Restart Android Studio
4. The **Dart** plugin installs automatically with Flutter.

---

## Step 7 — Open the Project in Android Studio

1. Open Android Studio
2. Click **Open** (or File → Open)
3. Navigate to:
   ```
   C:\Users\MF40127873\Desktop\MyTalamudipi\app
   ```
4. Click **OK** / **Trust Project**
5. Android Studio will detect it as a Flutter project automatically.
6. Wait for **Gradle sync** to finish (bottom status bar).

---

## Step 8 — Download NotoSansTelugu Font

The app needs the Telugu font files. Run this in PowerShell:

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
New-Item -ItemType Directory -Force -Path app\assets\fonts

# Download from Google Fonts GitHub
Invoke-WebRequest `
  -Uri "https://github.com/google/fonts/raw/main/ofl/notosanstelugu/NotoSansTelugu%5Bwdth%2Cwght%5D.ttf" `
  -OutFile "app\assets\fonts\NotoSansTelugu-Regular.ttf" `
  -UseBasicParsing

Copy-Item "app\assets\fonts\NotoSansTelugu-Regular.ttf" `
          "app\assets\fonts\NotoSansTelugu-Bold.ttf"
```

If the download fails, download manually from:  
https://fonts.google.com/noto/specimen/Noto+Sans+Telugu  
→ Click **Download family** → extract and copy both `NotoSansTelugu-Regular.ttf` and `NotoSansTelugu-Bold.ttf` to `app\assets\fonts\`.

---

## Step 9 — Get Flutter Packages

In PowerShell:

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi\app"
flutter pub get
```

Or in Android Studio: open the **Terminal** tab at the bottom and run `flutter pub get`.

---

## Step 10 — Build the APK

### Option A — Build from PowerShell (Recommended)

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi\app"
flutter build apk --release
```

The APK will be at:
```
app\build\app\outputs\flutter-apk\app-release.apk
```

Copy it to a convenient location:
```powershell
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
          "C:\Users\MF40127873\Desktop\MyTalamudipi\MyTalamudipi.apk"
```

---

### Option B — Build from Android Studio

1. In Android Studio, go to **Build → Flutter → Build APK**  
   *(or Build → Build Bundle(s) / APK(s) → Build APK(s))*
2. Wait for the build to complete (3–5 minutes first time)
3. Click **locate** in the success notification, or find the APK at:
   ```
   app\build\app\outputs\flutter-apk\app-release.apk
   ```

---

## Step 11 — Install APK on Android Phone

1. Transfer `MyTalamudipi.apk` to your phone via USB, WhatsApp, or Google Drive.
2. On the phone, go to **Settings → Security** (or **Privacy**) → enable **Install unknown apps** for your file manager or browser.
3. Open the APK file on the phone → tap **Install**.
4. On first launch the app copies the database (takes a few seconds with a progress bar).

---

## Running on a Connected Phone (for testing)

1. On your Android phone, enable **Developer Options**:  
   Settings → About Phone → tap **Build Number** 7 times.
2. Go to Developer Options → enable **USB Debugging**.
3. Connect phone via USB cable.
4. In PowerShell:
   ```powershell
   flutter devices
   ```
   Your phone should appear in the list.
5. Run the app directly on the phone:
   ```powershell
   cd "C:\Users\MF40127873\Desktop\MyTalamudipi\app"
   flutter run
   ```

---

## Running in an Android Emulator (Android Studio)

1. In Android Studio, go to **Device Manager** (right toolbar or Tools → Device Manager)
2. Click **Create Device** → choose **Pixel 6** → Next
3. Select a system image (e.g. **API 34, Android 14**) → Download if needed → Next → Finish
4. Click the **Play** button next to the emulator to start it
5. In Android Studio, select the emulator from the device dropdown and click **Run ▶**

---

## Verifying Everything Works

Run Flutter's diagnostic tool:

```powershell
flutter doctor
```

All items should show ✅. Common fixes:

| Issue | Fix |
|---|---|
| `Android toolchain — no licenses` | Run `flutter doctor --android-licenses` |
| `Android Studio not found` | Set `ANDROID_HOME` env variable |
| `cmdline-tools component missing` | Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools → Install |
| `Visual Studio not installed` | Only needed for Windows desktop — ignore for Android builds |

---

## Project File Structure

```
MyTalamudipi/
├── README.md                          ← This file
├── setup.ps1                          ← Automated setup script
├── scripts/
│   ├── extract_voters.py              ← PDF → SQLite extractor  ← RUN FIRST
│   ├── check_cmap.py                  ← Debug Telugu encoding
│   ├── check_pdfminer.py              ← Debug character codes
│   └── check_pdfminer2.py             ← Debug raw text output
└── app/                               ← Flutter Android project
    ├── pubspec.yaml                   ← Dependencies
    ├── assets/
    │   ├── voters.db                  ← Generated by extract_voters.py
    │   └── fonts/
    │       ├── NotoSansTelugu-Regular.ttf
    │       └── NotoSansTelugu-Bold.ttf
    └── lib/
        ├── main.dart                  ← App entry point
        ├── models/voter.dart          ← Voter data model
        ├── database/db_helper.dart    ← SQLite queries
        ├── screens/
        │   ├── home_screen.dart       ← Main menu
        │   ├── search_screen.dart     ← Search UI (name/ID/house)
        │   └── detail_screen.dart     ← Full voter record view
        └── widgets/
            └── voter_card.dart        ← List item card
```

---

## App Features

| Search | Input | Result |
|---|---|---|
| **పేరు (Name)** | Telugu or English name | All voters with matching name |
| **ఓటర్ ఐడి (Voter ID)** | EPIC number e.g. `TNN1234567` | Single unique voter record |
| **ఇంటి నంబరు (House No)** | House number | Entire family at that house |

- Bilingual interface — Telugu + English on every screen
- Works fully **offline** — no internet required after install
- Handles **2–5 lakh records** efficiently
- First-launch progress bar while database loads

---

## Troubleshooting

**App shows blank / no results**  
→ The `voters.db` file may be missing from `app\assets\`. Run `extract_voters.py` first.

**Telugu text shows as boxes or question marks**  
→ The font files are missing. Repeat Step 8.

**Build fails: "Gradle sync failed"**  
→ Check internet connection. In Android Studio: File → Sync Project with Gradle Files.

**`flutter` command not found**  
→ Add `C:\flutter\bin` to PATH and reopen PowerShell.

**PDF extraction gives 0 records**  
→ Run `python scripts\extract_voters.py --preview` and share the output to diagnose.
