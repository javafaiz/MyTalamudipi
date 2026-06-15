# Talamudipi SIR Information — తలముడిపి ఓటర్ల జాబితా

Android app to search the **2002 Special Intensive Revision (SIR)** voter list for Talamudipi village.

Search by **Name** (Telugu or English), **Serial No.**, **Voter ID (EPIC)**, or **House Number**.

---

## How it works

```
Electoral Roll PDFs  →  extract_voters.py  →  voters.db  →  GitHub Actions  →  APK
```

1. Download the PDF electoral rolls from the government website.
2. Run `extract_voters.py` locally — it reads the Telugu PDFs and writes a SQLite database (`voters.db`).
3. Push the project (including `voters.db`) to GitHub.
4. GitHub Actions automatically builds the Android APK in the cloud (~5 min).
5. Download the APK from the Actions tab and install on your phone.

No Android Studio required. No local Flutter setup required.

---

## Step 1 — Download the Electoral Roll PDFs

The voter PDFs are published by the Election Commission of India.

1. Go to: **https://ceoandhra.nic.in** (Andhra Pradesh) or **https://cetelangana.nic.in** (Telangana)
2. Navigate to: **Electoral Rolls → Final Rolls → Select District → Select Constituency → Select Part**
3. Download the PDF for each Part that covers Talamudipi village.
   - File names follow the pattern: `S01_185_140.pdf`, `S01_185_141.pdf` etc.
   - Parts 140–143 cover Talamudipi (Nandikotkur constituency, Kurnool district).
4. Save all PDFs to a folder, e.g. `C:\Downloads\voter_pdfs\`

> The PDFs use the **Gautami** Telugu font with Identity-H encoding. The extractor handles this
> automatically using GSUB font table decoding — no manual conversion needed.

---

## Step 2 — Install Python Dependencies

The extractor needs **PyMuPDF** and **fontTools**.

```powershell
pip install pymupdf fonttools
```

---

## Step 3 — Preview the PDF (optional sanity check)

Before extracting all records, check that Telugu text is decoded correctly:

```powershell
cd "C:\Users\MF40127873\Desktop\MyTalamudipi"
python scripts\extract_voters.py --pdf C:\Downloads\voter_pdfs\S01_185_140.pdf --preview
```

You should see Telugu names like `రెడ్డి`, `హుస్సేన్`, `కృష్ణ` in the output.

---

## Step 4 — Extract All PDFs to Database

### Single PDF:
```powershell
python scripts\extract_voters.py --pdf C:\Downloads\voter_pdfs\S01_185_140.pdf
```

### Entire folder (recommended — processes all parts at once):
```powershell
python scripts\extract_voters.py --pdf-dir C:\Downloads\voter_pdfs\
```

Expected output:
```
DB   : ...\app\assets\voters.db
PDFs : 4 file(s)

[1/4] S01_185_140.pdf
  -> 696 records  (Part 140)
[2/4] S01_185_141.pdf
  -> 633 records  (Part 141)
[3/4] S01_185_142.pdf
  -> 606 records  (Part 142)
[4/4] S01_185_143.pdf
  -> 558 records  (Part 143)

Total records in DB : 2,493
```

The database is saved to `app\assets\voters.db` automatically.

### Extractor flags:

| Flag | Description | Example |
|---|---|---|
| `--pdf` | Single PDF file | `--pdf S01_185_140.pdf` |
| `--pdf-dir` | Folder of PDFs | `--pdf-dir C:\Downloads\voter_pdfs\` |
| `--db` | Custom output path | `--db C:\my_data\voters.db` |
| `--preview` | Print decoded lines without saving | `--preview` |
| `--pages N` | Limit to first N pages (for testing) | `--pages 5` |

---

## Step 5 — Build the APK via GitHub Actions

> The APK is built in GitHub's cloud — no Android Studio, no Flutter SDK needed locally.

### 5a — Create a GitHub repository

1. Go to **https://github.com/new**
2. Create a **private** repository named `MyTalamudipi`
3. Do **not** initialize with README

### 5b — Push the project to GitHub

Open PowerShell in the project folder:

```powershell
$git = "C:\Users\MF40127873\AppData\Local\Programs\Git\cmd\git.exe"
Set-Location "C:\Users\MF40127873\Desktop\MyTalamudipi"

& $git init
& $git add .
& $git commit -m "Initial commit"
& $git branch -M main
& $git remote add origin https://github.com/YOUR_USERNAME/MyTalamudipi.git
& $git push -u origin main
```

> Replace `YOUR_USERNAME` with your GitHub username.

### 5c — Push updates (after re-extracting PDFs or changing code)

```powershell
$git = "C:\Users\MF40127873\AppData\Local\Programs\Git\cmd\git.exe"
Set-Location "C:\Users\MF40127873\Desktop\MyTalamudipi"
& $git add .
& $git commit -m "Update voters.db"
& $git push origin main
```

Every push to `main` automatically triggers a new APK build.

### 5d — Download the APK

1. Go to your GitHub repository page
2. Click **Actions** tab
3. Click the latest **"Build Flutter APK"** run (green ✅)
4. Scroll to **Artifacts** → click **`my-talamudipi-release-apk`** to download
5. Unzip → `app-release.apk` is inside

---

## Step 6 — Install APK on Android Phone

1. Transfer `app-release.apk` to your phone (USB, WhatsApp, Google Drive, etc.)
2. On the phone: **Settings → Security → Install unknown apps** → allow your file manager
3. Open the APK → tap **Install**
4. On first launch a progress bar appears while the database loads (a few seconds)

---

## App Features

| Search type | What you type | What it finds |
|---|---|---|
| **పేరు — Name** | `reddy` or `రెడ్డి` | All voters whose name matches |
| **సీరియల్ నంబరు — Serial No.** | `42` | Voter at that position in the printed list |
| **ఓటర్ ఐడి — Voter ID (EPIC)** | `AP271850405225` | Single voter by EPIC number |
| **ఇంటి నంబరు — House No.** | `1-5` | All family members at that house |

- **English name search** works phonetically — `krishna`, `hussain`, `raju` all find the correct Telugu names
- Fully **offline** after install — no internet required
- Bilingual interface (Telugu + English on every screen)

---

## Project Structure

```
MyTalamudipi/
├── README.md                            ← This file
├── .github/workflows/build-apk.yml     ← GitHub Actions CI — builds the APK
├── scripts/
│   └── extract_voters.py               ← PDF → SQLite extractor (run this locally)
└── app/                                ← Flutter Android project
    ├── pubspec.yaml
    ├── assets/
    │   ├── voters.db                   ← Generated by extract_voters.py
    │   ├── icon/app_icon.png           ← App launcher icon
    │   └── fonts/
    │       ├── NotoSansTelugu-Regular.ttf
    │       └── NotoSansTelugu-Bold.ttf
    └── lib/
        ├── main.dart                   ← Splash / loading screen
        ├── models/voter.dart           ← Voter data model
        ├── database/db_helper.dart     ← SQLite search queries
        ├── utils/transliterate.dart    ← English → phonetic search normalization
        └── screens/
            ├── home_screen.dart        ← Main menu
            ├── search_screen.dart      ← Search UI
            └── detail_screen.dart      ← Full voter record view
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| **0 records extracted** | Run with `--preview` to check decoded lines. Make sure the PDF is an AP electoral roll with Gautami font. |
| **Telugu shows as boxes in terminal** | Terminal may not render Telugu. The DB is still correct — install the APK to verify. |
| **GitHub Actions build fails** | Click the failed run → expand the failed step → read the error log. |
| **APK installs but shows no results** | `voters.db` was not committed. Re-run extractor, then `git add app/assets/voters.db` and push. |
| **App shows "Loading database…" forever** | `voters.db` may be corrupt. Delete it, re-run the extractor, and push again. |
