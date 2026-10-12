"""Xuất báo cáo Markdown thành PDF; cần reportlab và font DejaVu Sans."""
from pathlib import Path
from xml.sax.saxutils import escape
import re
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,PageBreak,Image
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
root=Path(__file__).resolve().parents[1]
fonts=Path('/usr/share/fonts/truetype/dejavu')
if fonts.exists(): normal=fonts/'DejaVuSans.ttf';bold=fonts/'DejaVuSans-Bold.ttf'
else: normal=Path('C:/Windows/Fonts/arial.ttf');bold=Path('C:/Windows/Fonts/arialbd.ttf')
pdfmetrics.registerFont(TTFont('Report',str(normal)));pdfmetrics.registerFont(TTFont('ReportBold',str(bold)));pdfmetrics.registerFontFamily('Report',normal='Report',bold='ReportBold',italic='Report',boldItalic='ReportBold')
body=ParagraphStyle('Body',fontName='Report',fontSize=9.2,leading=14,spaceAfter=7)
heading=ParagraphStyle('Heading',parent=body,fontName='ReportBold',fontSize=12,leading=17,spaceBefore=13,spaceAfter=9)
title=ParagraphStyle('Title',parent=heading,fontSize=17,leading=23)
small=ParagraphStyle('Small',parent=body,fontSize=8,leading=12)
def clean(s):
 s=escape(s).replace('`','')
 s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#26705d">\1</link>',s)
 return re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',s)
flow=[];table=[]
def flush():
 global table
 if not table:return
 rows=[[Paragraph(clean(cell),small) for cell in row] for row in table];cols=len(rows[0]);width=487/cols
 t=Table(rows,colWidths=[width]*cols,repeatRows=1,hAlign='LEFT');t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e9f0ec')),('VALIGN',(0,0),(-1,-1),'TOP'),('GRID',(0,0),(-1,-1),.4,colors.HexColor('#bdc8c2')),('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]));flow.extend([t,Spacer(1,9)]);table=[]
for line in (root/'docs/Mini-Project-3-Report.md').read_text(encoding='utf-8').splitlines():
 if line.startswith('|'):
  row=[cell.strip() for cell in line.strip('|').split('|')]
  if all(re.match(r'^:?-+:?$',cell) for cell in row):continue
  table.append(row);continue
 flush()
 if not line.strip():continue
 if line.startswith('## 3.') or line.startswith('## 4.'):flow.append(PageBreak())
 if line.startswith('# '):flow.append(Paragraph(clean(line[2:]),title))
 elif line.startswith('## '):flow.append(Paragraph(clean(line[3:]),heading))
 else:flow.append(Paragraph(clean(line),body))
flush()
photos=list((root/'docs/screenshots').glob('*.png'))
if photos:
 flow.extend([PageBreak(),Paragraph('Minh chứng trên Android Emulator',heading)])
 cells=[]
 for file in sorted(photos)[:4]:
  from PIL import Image as PILImage
  with PILImage.open(file) as im:w,h=im.size
  height=300;width=height*w/h
  cells.append([Image(str(file),width=width,height=height),Paragraph({'01_review_ocr':'Duyệt kết quả OCR', '02_expenses':'Danh sách khoản chi', '03_categories':'Thống kê danh mục', '04_weekly':'Thống kê theo tuần'}.get(file.stem,file.stem),small)])
 rows=[]
 for i in range(0,len(cells),2):rows.append([cells[i],cells[i+1] if i+1<len(cells) else ''])
 flow.append(Table(rows,colWidths=[243,243],style=[('VALIGN',(0,0),(-1,-1),'TOP')]))
def footer(c,doc):
 c.setFont('Report',8);c.setFillColor(colors.HexColor('#52675d'));c.drawString(54,28,'Nguyễn Đăng Đức Huy - 23IT101 - Lab 3');c.drawRightString(541,28,str(doc.page))
out=root/'docs/Bao-cao-Lab-3.pdf'
SimpleDocTemplate(str(out),pagesize=(595.28,841.89),leftMargin=54,rightMargin=54,topMargin=45,bottomMargin=48,title='Lab 3 - Sổ chi tiêu VKU',author='Nguyễn Đăng Đức Huy').build(flow,onFirstPage=footer,onLaterPages=footer)
print(out)
