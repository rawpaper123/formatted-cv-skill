# IntelliPro IPG Candidate template specification

## Reference identity

- Editable authority: `assets/reference.docx`
- Visual authority: `assets/reference.pdf`
- Brand artwork: `assets/intellipro-logo.png` (273 x 77 RGBA, transparent background)
- DOCX SHA-256: `bc3a20bd92a4944a64d6870309df5285dcfa90b902ad099d295fb5462086de87`
- PDF SHA-256: `c323483216371c73731f09aab5b577ea77225878388d1433d8e72684036fe6c4`
- Logo SHA-256: `4014dfe32d802e9011436903f635ffc0db891f1153ff25828647ea25c94b0459`
- Visual reference: 4 A4 pages. The page count is an example, not a limit.
- Package baseline: 17 ZIP parts, one Word section, 107 body paragraphs, no tables, no content controls, no fields, and no footnotes/endnotes.
- Privacy baseline: all candidate facts, names, employers, schools, locations, identifiers, publication links, document authors, and external hyperlinks have been replaced or removed. Bracketed text is structural guidance only and must never survive into a candidate deliverable.
- Output privacy rule: never include candidate email addresses, phone numbers, detailed street/mailing addresses, personal messaging/social handles, or personal contact/profile URLs. City-level location, professional identifiers such as ORCID, and content links such as DOI, publication, or project/repository URLs may remain when relevant.

## Page and brand system

- Page size: A4 portrait, 8.27 x 11.69 inches.
- Margins: 0.75 inch left/right and 1.00 inch top/bottom.
- Header artwork: right-aligned IntelliPro logo; source drawing is approximately 1.90 x 0.54 inches.
- Footer artwork: website and San Jose address strip; source drawing is approximately 5.74 x 0.30 inches.
- Preserve the source header/footer package parts and drawing relationships. In the WPS visual reference the artwork appears on pages 1 and 3; do not rebuild that behavior from scratch.
- The supplied transparent logo may replace the header logo only when reconstruction is unavoidable. Keep its aspect ratio and do not add a box, shadow, or background.

## Typography and rhythm

- Body text is 12 pt (`w:sz=24`). East Asian font is SimSun (`宋体`); Latin text uses the document's `majorAscii` theme, with Arial for complex-script fallback.
- Main text is black. Bold marks labels, roles, dates/companies, links, and selected emphasis.
- Section headings are bold and underlined, with a blank paragraph separating major sections.
- The reference relies heavily on direct paragraph/run formatting rather than named Heading styles. Reuse or clone reference paragraphs instead of normalizing styles.
- Preserve tabs and indents. Do not replace the opening information block or role headings with tables.

## Slot map

- Body paragraphs 0-7: opening candidate information. Use only non-contact fields such as name, city-level location, current company, current position, and relevant professional identifiers. One field per paragraph, with exactly one tab between label and value. Every paragraph carries the same explicit left tab stop at 1.75 inches from the text area's left edge; never substitute spaces or multiple default tabs.
- Paragraph 10: summary heading. Paragraphs 11-19 provide the triangular-bullet summary pattern.
- Paragraph 21: patents heading. Paragraphs 22-24 provide compact patent bullet patterns.
- Paragraph 26: languages heading. Paragraph 27 provides the language-line pattern.
- Paragraph 29: education heading. Paragraphs 30-33 provide education and optional thesis patterns.
- Paragraph 36: professional-experience heading.
- Experience blocks begin at paragraphs 37, 45, 54, 62, 69, 76, and 82. Each block uses: date range plus employer; optional employer description; bold job title; location; achievement bullets; blank separator.
- Paragraph 89: publications heading. Paragraphs 90-104 provide the numbered-publication pattern.

Paragraph numbers identify the immutable retained reference only. After cloning or deleting content, locate output slots by role, formatting pattern, and neighboring structure rather than stale output indices.

## Language labels

- Chinese headings: `概况总结`, `专利`, `语言能力`, `教育背景`, `工作经历`, `学术论文`.
- English headings: `Professional Summary`, `Patents`, `Languages`, `Education`, `Professional Experience`, `Publications`.
- Translate other labels consistently with the chosen output language. Preserve proper names, credential abbreviations, product names, and publication titles unless a conventional translation is clearly appropriate.

## Variable-content rules

- Candidate name is required. Credentials may remain in the displayed name and filename when the source uses them.
- Remove direct contact fields even when populated in the source; do not replace them with redaction labels or placeholders.
- Optional opening fields may be removed when absent. Replace or delete every bracketed placeholder; never retain sanitized reference text in a candidate deliverable.
- Omit an absent optional section and its surrounding excess whitespace.
- Clone a complete experience or publication pattern for additional entries. Preserve the source list/numbering definitions and hanging indents.
- Allow natural pagination. Keep a role's date/employer and title together when possible; avoid orphaned headings and nearly blank trailing pages.
- Preserve source detail unless the user requests condensation. If content is too dense, add pages before reducing type.

## Renderer evidence and fidelity gates

- WPS exported the retained DOCX as 4 pages whose 150 DPI page renders were pixel-identical to the retained PDF on all four pages.
- LibreOffice 26.2.4.2 opened the reference but reflowed it to 7 pages. LibreOffice is a required installed dependency and useful fallback/diagnostic engine, but its pagination is not the visual authority for this retained template.
- On Windows use WPS first for the final PDF when available, Word second, and LibreOffice third. On macOS prefer Microsoft Word through native app control, then Apple Pages, and use LibreOffice/Homebrew only as the final fallback. Switch engines after failure instead of repeatedly retrying.
- Before delivery, inspect every final PDF page and confirm branding, A4 geometry, readable 12 pt hierarchy, tab alignment, list indentation, balanced whitespace, and absence of sample text or placeholders.
