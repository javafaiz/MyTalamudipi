"""
Extract voter data from Telugu PDF(s) and store in SQLite database.
MY Talamudipi – PDF Extraction Pipeline

Fields extracted:
    serial_no, house_number, voter_name, relationship_type,
    relationship_name, age, voter_id, gender, part_name

Usage:
    # Single PDF (original behaviour)
    python extract_voters.py --pdf path/to/file.pdf

    # Folder of 100 PDFs  <- NEW: for multi-part villages like Nandikotkur
    python extract_voters.py --pdf-dir path/to/pdfs_folder/

    # Preview raw text from one PDF (troubleshoot Telugu encoding)
    python extract_voters.py --pdf path\to\file.pdf --preview
"""

import re
import sys
import sqlite3
import argparse
from pathlib import Path

from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextBox, LTTextLine

# ── Config ──────────────────────────────────────────────────────────────────
PDF_PATH = r'C:\Users\MF40127873\Downloads\S01_185_140.pdf'
DB_PATH  = str(Path(__file__).parent.parent / 'app' / 'assets' / 'voters.db')

# ── Part name helper ─────────────────────────────────────────────────────────

def _part_name_from_file(pdf_path: str) -> str:
    """Derive a human-readable part label from the PDF filename.
    e.g. 'S01_185_001.pdf' → 'Part 1'
         'nandikotkur_ward5_part023.pdf' → 'Part 23'
    Falls back to the bare filename stem if no trailing number is found.
    """
    stem = Path(pdf_path).stem          # e.g. 'S01_185_001'
    parts = stem.replace('-', '_').split('_')
    last = parts[-1]
    if last.isdigit():
        return f"Part {int(last)}"      # strip leading zeros
    return stem                         # fallback: use full filename

# Voter EPIC ID patterns used in AP / Telangana
VOTER_ID_RE = re.compile(r'\b[A-Z]{2,3}\d{6,10}\b')

# Telugu relationship keywords → normalised label
REL_MAP = {
    'తండ్రి': 'Father',  'తల్లి': 'Mother',
    'భర్త':   'Husband', 'భార్య': 'Wife',
    'సోదరుడు': 'Brother','సోదరి': 'Sister',
    'కుమారుడు': 'Son',   'కుమార్తె': 'Daughter',
    'తాత':   'Grandfather','నాన':  'Father',   # alternate spellings
    'father': 'Father',  'mother': 'Mother',
    'husband': 'Husband','wife': 'Wife',
    'son': 'Son',        'daughter': 'Daughter',
}

# Telugu gender keywords
GENDER_MAP = {
    'పురుష': 'Male',   'స్త్రీ': 'Female',  'ఇతర': 'Other',
    'male': 'Male',    'female': 'Female',   'm': 'Male', 'f': 'Female',
    'పు':   'Male',    'స్త్': 'Female',
}

# Header / label keywords to skip when collecting name tokens
SKIP_KEYWORDS = {
    'క్రమ', 'సంఖ్య', 'గృహ', 'ఓటరు', 'పేరు', 'సంబంధం',
    'వయస్సు', 'లింగం', 'ఓటర్', 'ఐడి', 'నంబరు', 'కార్డు',
    'serial', 'house', 'voter', 'name', 'relation', 'age',
    'gender', 'photo', 'sl.no', 'sl', 'no', 'epic',
    'part', 'ward', 'section', 'polling', 'station',
}

# ── Database ─────────────────────────────────────────────────────────────────

def create_db(db_path: str) -> sqlite3.Connection:
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript('''
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
            part_name         TEXT DEFAULT ''
        );
        CREATE INDEX IF NOT EXISTS idx_voter_id     ON voters(voter_id);
        CREATE INDEX IF NOT EXISTS idx_house_number ON voters(house_number);
        CREATE INDEX IF NOT EXISTS idx_voter_name   ON voters(voter_name);
        CREATE INDEX IF NOT EXISTS idx_part_name    ON voters(part_name);
    ''')
    conn.commit()
    return conn


def insert_record(cur: sqlite3.Cursor, r: dict):
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


# ── Text extraction ──────────────────────────────────────────────────────────

def extract_lines(pdf_path: str) -> list[tuple[int, float, float, str]]:
    """
    Returns list of (page_num, x0, y0, text) sorted page-by-page,
    top-to-bottom, left-to-right within each page.
    """
    results: list[tuple[int, float, float, str]] = []
    for page_num, page_layout in enumerate(extract_pages(pdf_path)):
        page_h = page_layout.height
        for element in page_layout:
            if isinstance(element, LTTextBox):
                for line in element:
                    if isinstance(line, LTTextLine):
                        text = line.get_text().strip()
                        if text:
                            # Invert y so 0 = top of page
                            results.append((page_num, line.x0, page_h - line.y1, text))
    results.sort(key=lambda r: (r[0], round(r[2], 1), r[1]))
    return results


# ── Parsing helpers ──────────────────────────────────────────────────────────

def _normalise(text: str) -> str:
    return text.strip().lower()


def _detect_relationship(text: str) -> str:
    low = _normalise(text)
    for key, val in REL_MAP.items():
        if key.lower() in low:
            return val
    return ''


def _detect_gender(text: str) -> str:
    low = _normalise(text)
    for key, val in GENDER_MAP.items():
        if key.lower() in low:
            return val
    return ''


def _is_number(token: str) -> bool:
    return token.replace('-', '').replace('/', '').isdigit()


def _label_value(line: str) -> tuple[str, str]:
    """Split 'label : value' or 'label value' into (label, value)."""
    for sep in (':', '-', '–'):
        if sep in line:
            parts = line.split(sep, 1)
            return parts[0].strip(), parts[1].strip()
    return '', line.strip()


# ── Main parser ───────────────────────────────────────────────────────────────

def parse_records(lines: list[tuple[int, float, float, str]]) -> list[dict]:
    """
    Strategy:
    1.  Scan all lines for EPIC / voter-ID tokens.
    2.  For each EPIC token, collect the surrounding ~10 lines as a 'block'.
    3.  Within that block extract fields using keyword matching.
    """
    # Index lines that contain a voter ID
    id_positions: list[int] = []
    for i, (_, _, _, text) in enumerate(lines):
        if VOTER_ID_RE.search(text.upper()):
            id_positions.append(i)

    if not id_positions:
        print("[WARN] No voter IDs found. Check raw output with --preview.")
        return []

    records = []
    WINDOW = 12  # lines before and after the EPIC line to inspect

    for pos in id_positions:
        block = lines[max(0, pos - WINDOW): pos + WINDOW + 1]
        block_text = [(t[3]) for t in block]

        r: dict = {
            'serial_no': '', 'house_number': '', 'voter_name': '',
            'relationship_type': '', 'relationship_name': '',
            'age': 0, 'voter_id': '', 'gender': '',
        }

        # Extract voter_id first
        for text in block_text:
            m = VOTER_ID_RE.search(text.upper())
            if m:
                r['voter_id'] = m.group()
                break

        for text in block_text:
            label, value = _label_value(text)
            low_label = _normalise(label or text)
            low_full  = _normalise(text)

            # Serial number
            if not r['serial_no'] and any(k in low_label for k in ('క్రమ', 'serial', 'sl')):
                if _is_number(value):
                    r['serial_no'] = value

            # House number
            if not r['house_number'] and any(k in low_label for k in ('గృహ', 'house', 'door', 'flat')):
                r['house_number'] = value or text.split()[-1]

            # Voter name (label form)
            if not r['voter_name'] and any(k in low_label for k in ('ఓటరు పేరు', 'ఓటరు', 'voter name', 'voter')):
                candidate = value.strip()
                if candidate and not VOTER_ID_RE.search(candidate.upper()):
                    r['voter_name'] = candidate

            # Age
            if not r['age']:
                if any(k in low_label for k in ('వయస్సు', 'age')):
                    try:
                        r['age'] = int(value.strip())
                    except ValueError:
                        pass
                else:
                    # bare number between 1-120 that isn't serial/house
                    tokens = text.split()
                    if len(tokens) == 1 and _is_number(tokens[0]):
                        n = int(tokens[0])
                        if 1 <= n <= 120 and not r['age']:
                            r['age'] = n

            # Relationship type
            rel = _detect_relationship(text)
            if rel and not r['relationship_type']:
                r['relationship_type'] = rel
                # The relationship name is often on the same line after the keyword
                for kw in REL_MAP:
                    if kw.lower() in low_full:
                        remaining = text[text.lower().find(kw.lower()) + len(kw):].strip(' :–-')
                        if remaining:
                            r['relationship_name'] = remaining
                        break

            # Gender
            gnd = _detect_gender(text)
            if gnd and not r['gender']:
                r['gender'] = gnd

        # Fallback: if voter_name still empty, pick first non-numeric, non-ID,
        # non-label Telugu line in the block
        if not r['voter_name']:
            for text in block_text:
                low = _normalise(text)
                if (VOTER_ID_RE.search(text.upper())
                        or _is_number(text.replace(' ', ''))
                        or any(k in low for k in SKIP_KEYWORDS)):
                    continue
                # Prefer lines with Telugu Unicode (U+0C00–U+0C7F)
                if any('\u0C00' <= ch <= '\u0C7F' for ch in text):
                    r['voter_name'] = text.strip()
                    break

        if r['voter_id']:
            records.append(r)

    return records


# ── Entry point ───────────────────────────────────────────────────────────────

def _process_one_pdf(
    pdf_path: str,
    cur: sqlite3.Cursor,
    pages: int = 0,
    preview: bool = False,
    part_name: str = '',
) -> int:
    """Extract records from a single PDF and insert them into the open cursor.
    Returns the number of records inserted."""
    print(f"  Processing: {Path(pdf_path).name}  (part: {part_name or '—'})")
    raw_lines = extract_lines(pdf_path)

    if preview:
        print(f"\n── RAW LINES from {Path(pdf_path).name} (first 100) ──")
        for i, (pg, x, y, text) in enumerate(raw_lines[:100]):
            print(f"[pg{pg+1} y={y:6.1f} x={x:6.1f}]  {repr(text)}")
        print("\nRun without --preview to extract and save records.")
        return 0

    if pages:
        raw_lines = [l for l in raw_lines if l[0] < pages]

    records = parse_records(raw_lines)

    if not records:
        print(f"  [WARN] No records found in {Path(pdf_path).name}. Skipping.")
        return 0

    # Stamp every record with the part name
    for r in records:
        r['part_name'] = part_name

    BATCH = 5000
    cur.execute('BEGIN')
    for i, r in enumerate(records):
        insert_record(cur, r)
        if (i + 1) % BATCH == 0:
            cur.connection.commit()
            cur.execute('BEGIN')
    cur.connection.commit()

    print(f"  → {len(records):,} records  ({part_name})")
    return len(records)


def main():
    parser = argparse.ArgumentParser(
        description='Extract Telugu voter data from one PDF or a folder of PDFs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            'Examples:\n'
            '  Single PDF:\n'
            '    python extract_voters.py --pdf S01_185_001.pdf\n'
            '\n'
            '  Folder of 100 PDFs (e.g. Nandikotkur):\n'
            '    python extract_voters.py --pdf-dir C:\\PDFs\\Nandikotkur\\\n'
            '\n'
            '  Preview raw text (Telugu encoding check):\n'
            '    python extract_voters.py --pdf S01_185_001.pdf --preview\n'
        ),
    )
    parser.add_argument('--pdf',     default='',      help='Path to a single PDF file')
    parser.add_argument('--pdf-dir', default='',      dest='pdf_dir',
                        help='Path to a FOLDER containing multiple PDF files')
    parser.add_argument('--db',      default=DB_PATH, help='Output SQLite path')
    parser.add_argument('--preview', action='store_true',
                        help='Print raw lines without saving to DB (works with --pdf only)')
    parser.add_argument('--pages',   type=int, default=0,
                        help='Number of pages to process per PDF (0 = all)')
    args = parser.parse_args()

    # ── Resolve the list of PDFs to process ─────────────────────────────────
    if args.pdf_dir:
        pdf_folder = Path(args.pdf_dir)
        if not pdf_folder.is_dir():
            print(f"ERROR: --pdf-dir '{args.pdf_dir}' is not a valid directory.")
            sys.exit(1)
        pdf_files = sorted(pdf_folder.glob('*.pdf'))
        if not pdf_files:
            pdf_files = sorted(pdf_folder.glob('*.PDF'))
        if not pdf_files:
            print(f"ERROR: No .pdf files found in '{args.pdf_dir}'")
            sys.exit(1)
        print(f"Found {len(pdf_files)} PDF(s) in: {pdf_folder}")
    elif args.pdf:
        pdf_files = [Path(args.pdf)]
    else:
        # Default single-file fallback for backward compatibility
        pdf_files = [Path(PDF_PATH)]

    print(f"DB   : {args.db}")
    print(f"PDFs : {len(pdf_files)} file(s)")
    print()

    if args.preview:
        # Preview mode: only process the first file
        _process_one_pdf(
            str(pdf_files[0]),
            cur=None,           # type: ignore  – not used in preview mode
            pages=args.pages,
            preview=True,
            part_name=_part_name_from_file(str(pdf_files[0])),
        )
        return

    conn = create_db(args.db)
    cur  = conn.cursor()

    grand_total = 0
    failed = []

    for idx, pdf_path in enumerate(pdf_files, start=1):
        part = _part_name_from_file(str(pdf_path))
        print(f"[{idx}/{len(pdf_files)}] {pdf_path.name}")
        try:
            count = _process_one_pdf(
                str(pdf_path),
                cur=cur,
                pages=args.pages,
                preview=False,
                part_name=part,
            )
            grand_total += count
        except Exception as exc:
            print(f"  [ERROR] {pdf_path.name}: {exc}")
            failed.append(pdf_path.name)

    total_in_db = conn.execute('SELECT COUNT(*) FROM voters').fetchone()[0]
    conn.close()

    print()
    print('═' * 60)
    print(f"Total records inserted this run : {grand_total:,}")
    print(f"Total records in DB             : {total_in_db:,}")
    print(f"Database saved to               : {args.db}")
    if failed:
        print(f"\n[WARN] {len(failed)} PDF(s) failed:")
        for f in failed:
            print(f"  • {f}")
    print()
    print("Next step:")
    print("  Push the updated voters.db to GitHub and let the workflow build the APK.")
    print("  Or run 'flutter build apk --release' locally if Flutter is installed.")


if __name__ == '__main__':
    main()
