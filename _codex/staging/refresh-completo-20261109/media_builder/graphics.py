"""Content-free graphic primitives adapted from RoadRunners' public kit.

Provenance: RoadRunners/_codex/docs/brasil_que_corre_provas/
lancamento_q3_2026_10_09/gerar_kit.py: rect, txt, logo (09 October 2026).
Only these drawing primitives are copied. No historical module, DATA, source JSON,
top-level registration, mkdir or generation code is imported or executed.
"""
from html import escape
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

INK = '#242424'
GRAY = '#CFCFCF'
PANEL = '#393939'
YELLOW = '#F6BD30'
WHITE = '#FFFFFF'
LILAC = '#D8C8F2'
MINT = '#B6DDCB'


class Graphics:
    def __init__(self, fonts):
        for name, filename in [('Body', 'Poppins-400.ttf'), ('Medium', 'Poppins-600.ttf'),
                               ('Bold', 'Poppins-700.ttf'), ('Title', 'LibreFranklin-900.ttf')]:
            if name not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(TTFont(name, str(fonts / filename)))
        self.layout = []

    def rect(self, c, x, y, w, h, color, H, radius=0):
        c.setFillColor(HexColor(color))
        if radius:
            c.roundRect(x, H-y-h, w, h, radius, fill=1, stroke=0)
        else:
            c.rect(x, H-y-h, w, h, fill=1, stroke=0)

    def txt(self, c, text, x, y, width, size, H, color=WHITE, font='Body', leading=None, max_h=None):
        p = Paragraph(escape(str(text)).replace('\n', '<br/>'), ParagraphStyle('public', fontName=font,
                      fontSize=size, leading=leading or size*1.28, textColor=HexColor(color)))
        _, height = p.wrap(width, H)
        if x < 0 or y < 0 or y + height > H-15 or (max_h is not None and height > max_h):
            raise ValueError(f'Text exceeds layout: {text!r}; y={y}, height={height}, max={max_h}')
        p.drawOn(c, x, H-y-height)
        self.layout.append(dict(page=c.getPageNumber(), text=str(text), box=[x, y, width, height]))
        return height

    def logo(self, c, H, x=64, y=52):
        self.txt(c, 'ROAD', x, y, 115, 26, H, font='Title')
        self.rect(c, x+89, y+1, 5, 31, YELLOW, H)
        self.rect(c, x+100, y+1, 5, 31, YELLOW, H)
        self.txt(c, 'RUNNERS', x+116, y, 200, 26, H, font='Title')
