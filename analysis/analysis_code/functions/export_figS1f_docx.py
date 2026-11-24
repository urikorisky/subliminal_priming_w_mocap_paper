"""Export Fig. S1f Temporal Full-Trajectory FDR summary table as a styled DOCX."""
import argparse
import html
import json
import os
import zipfile

CONTENT_TYPES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-officedocument.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>"""

RELS_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""

DOC_RELS_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>"""

STYLES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="20"/>
        <w:szCs w:val="20"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>"""


def make_run(text, bold=False, color=None, size_half_pt=20):
    props = ['<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>']
    if bold:
        props.append("<w:b/>")
    if color:
        props.append(f'<w:color w:val="{color}"/>')
    props.append(f'<w:sz w:val="{size_half_pt}"/><w:szCs w:val="{size_half_pt}"/>')
    escaped = html.escape(str(text), quote=False)
    return f'<w:r><w:rPr>{"".join(props)}</w:rPr><w:t xml:space="preserve">{escaped}</w:t></w:r>'


def make_cell(text, width_dxa, align="left", fill=None, bold=False, color="111111",
              size_half_pt=19, top_border=None, bottom_border=None):
    jc_map = {"left": "left", "center": "center", "right": "right"}
    jc = jc_map.get(align, "left")
    shd = f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>' if fill else ""
    borders = []
    if top_border:
        borders.append(f'<w:top {top_border}/>')
    if bottom_border:
        borders.append(f'<w:bottom {bottom_border}/>')
    border_xml = f"<w:tcBorders>{''.join(borders)}</w:tcBorders>" if borders else ""
    margins = (
        '<w:tcMar>'
        '<w:top w:w="90" w:type="dxa"/>'
        '<w:bottom w:w="90" w:type="dxa"/>'
        '<w:left w:w="110" w:type="dxa"/>'
        '<w:right w:w="110" w:type="dxa"/>'
        '</w:tcMar>'
    )
    tc_pr = (
        f'<w:tcPr><w:tcW w:w="{width_dxa}" w:type="dxa"/>'
        f'{border_xml}{shd}{margins}<w:vAlign w:val="center"/></w:tcPr>'
    )
    p_pr = f'<w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="{jc}"/></w:pPr>'
    run = make_run(text, bold=bold, color=color, size_half_pt=size_half_pt)
    return f"<w:tc>{tc_pr}<w:p>{p_pr}{run}</w:p></w:tc>"


def build_document_xml(payload):
    title = payload["title"]
    headers = payload["headers"]
    rows = payload["rows"]
    # Letter portrait printable width ~9360 dxa (6.5 in) or slightly wider margins 9900 dxa (~6.875 in)
    col_widths = [1980, 1200, 1140, 1180, 1200, 1180, 1480]  # sum = 9360 dxa (6.50 in)
    grid_xml = "".join(f'<w:gridCol w:w="{w}"/>' for w in col_widths)

    tbl_borders = (
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="12" w:space="0" w:color="2B3E5A"/>'
        '<w:bottom w:val="single" w:sz="12" w:space="0" w:color="2B3E5A"/>'
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="D0D7E2"/>'
        '<w:left w:val="none"/><w:right w:val="none"/><w:insideV w:val="none"/>'
        '</w:tblBorders>'
    )
    tbl_pr = (
        '<w:tblPr>'
        '<w:tblW w:w="9360" w:type="dxa"/>'
        '<w:tblLayout w:type="fixed"/>'
        f'{tbl_borders}'
        '</w:tblPr>'
    )

    hdr_cells = []
    for idx, h_txt in enumerate(headers):
        al = "left" if idx == 0 else "center"
        hdr_cells.append(
            make_cell(
                h_txt,
                col_widths[idx],
                align=al,
                fill="335280",
                bold=True,
                color="FFFFFF",
                size_half_pt=20,
            )
        )
    tr_xml = [f'<w:tr><w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>{"".join(hdr_cells)}</w:tr>']

    n_rows = len(rows)
    for r_idx, row in enumerate(rows):
        is_posthoc = bool(row.get("posthoc", False))
        if is_posthoc:
            bg = "FFFBE3"
        elif r_idx % 2 == 1:
            bg = "F7F9FC"
        else:
            bg = "FFFFFF"
        cells_data = row["cells"]
        is_sig = bool(row.get("significant", False))
        bot_b = 'w:val="single" w:sz="12" w:space="0" w:color="2B3E5A"' if r_idx == n_rows - 1 else None
        row_cells = []
        for c_idx, val in enumerate(cells_data):
            al = "left" if c_idx == 0 else "center"
            bold = (c_idx in (0, len(cells_data) - 1))
            color = "111111"
            if c_idx == len(cells_data) - 1:
                color = "197828" if is_sig else "A61E1E"
            row_cells.append(
                make_cell(
                    val,
                    col_widths[c_idx],
                    align=al,
                    fill=bg,
                    bold=bold,
                    color=color,
                    size_half_pt=19,
                    bottom_border=bot_b,
                )
            )
        tr_xml.append(f'<w:tr><w:trPr><w:cantSplit/></w:trPr>{"".join(row_cells)}</w:tr>')

    title_p = (
        '<w:p>'
        '<w:pPr><w:spacing w:before="0" w:after="140"/></w:pPr>'
        f'{make_run(title, bold=True, color="111111", size_half_pt=24)}'
        '</w:p>'
    )
    table_xml = f"<w:tbl>{tbl_pr}<w:tblGrid>{grid_xml}</w:tblGrid>{''.join(tr_xml)}</w:tbl>"
    sect_pr = (
        '<w:sectPr>'
        '<w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="1080" w:right="1440" w:bottom="1080" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>'
        '</w:sectPr>'
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        f"<w:body>{title_p}{table_xml}<w:p/>{sect_pr}</w:body>"
        "</w:document>"
    )


def main():
    parser = argparse.ArgumentParser(description="Write Fig. S1f table DOCX")
    parser.add_argument("--json", required=True, help="Path to JSON payload")
    parser.add_argument("--out", required=True, help="Output DOCX path")
    args = parser.parse_args()

    with open(args.json, "r", encoding="utf-8") as f:
        payload = json.load(f)

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    doc_xml = build_document_xml(payload)
    with zipfile.ZipFile(args.out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", CONTENT_TYPES_XML)
        zf.writestr("_rels/.rels", RELS_XML)
        zf.writestr("word/_rels/document.xml.rels", DOC_RELS_XML)
        zf.writestr("word/styles.xml", STYLES_XML)
        zf.writestr("word/document.xml", doc_xml)


if __name__ == "__main__":
    main()
