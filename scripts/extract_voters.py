"""
Extract voter data from Telugu electoral roll PDFs (AP / Telangana).
Uses PyMuPDF (fitz) instead of pdfminer -- handles custom font encodings better.

Each voter record in the PDF is laid out as 8 consecutive text lines per page:
    Line 1 : serial_no       (integer)
    Line 2 : house_number    (e.g. 1-1, 1-2A)
    Line 3 : voter_name      (Telugu -- may appear garbled due to font encoding)
    Line 4 : relationship_type
    Line 5 : relationship_name
    Line 6 : gender
    Line 7 : age             (integer)
    Line 8 : voter_id        (EPIC -- e.g. AP271850405225)

Usage:
    # Single PDF
    python extract_voters.py --pdf path/to/file.pdf

    # Folder of PDFs (e.g. 100 parts of Nandikotkur)
    python extract_voters.py --pdf-dir path/to/pdfs_folder/

    # Preview raw lines (check encoding / structure)
    python extract_voters.py --pdf path/to/file.pdf --preview
"""

import re
import sys
import sqlite3
import argparse
from pathlib import Path

try:
    import fitz  # PyMuPDF
except ImportError:
    print("ERROR: PyMuPDF not installed. Run:  pip install pymupdf")
    sys.exit(1)

# -- Config -------------------------------------------------------------------
PDF_PATH = r'C:\Users\MF40127873\Downloads\S01_185_140.pdf'
DB_PATH  = str(Path(__file__).parent.parent / 'app' / 'assets' / 'voters.db')

# AP / Telangana EPIC IDs: 2-3 letters + 6-14 digits
VOTER_ID_RE  = re.compile(r'^[A-Z]{2,3}\d{6,14}$')

# House number: digit(s) then hyphen then digits/letters  e.g. 1-1, 12-3A
HOUSE_NO_RE  = re.compile(r'^\d+[-/]\d*[A-Za-z]?\d*$')


# -- Part name from filename --------------------------------------------------

def _part_name_from_file(pdf_path: str) -> str:
    """'S01_185_001.pdf'  ->  'Part 1'"""
    stem  = Path(pdf_path).stem
    parts = stem.replace('-', '_').split('_')
    last  = parts[-1]
    if last.isdigit():
        return f"Part {int(last)}"
    return stem


# -- Database -----------------------------------------------------------------

def create_db(db_path: str) -> sqlite3.Connection:
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.executescript('''
        CREATE TABLE IF NOT EXISTS voters (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            serial_no         TEXT,
            house_number      TEXT,
            voter_name        TEXT,
            relationship_type TEXT,
            relationship_name TEXT,
            age               INTEGER,
            voter_id          TEXT,
            gender            TEXT,
            part_name         TEXT DEFAULT ""
        );
        CREATE INDEX IF NOT EXISTS idx_voter_id     ON voters(voter_id);
        CREATE INDEX IF NOT EXISTS idx_house_number ON voters(house_number);
        CREATE INDEX IF NOT EXISTS idx_voter_name   ON voters(voter_name);
        CREATE INDEX IF NOT EXISTS idx_part_name    ON voters(part_name);
    ''')
    conn.commit()
    return conn


def _insert_batch(conn: sqlite3.Connection, records: list):
    cur = conn.cursor()
    cur.execute('BEGIN')
    for r in records:
        cur.execute('''
            INSERT INTO voters
                (serial_no, house_number, voter_name, relationship_type,
                 relationship_name, age, voter_id, gender, part_name)
            VALUES (?,?,?,?,?,?,?,?,?)
        ''', (
            r.get('serial_no', ''),
            r.get('house_number', ''),
            r.get('voter_name', ''),
            r.get('relationship_type', ''),
            r.get('relationship_name', ''),
            r.get('age', 0),
            r.get('voter_id', ''),
            r.get('gender', ''),
            r.get('part_name', ''),
        ))
    conn.commit()


# -- PDF extraction -----------------------------------------------------------

def _clean_lines(raw_text: str) -> list:
    return [ln.strip() for ln in raw_text.splitlines() if ln.strip()]


def _is_serial(token: str) -> bool:
    return token.isdigit()


def _is_age(token: str) -> bool:
    return token.isdigit() and 1 <= int(token) <= 120


def _is_voter_id(token: str) -> bool:
    return bool(VOTER_ID_RE.match(token.upper()))


def _is_house_no(token: str) -> bool:
    return bool(HOUSE_NO_RE.match(token))


def extract_from_pdf(pdf_path: str, part_name: str = '',
                     preview: bool = False, max_pages: int = 0) -> list:
    """
    Extract voter records from a single PDF.

    Strategy
    --------
    Each page text is split into lines. We scan for an 8-line window where:
        window[0]  = serial_no     (digits only)
        window[1]  = house_number  (matches HOUSE_NO_RE)
        window[2]  = voter_name
        window[3]  = relationship_type
        window[4]  = relationship_name
        window[5]  = gender
        window[6]  = age           (1-120 digits)
        window[7]  = voter_id      (matches VOTER_ID_RE)
    On match, record it and advance 8 lines; otherwise shift by 1.
    """
    doc = fitz.open(pdf_path)
    total_pages = min(len(doc), max_pages) if max_pages else len(doc)

    all_lines = []
    for page_num in range(total_pages):
        page = doc[page_num]
        all_lines.extend(_clean_lines(page.get_text("text")))
    doc.close()

    if preview:
        print(f"\n-- RAW LINES from {Path(pdf_path).name} (first 120) --")
        enc = sys.stdout.encoding or 'utf-8'
        for idx, ln in enumerate(all_lines[:120]):
            safe = ln.encode(enc, errors='replace').decode(enc, errors='replace')
            print(f"  [{idx:4d}]  {safe}")
        return []

    records = []
    i = 0
    while i <= len(all_lines) - 8:
        w = all_lines[i: i + 8]
        if (_is_serial(w[0]) and _is_house_no(w[1])
                and _is_age(w[6]) and _is_voter_id(w[7])):
            records.append({
                'serial_no':         w[0],
                'house_number':      w[1],
                'voter_name':        w[2],
                'relationship_type': w[3],
                'relationship_name': w[4],
                'gender':            w[5],
                'age':               int(w[6]),
                'voter_id':          w[7].upper(),
                'part_name':         part_name,
            })
            i += 8
        else:
            i += 1

    return records


# -- Process one PDF ----------------------------------------------------------

def _process_one(pdf_path: str, conn: sqlite3.Connection,
                 part_name: str = '', preview: bool = False,
                 max_pages: int = 0) -> int:
    records = extract_from_pdf(pdf_path, part_name=part_name,
                               preview=preview, max_pages=max_pages)
    if preview:
        return 0
    if not records:
        print(f"  [WARN] No records found in {Path(pdf_path).name}")
        return 0
    _insert_batch(conn, records)
    print(f"  -> {len(records):,} records  ({part_name or Path(pdf_path).name})")
    return len(records)


# -- Entry point --------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Extract voter data from AP/Telangana electoral roll PDFs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            'Examples:\n'
            '  python extract_voters.py --pdf S01_185_140.pdf\n'
            '  python extract_voters.py --pdf-dir C:/PDFs/Nandikotkur/\n'
            '  python extract_voters.py --pdf S01_185_140.pdf --preview\n'
        ),
    )
    parser.add_argument('--pdf',     default='',      help='Path to a single PDF')
    parser.add_argument('--pdf-dir', default='',      dest='pdf_dir',
                        help='Folder containing multiple PDFs')
    parser.add_argument('--db',      default=DB_PATH, help='Output SQLite path')
    parser.add_argument('--preview', action='store_true',
                        help='Print raw lines without saving')
    parser.add_argument('--pages',   type=int, default=0,
                        help='Max pages per PDF (0 = all)')
    args = parser.parse_args()

    if args.pdf_dir:
        folder = Path(args.pdf_dir)
        if not folder.is_dir():
            print(f"ERROR: '{args.pdf_dir}' is not a directory."); sys.exit(1)
        pdf_files = sorted(folder.glob('*.pdf')) or sorted(folder.glob('*.PDF'))
        if not pdf_files:
            print(f"ERROR: No PDFs in '{args.pdf_dir}'"); sys.exit(1)
    elif args.pdf:
        pdf_files = [Path(args.pdf)]
    else:
        pdf_files = [Path(PDF_PATH)]

    print(f"DB   : {args.db}")
    print(f"PDFs : {len(pdf_files)} file(s)\n")

    if args.preview:
        extract_from_pdf(str(pdf_files[0]), preview=True, max_pages=args.pages)
        return

    conn  = create_db(args.db)
    total = 0
    failed = []

    for idx, pdf_path in enumerate(pdf_files, 1):
        part = _part_name_from_file(str(pdf_path))
        print(f"[{idx}/{len(pdf_files)}] {pdf_path.name}")
        try:
            total += _process_one(str(pdf_path), conn,
                                  part_name=part, max_pages=args.pages)
        except Exception as exc:
            print(f"  [ERROR] {pdf_path.name}: {exc}")
            failed.append(pdf_path.name)

    in_db = conn.execute('SELECT COUNT(*) FROM voters').fetchone()[0]
    conn.close()

    print(f"\n{'='*56}")
    print(f"Records inserted this run : {total:,}")
    print(f"Total records in DB       : {in_db:,}")
    print(f"Database                  : {args.db}")
    if failed:
        print(f"\n[WARN] {len(failed)} file(s) failed:")
        for f in failed: print(f"  * {f}")
    print("\nNext: push app/assets/voters.db to GitHub to rebuild the APK.")


if __name__ == '__main__':
    main()