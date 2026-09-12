from pathlib import Path

from PIL import Image
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas


ROOT = Path("/Users/Shared/Projects/RunnerHub/Business")
SOURCE_DIR = ROOT / ".codex-build/nsc-corre/rendered/v4"
OUTPUT_PATH = ROOT / "output/pdf/NSC_Corre_Parceria_RunnerHub_v4.pdf"
PAGE_SIZE = (960, 540)


def slide_number(path: Path) -> int:
    return int(path.stem.rsplit("-", 1)[1])


slides = sorted(SOURCE_DIR.glob("slide-*.png"), key=slide_number)
if len(slides) != 14:
    raise RuntimeError(f"Expected 14 rendered slides, found {len(slides)}")

for slide in slides:
    with Image.open(slide) as image:
        if image.size != (1920, 1080):
            raise RuntimeError(f"Unexpected dimensions for {slide.name}: {image.size}")

OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
pdf = canvas.Canvas(str(OUTPUT_PATH), pagesize=PAGE_SIZE, pageCompression=1)
pdf.setTitle("NSC Corre - Parceria RunnerHub + NSC")
pdf.setAuthor("RunnerHub")
pdf.setSubject("Proposta de plataforma anual para a corrida catarinense")

for slide in slides:
    pdf.drawImage(
        ImageReader(str(slide)),
        0,
        0,
        width=PAGE_SIZE[0],
        height=PAGE_SIZE[1],
        preserveAspectRatio=True,
        anchor="c",
        mask="auto",
    )
    pdf.showPage()

pdf.save()
print(OUTPUT_PATH)
