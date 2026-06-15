"""
Extract voter data from Telugu electoral roll PDFs (AP / Telangana).
Uses PyMuPDF (fitz) with font-aware GSUB decoding to recover proper Telugu text.

Each voter record in the PDF is laid out as 8 consecutive text lines per page:
    Line 1 : serial_no       (integer, Helvetica font)
    Line 2 : house_number    (e.g. 1-1, 1-2A, Helvetica font)
    Line 3 : voter_name      (Telugu text, Gautami font)
    Line 4 : relationship_type (Telugu, Gautami font)
    Line 5 : relationship_name (Telugu, Gautami font)
    Line 6 : gender          (Telugu, Gautami font)
    Line 7 : age             (integer, Helvetica font)
    Line 8 : voter_id        (EPIC e.g. AP271850405225, Helvetica font)

Decoding strategy:
  - Helvetica / Times-Roman spans → standard ASCII (no conversion needed)
  - Gautami (Telugu) spans → glyph_id → Telugu Unicode via GSUB reverse lookup

Usage:
    # Single PDF
    python extract_voters.py --pdf path/to/file.pdf

    # Folder of PDFs
    python extract_voters.py --pdf-dir path/to/pdfs_folder/

    # Preview raw lines (check encoding / structure)
    python extract_voters.py --pdf path/to/file.pdf --preview
"""

import re
import sys
import sqlite3
import argparse
import io
from pathlib import Path

try:
    import fitz  # PyMuPDF
except ImportError:
    print("ERROR: PyMuPDF not installed. Run:  pip install pymupdf")
    sys.exit(1)

try:
    from fontTools.ttLib import TTFont
    _FONTTOOLS_OK = True
except ImportError:
    _FONTTOOLS_OK = False

# -- Config -------------------------------------------------------------------
PDF_PATH = r'C:\Users\MF40127873\Downloads\S01_185_140.pdf'
DB_PATH  = str(Path(__file__).parent.parent / 'app' / 'assets' / 'voters.db')

# AP / Telangana EPIC IDs: 2-3 letters + 6-14 digits
VOTER_ID_RE  = re.compile(r'^[A-Z]{2,3}\d{6,14}$')

# House number: digit(s) then hyphen then digits/letters  e.g. 1-1, 12-3A
HOUSE_NO_RE  = re.compile(r'^\d+[-/]\d*[A-Za-z]?\d*$')


# -- GSUB-based Telugu font decoder -------------------------------------------

def _build_gsub_map(tt: 'TTFont') -> dict:
    """Return {glyph_index: unicode_string} using GSUB reverse lookup."""
    reverse_sub = {}
    if 'GSUB' in tt:
        for record in tt['GSUB'].table.LookupList.Lookup:
            for sub in record.SubTable:
                if hasattr(sub, 'ligatures'):
                    for fg, lig_list in sub.ligatures.items():
                        for lig in lig_list:
                            reverse_sub[lig.LigGlyph] = [fg] + list(lig.Component)
                elif hasattr(sub, 'mapping'):
                    for inp, out in sub.mapping.items():
                        reverse_sub[out] = [inp]

    cmap = tt.getBestCmap()
    glyph_order = tt.getGlyphOrder()
    gname_to_uni = {g: u for u, g in cmap.items()}

    def g2u(gname, depth=0):
        if depth > 6:
            return ''
        if gname in gname_to_uni:
            return chr(gname_to_uni[gname])
        if gname in reverse_sub:
            return ''.join(g2u(g, depth + 1) for g in reverse_sub[gname])
        return ''

    return {i: g2u(gname) for i, gname in enumerate(glyph_order)}


class _PdfDecoder:
    """
    Holds per-document font decode maps.
    Gautami glyphs → proper Telugu Unicode via GSUB reverse lookup.
    Call decode_page(page) to get a list of (font_is_telugu, decoded_line_text).
    """

    def __init__(self, doc: 'fitz.Document'):
        # xref -> {glyph_id: unicode_str}
        self._maps: dict[int, dict] = {}
        # basefont_name -> xref  (built lazily per page)
        self._name_to_xref: dict[str, int] = {}
        self._doc = doc
        # Pre-scan all xrefs for Gautami fonts
        self._prescan()

    def _prescan(self):
        """Find all Gautami font xrefs in the document."""
        for page in self._doc:
            for f in page.get_fonts(full=True):
                xref, _ext, _ftype, basefont, _alias, _enc, *_ = f
                if 'Gautami' in basefont and basefont not in self._name_to_xref:
                    self._name_to_xref[basefont] = xref

    def _get_map(self, xref: int) -> dict | None:
        if xref in self._maps:
            return self._maps[xref]
        if not _FONTTOOLS_OK:
            return None
        try:
            font_data = self._doc.extract_font(xref)
            fbytes = font_data[3]
            if not fbytes:
                return None
            tt = TTFont(io.BytesIO(fbytes))
            m = _build_gsub_map(tt)
            self._maps[xref] = m
            return m
        except Exception:
            return None

    def decode_page(self, page: 'fitz.Page') -> list[str]:
        """Return list of decoded text lines (non-empty) from the page."""
        # Build font name -> xref for this page
        page_font_map: dict[str, int] = {}
        for f in page.get_fonts(full=True):
            xref, _ext, _ftype, basefont, _alias, _enc, *_ = f
            page_font_map[basefont] = xref
            # Also map partial matches (span font name may omit style)
            short = basefont.split('+')[-1]  # strip subset prefix like ABCDEE+
            page_font_map[short] = xref

        d = page.get_text('rawdict')
        lines: list[str] = []

        for block in d['blocks']:
            if block['type'] != 0:
                continue
            for line in block['lines']:
                text = ''
                for span in line['spans']:
                    font_name = span.get('font', '')
                    is_telugu = 'Gautami' in font_name

                    if is_telugu:
                        # Find xref: try full name, then partial
                        xref = page_font_map.get(font_name)
                        if xref is None:
                            for k, v in page_font_map.items():
                                if 'Gautami' in k:
                                    is_bold = 'Bold' in font_name
                                    if is_bold == ('Bold' in k):
                                        xref = v
                                        break
                        gmap = self._get_map(xref) if xref else None
                        for ch in span['chars']:
                            code = ord(ch['c']) if isinstance(ch['c'], str) else ch['c']
                            text += gmap.get(code, '') if gmap else chr(code)
                    else:
                        for ch in span['chars']:
                            text += ch['c'] if isinstance(ch['c'], str) else chr(ch['c'])

                stripped = text.strip().replace('\xa0', ' ').strip()
                if stripped:
                    lines.append(stripped)

        return lines


# -- Telugu text normalisation ------------------------------------------------

def _normalise_gender(raw: str) -> str:
    """Map decoded Telugu gender text to Male / Female."""
    r = raw.strip()
    # After GSUB decoding:
    #   'పు' (పురుషుడు abbrev) = Male
    #   'సీ్త' / 'స్త్రీ' (sthri) = Female
    if r.startswith('పు'):
        return 'Male'
    if r.startswith('సీ') or r.startswith('స్త') or 'స్త్రీ' in r:
        return 'Female'
    # Fallback: old garbled form detection
    if r.startswith('W'):
        return 'Male'
    if '\u013d' in r or '\u0160' in r:
        return 'Female'
    return r  # keep as-is if unknown


def _normalise_rel_type(raw: str) -> str:
    """Map decoded Telugu relationship type to Father / Husband."""
    r = raw.strip()
    # After GSUB decoding: 'తం' = తండ్రి (Father), 'భ' or 'భర్త' = Husband
    if r.startswith('తం') or r == 'తం':
        return 'Father'
    if r.startswith('భ') or r.startswith('Z'):
        return 'Husband'
    # Fallback: old garbled form
    if r in ('R3', 'R'):
        return 'Father'
    if r == 'Z':
        return 'Husband'
    return r


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


# -- Helper predicates --------------------------------------------------------

def _is_serial(token: str) -> bool:
    return token.isdigit()

def _is_age(token: str) -> bool:
    return token.isdigit() and 1 <= int(token) <= 120

def _is_voter_id(token: str) -> bool:
    return bool(VOTER_ID_RE.match(token.upper()))

def _is_house_no(token: str) -> bool:
    return bool(HOUSE_NO_RE.match(token))


# -- PDF extraction -----------------------------------------------------------

def extract_from_pdf(pdf_path: str, part_name: str = '',
                     preview: bool = False, max_pages: int = 0) -> list:
    doc = fitz.open(pdf_path)
    total_pages = min(len(doc), max_pages) if max_pages else len(doc)

    decoder = _PdfDecoder(doc)
    all_lines: list[str] = []

    for page_num in range(total_pages):
        page = doc[page_num]
        all_lines.extend(decoder.decode_page(page))

    doc.close()

    if preview:
        print(f"\n-- DECODED LINES from {Path(pdf_path).name} (first 120) --")
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
                'relationship_type': _normalise_rel_type(w[3]),
                'relationship_name': w[4],
                'gender':            _normalise_gender(w[5]),
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