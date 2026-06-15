from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextBox, LTTextLine, LTChar
import sys

pdf_path = r'C:\Users\MF40127873\Downloads\S01_185_140.pdf'

for i, page_layout in enumerate(extract_pages(pdf_path)):
    if i != 1:
        continue
    for element in page_layout:
        if isinstance(element, LTTextBox):
            for line in element:
                if isinstance(line, LTTextLine):
                    text = line.get_text().strip()
                    if text and len(text) > 3:
                        print(f'Line: {repr(text[:80])}')
                        # Show character codepoints
                        for ch in text[:30]:
                            if ord(ch) > 127:
                                print(f'  U+{ord(ch):04X} = {ch!r}')
                        break
    break
