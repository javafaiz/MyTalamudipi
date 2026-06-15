import fitz
import re

doc = fitz.open(r'C:\Users\MF40127873\Downloads\S01_185_140.pdf')

# Search for ToUnicode CMap in all xref objects
for xref in range(1, doc.xref_length()):
    try:
        keys = doc.xref_get_keys(xref)
        if 'ToUnicode' in keys:
            print(f'Found ToUnicode at xref {xref}')
            stream = doc.xref_stream(xref)
            if stream:
                text = stream.decode('latin-1', errors='replace')
                if 'beginbfchar' in text or 'beginbfrange' in text:
                    print(text[:4000])
                    break
    except Exception as e:
        pass

print("Done searching")
