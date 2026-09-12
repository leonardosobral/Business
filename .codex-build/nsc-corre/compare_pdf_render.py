from pathlib import Path
import sys

import numpy as np
from PIL import Image


ROOT = Path("/Users/Shared/Projects/RunnerHub/Business")
SOURCE_DIR = ROOT / ".codex-build/nsc-corre/rendered/v4"
RENDERED_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "tmp/pdfs/rendered-final"

results = []
for number in range(1, 15):
    source = np.asarray(Image.open(SOURCE_DIR / f"slide-{number}.png").convert("RGB"), dtype=np.int16)
    rendered = np.asarray(Image.open(RENDERED_DIR / f"page-{number:02d}.png").convert("RGB"), dtype=np.int16)
    if source.shape != rendered.shape:
        raise RuntimeError(f"Slide {number}: shape mismatch {source.shape} vs {rendered.shape}")
    delta = np.abs(source - rendered)
    results.append((number, float(delta.mean()), float((delta > 2).mean()), int(delta.max())))

for number, mean_delta, changed_fraction, max_delta in results:
    print(
        f"slide {number:02d}: mean_abs_delta={mean_delta:.5f}, "
        f"channels_over_2={changed_fraction:.5%}, max_delta={max_delta}"
    )

print(f"deck_mean_abs_delta={sum(item[1] for item in results) / len(results):.5f}")
print(f"deck_channels_over_2={sum(item[2] for item in results) / len(results):.5%}")
