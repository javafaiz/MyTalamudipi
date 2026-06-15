from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextBox, LTTextLine, LTChar, LTAnon
from pdfminer.pdfpage import PDFPage
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfdevice import PDFDevice
from pdfminer.pdffont import PDFCIDFont, PDFType0Font
import io

pdf_path = r'C:\Users\MF40127873\Downloads\S01_185_140.pdf'

# Use pdfminer to check character codes
with open(pdf_path, 'rb') as f:
    rsrcmgr = PDFResourceManager()
    
    for i, page_layout in enumerate(extract_pages(pdf_path)):
        if i > 1:
            break
        for element in page_layout:
            if isinstance(element, LTTextBox):
                for line in element:
                    if isinstance(line, LTTextLine):
                        text = line.get_text().strip()
                        if text and i == 1:
                            # Show non-ASCII chars and their code points
                            for ch in text[:50]:
                                if ord(ch) > 127:
                                    print(f'char: {ch!r}, codepoint: U+{ord(ch):04X}')
                        if text and i == 1 and len(text) > 3:
                            print(f'Line: {repr(text[:80])}')
                            break
                if i == 1:
                    break
        if i == 1:
            break
