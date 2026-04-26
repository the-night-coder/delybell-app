from __future__ import annotations

import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
)


def _escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def build_pdf(md_path: Path, pdf_path: Path) -> None:
    raw = md_path.read_text(encoding="utf-8")
    lines = raw.splitlines()

    styles = getSampleStyleSheet()
    base = ParagraphStyle(
        "BodyBase",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=10.5,
        leading=15,
        spaceAfter=4,
    )
    h1 = ParagraphStyle(
        "H1",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=17,
        leading=22,
        textColor=colors.HexColor("#1f2937"),
        spaceBefore=8,
        spaceAfter=6,
    )
    h2 = ParagraphStyle(
        "H2",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=17,
        textColor=colors.HexColor("#111827"),
        spaceBefore=8,
        spaceAfter=4,
    )
    h3 = ParagraphStyle(
        "H3",
        parent=styles["Heading3"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#111827"),
        spaceBefore=6,
        spaceAfter=2,
    )
    bullet = ParagraphStyle(
        "BulletBody",
        parent=base,
        leftIndent=14,
        firstLineIndent=-9,
        bulletIndent=0,
    )
    num = ParagraphStyle(
        "NumBody",
        parent=base,
        leftIndent=16,
        firstLineIndent=-11,
        bulletIndent=0,
    )
    meta = ParagraphStyle(
        "Meta",
        parent=base,
        fontSize=9.5,
        textColor=colors.HexColor("#4b5563"),
    )
    title = ParagraphStyle(
        "Title",
        parent=h1,
        fontSize=19,
        leading=24,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#111827"),
        spaceAfter=10,
    )
    code_style = ParagraphStyle(
        "Code",
        parent=base,
        fontName="Courier",
        fontSize=8.7,
        leading=11,
        backColor=colors.HexColor("#f3f4f6"),
        borderColor=colors.HexColor("#e5e7eb"),
        borderWidth=0.4,
        borderPadding=6,
        leftIndent=2,
        rightIndent=2,
        spaceBefore=3,
        spaceAfter=5,
    )

    story = []
    in_code = False
    code_buf: list[str] = []
    para_buf: list[str] = []
    first_heading_used = False

    def flush_para() -> None:
        nonlocal para_buf
        if not para_buf:
            return
        text = " ".join(s.strip() for s in para_buf).strip()
        if text:
            style = meta if text.lower().startswith(("prepared for", "date:", "project version:")) else base
            story.append(Paragraph(_escape(text), style))
        para_buf = []

    def flush_code() -> None:
        nonlocal code_buf
        if not code_buf:
            return
        story.append(Preformatted("\n".join(code_buf), code_style))
        code_buf = []

    for line in lines:
        stripped = line.rstrip("\n")
        clean = stripped.strip()

        if clean.startswith("```"):
            flush_para()
            if in_code:
                flush_code()
                in_code = False
            else:
                in_code = True
            continue

        if in_code:
            code_buf.append(stripped)
            continue

        if not clean:
            flush_para()
            story.append(Spacer(1, 2))
            continue

        if clean.startswith("# "):
            flush_para()
            txt = _escape(clean[2:].strip())
            story.append(Paragraph(txt, title if not first_heading_used else h1))
            first_heading_used = True
            continue

        if clean.startswith("## "):
            flush_para()
            story.append(Paragraph(_escape(clean[3:].strip()), h2))
            continue

        if clean.startswith("### "):
            flush_para()
            story.append(Paragraph(_escape(clean[4:].strip()), h3))
            continue

        if clean.startswith("- "):
            flush_para()
            story.append(Paragraph(_escape(clean[2:].strip()), bullet, bulletText="•"))
            continue

        numbered = False
        for i in range(1, 100):
            prefix = f"{i}. "
            if clean.startswith(prefix):
                flush_para()
                story.append(Paragraph(_escape(clean[len(prefix):].strip()), num, bulletText=f"{i}."))
                numbered = True
                break
        if numbered:
            continue

        para_buf.append(stripped)

    flush_para()
    flush_code()

    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=14 * mm,
        title="Delybell Customer App - Project Handover Documentation",
        author="OpenAI Codex",
    )
    doc.build(story)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python docs/export_md_to_pdf.py <input.md> <output.pdf>")
        return 1
    md_path = Path(sys.argv[1])
    pdf_path = Path(sys.argv[2])
    if not md_path.exists():
        print(f"Input file not found: {md_path}")
        return 2
    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    build_pdf(md_path, pdf_path)
    print(f"Created PDF: {pdf_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
