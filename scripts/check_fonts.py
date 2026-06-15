"""Check which font each span uses on page 2 (voter records page)."""
import fitz, sys, io, pathlib
from fontTools.ttLib import TTFont

sys.stdout.reconfigure(encoding='utf-8')

PDF = r'C:\Users\MF40127873\Downloads\voter_pdfs\S01_185_140.pdf'
doc = fitz.open(PDF)


def build_decode_map(xref):
    fbytes = doc.extract_font(xref)[3]
    tt = TTFont(io.BytesIO(fbytes))
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

    def g2u(gname, d=0):
        if d > 6:
            return ''
        if gname in gname_to_uni:
            return chr(gname_to_uni[gname])
        if gname in reverse_sub:
            return ''.join(g2u(g, d + 1) for g in reverse_sub[gname])
        return ''

    return {i: g2u(gname) for i, gname in enumerate(glyph_order)}


map3 = build_decode_map(3)
map4 = build_decode_map(4)

page = doc[1]
d = page.get_text('rawdict')
out = []
for block in d['blocks']:
    if block['type'] == 0:
        for line in block['lines']:
            parts = []
            for span in line['spans']:
                font = span['font']
                raw = ''
                decoded = ''
                for ch in span['chars']:
                    code = ord(ch['c']) if isinstance(ch['c'], str) else ch['c']
                    raw += ch['c'] if isinstance(ch['c'], str) else chr(code)
                    if 'Gautami' in font:
                        use_map = map4 if 'Bold' in font else map3
                        decoded += use_map.get(code, chr(code))
                    else:
                        decoded += chr(code)
                parts.append(f'[{font}] raw={repr(raw)} dec={repr(decoded)}')
            out.append(' | '.join(parts))

pathlib.Path('fontmap_test.txt').write_text('\n'.join(out), encoding='utf-8')
print('Written fontmap_test.txt')
