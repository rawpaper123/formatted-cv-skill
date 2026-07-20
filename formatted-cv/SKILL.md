---
name: formatted-cv
description: Transform candidate resumes from DOCX or PDF into privacy-safe IntelliPro Formatted CVs that remove candidate contact details, follow the retained IPG Candidate layout and branding, preserve the source language unless another language is requested, and deliver matching Word and PDF files named "Candidate Name - IPG Candidate". Use when the user asks to format, template, standardize, translate, or convert a resume/CV into a Formatted CV, IntelliPro CV, or IPG Candidate CV.
---

# Formatted CV

Create a candidate CV from the retained IntelliPro reference. Return both DOCX and PDF. Treat `assets/reference.docx` as the editable structure authority and `assets/reference.pdf` as the visual authority.

## Required preparation

1. Read `references/template-spec.md` before editing.
2. Use the installed Documents and PDF capabilities to inspect the complete source resume, including every page, table, header, footer, text box, and image.
3. On Windows run `scripts/ensure_libreoffice.ps1` before authoring and let it install LibreOffice when absent. On macOS do not install LibreOffice up front: prefer Microsoft Word through native app control, then let `scripts/export_pdf.sh` try Apple Pages and finally LibreOffice. Only the last fallback uses the official Homebrew `libreoffice` cask; fail clearly when no working exporter is available.
4. Keep `assets/reference.docx`, `assets/reference.pdf`, and `assets/intellipro-logo.png` unchanged.

## Language and content rules

- Detect the source resume's main language and use it for the output by default.
- Use another language only when the user explicitly requests it. Translate faithfully when needed.
- Extract facts from the supplied resume only. Do not invent employers, dates, titles, credentials, compensation, visa status, achievements, metrics, publications, patents, or contact details.
- Never include candidate contact details, even when present in the source: email addresses, telephone/mobile numbers, street or mailing addresses, personal messaging/social handles, or personal profile/contact URLs. Remove them without placeholders.
- Keep location only at city, metro, state/province, or country level when relevant. Professional identifiers and content links such as ORCID, DOI, publication URLs, and project/repository URLs may remain when they support the CV rather than provide a contact route.
- Ask for the candidate name if it cannot be established. Remove unavailable optional rows or sections cleanly; never leave placeholders such as `N/A`, `TBD`, or sample-candidate text.
- The bracketed text in `assets/reference.docx` is privacy-safe structural guidance, not output content. Replace or delete every bracketed placeholder in the candidate deliverables.
- Preserve all materially relevant source content. Page count may grow or shrink. Prefer additional pages over smaller type, cramped spacing, or destructive summarization.
- Do not research or add company descriptions unless the user explicitly requests enrichment.

## Build workflow

1. Copy `assets/reference.docx` to a task-local working DOCX. Never edit the retained reference.
2. Map the source content to the slot patterns in `references/template-spec.md`:
   - candidate information, excluding all direct contact details;
   - professional summary;
   - patents;
   - languages;
   - education;
   - professional experience;
   - publications.
3. Translate labels and section headings to the output language. For Chinese use `候选人姓名`, `签证状态`, `当前所在地`, `当前公司`, `当前职位`, `当前薪资`, `求职方向`, and `推荐编号`. For English use the labels retained in the reference.
4. Edit or clone source paragraphs in place so their paragraph and run properties remain source-derived. Delete whole unused pattern blocks. Do not rebuild the document from a blank file or introduce a second style system.
5. In every opening-information paragraph, keep exactly one tab between the label and value and preserve the reference's explicit 1.75-inch left tab stop. All values must begin on the same vertical line regardless of label length; never align this block with spaces or multiple default tabs.
6. Preserve A4 geometry, margins, header/footer artwork, IntelliPro logo treatment, section hierarchy, tab alignment, list indentation, and publication numbering. Use `assets/intellipro-logo.png` only when the header artwork must be recreated.
7. Keep the reference's 12 pt body type and readable spacing. Add pages when content grows; do not force a four-page limit.
8. Name the outputs exactly `<candidate name> - IPG Candidate.docx` and `<candidate name> - IPG Candidate.pdf`. Sanitize only characters Windows forbids in filenames.

## PDF export and fallback

On Windows run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/export_pdf.ps1 `
  -InputDocx "C:\absolute\path\Candidate Name - IPG Candidate.docx" `
  -OutputPdf "C:\absolute\path\Candidate Name - IPG Candidate.pdf"
```

On macOS run:

```bash
bash scripts/export_pdf.sh "/absolute/path/Candidate Name - IPG Candidate.docx" \
  "/absolute/path/Candidate Name - IPG Candidate.pdf" --force
```

The Windows script verifies LibreOffice first, then tries WPS, Microsoft Word, and LibreOffice in that order. On macOS, first use Microsoft Word through the installed native app-control capability when available because it best preserves DOCX layout. Otherwise the shell script tries Apple Pages, then installs/uses LibreOffice only as the final fallback. Move on after failure; do not repeatedly retry one engine.

## Verification gate

1. Render the final PDF to page images with the PDF capability and inspect every page at 100% zoom.
2. Inspect the final DOCX structurally and render it through the best working local engine. Use the platform export script's PDF as the user-visible rendering authority when the bundled Documents renderer fails.
3. Compare the result with `assets/reference.pdf` for layout language, not fixed pagination: A4 proportions, margins, branding, typography, hierarchy, alignment, whitespace, bullets, and recurring header/footer treatment.
4. Confirm the opening-information values share one exact left edge in both DOCX and PDF. Fail and revise if any row shifts because of label length, spaces, or default tab spacing.
5. Fail and revise if any text clips, overlaps, becomes unreadably dense, wraps into the wrong column, leaves sample content, or separates a role heading from its content.
6. Search both final files for every source email address, phone number, detailed address, social/messaging handle, and personal contact/profile URL. Fail and revise if any survives.
7. Confirm both final files exist, are non-empty, open successfully, contain the same candidate content, and follow the required filenames.

After changing scripts or retained assets, run `scripts/self_test.ps1` on Windows or `bash scripts/self_test.sh` on macOS.
