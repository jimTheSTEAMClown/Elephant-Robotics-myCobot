# AI-Rules-Documentation-Projects - STEAM Clown Documentation Rules

> Comprehensive style and formatting rules for all documentation generated for Jim The STEAM Clown / SVCTE Mechatronics curriculum projects.
> Apply these rules as a validation pass on any AI-generated document before finalizing.

---

## 1. Output Format

- **All documents are Markdown (`.md`) files.** Never generate `.docx`, `.html`, or `.pdf` unless explicitly requested.
- Deliver documents as both:
  - An inline Markdown preview in the chat (for copy-paste convenience), **and**
  - A downloadable `.md` file artifact.
- Files must render correctly when pasted or committed directly into a **GitHub `.md` file**. Test mentally against GitHub's Markdown renderer before finalizing.
- $\color{red}{Note:}$ Before generating an .md file, check the file for anything that won't render cleanly on GitHub's Markdown renderer.

---

## 2. Heading Hierarchy

- **Exactly one `# H1`** per document — the document title only.
- Use `##` for major sections, `###` for subsections, `####` sparingly for deep nesting.
- Never skip heading levels (e.g., don't jump from `##` to `####`).
- No duplicate H1s. If a section was promoted to H1 during editing, demote it back to `##`.

---

## 2.1 Heading Emojis

- Don't use em dash (—)
- Keep sentences in natural language, and use standard punctuation, with commas and periods where appropriate.

---

## 2.2 Heading Emojis

- In general don't use Emojis in headings
- Ok are "green check mark" and "red X" when highlighting right and wrong options 

---

## 3. Code Fences

- **Every code block must have a language label.** No bare triple-backtick fences.

  ```python
  # Correct — labeled
  ```

  ```
  # Wrong — no label
  ```

- Common labels to use: `python`, `cpp`, `arduino`, `bash`, `text`, `yaml`, `json`, `markdown`, `mermaid`.
- Use `text` for directory trees, plain output, or anything that isn't a programming language.
- Use `arduino` or `cpp` for Arduino/C++ sketches (both are acceptable; `arduino` is preferred for `.ino` files).

---

## 4. No Raw HTML

- **Never use raw HTML tags** inside Markdown documents.
- No `<br>`, `<div>`, `<span>`, `<a href="...">`, `<img>`, `<details>`, `<summary>`, or any other HTML elements.
- Use Markdown-native syntax for everything:
  - Links: `[link text](URL)`
  - Images: `![alt text](URL)`
  - Horizontal rules: `---`
  - Line breaks: blank line between paragraphs

---

## 5. Links and URLs

- **No raw/bare URLs.** Always wrap in Markdown link syntax: `[descriptive text](https://...)`.
- Never use auto-generated link text like `[http://README.md](http://README.md)` — these are a sign of editor contamination (Notion, Google Docs, etc.).
- Source citations go at the **bottom of the document** in a `## Sources` or `## References` section with full labeled links.

---

## 6. Diagrams

- **Prefer Mermaid diagrams over ASCII art** for all architecture, flow, and system diagrams.
- Always use a labeled `mermaid` code fence:

  ````markdown
  ```mermaid
  graph TD
      A[Input] --> B[Process] --> C[Output]
  ```
  ````

- ASCII art is acceptable only for very simple inline illustrations where a Mermaid diagram would be overkill (e.g., a 3-pin connector pinout).
- Never embed diagrams as images if a Mermaid equivalent is feasible.

---

## 7. Directory Trees

- Render directory trees inside a labeled `text` code fence — never as bare Markdown lists or with raw link formatting.

  ```text
  project_root/
  ├── src/
  │   └── main.py
  └── README.md
  ```

- Use proper tree characters: `├──`, `└──`, `│`. Do not use `-` or `*` as tree branches.

---

## 8. Inclusive Terminology (Serial Protocols)

- **Never use "Master/Slave"** for any serial protocol or hardware relationship.
- Use the appropriate inclusive alternative based on the protocol context:

  | Protocol | Use Instead |
  |---|---|
  | SPI | Controller / Peripheral |
  | I²C | Controller / Target |
  | USB | Host / Device |
  | Generic / ambiguous | Primary / Secondary |

- This rule applies to all documentation, code comments, diagram labels, and variable names.

---

## 9. Code Comments — Curriculum Style

- In curriculum-facing code, comments must explain **why**, not just **what**.
- Use the `# LEARN:` comment convention to flag key concepts for students:

  ```python
  # LEARN: We use BOARD pin numbering so the code matches the physical pin labels
  #        on the Raspberry Pi board. BCM numbering refers to the chip's GPIO numbers,
  #        which don't match the printed labels.
  GPIO.setmode(GPIO.BOARD)
  ```

- Avoid trivial comments that restate the code (e.g., `# increment i` above `i += 1`).

---

## 10. Document Metadata & Disclaimer

When a document was AI-assisted, include a standard disclaimer block near the top (after the H1 and summary, before the first major section):

```markdown
> **AI Assist Disclosure:** This document was generated with AI assistance (Claude / ChatGPT),
> reviewed and refined by Jim The STEAM Clown, and validated against STEAM Clown documentation rules.
> Content accuracy has [not yet been / been] fully verified — use with appropriate judgment.
```

Adjust the final clause based on review status.

---

## 11. Source Citations

- **Always cite sources** used in a document.
- Place a `## Sources` section at the bottom of every document that references external material.
- Format:

  ```markdown
  ## Sources

  - [Descriptive Title](https://full-url-here)
  - [Another Source](https://full-url-here)
  ```

- Never embed bare URLs inline in body text.

---

## 12. File and Project Naming Conventions

- Use **lowercase with hyphens** for filenames: `rover_arduino-c-architecture_guide.md` ✓
- No spaces in filenames.
- Descriptive names over generic names: `pi_rover_ultrasonic.py` preferred over `main.py`.
- Document filenames should describe their content, not their type: `steam_clown_lms_strategy.md`, not `strategy_doc.md`.

---

## 13. Tables

- Use **Markdown pipe tables** for structured data.
- Always include a header row and a separator row.
- Keep columns reasonably aligned in source for readability.

  ```markdown
  | Column A | Column B | Column C |
  |---|---|---|
  | Value 1  | Value 2  | Value 3  |
  ```

---

## 14. ZIP / Deployment Package Structure

- For the **Curriculum Development Time Tracker** and similar web app projects:
  - ZIP files must use `tracker/` at root with `data/` as a subfolder.
  - Structure must support direct deployment by extracting to the server directory.
- For Raspberry Pi script packages:
  - Include a `logs/` directory placeholder or `.gitkeep`.
  - Include a `README.md` at the project root.

---

## 15. Validation Checklist

Run this checklist as a final pass before delivering any document:

- [ ] Exactly one `# H1` (document title only)
- [ ] No heading levels skipped
- [ ] All code fences have a language label
- [ ] No raw HTML tags anywhere
- [ ] No bare/raw URLs — all wrapped as `[text](url)`
- [ ] No auto-linked filenames (e.g., `[README.md](http://README.md)`)
- [ ] Diagrams use Mermaid, not ASCII art (where applicable)
- [ ] Directory trees use `text` code fences with proper tree characters
- [ ] Serial protocol terminology is inclusive (no Master/Slave)
- [ ] Sources cited at the bottom if external references used
- [ ] Filename is descriptive and uses lowercase-with-hyphens convention
- [ ] AI Assist Disclosure block present (if AI-generated)

---

## 16. Open Source & Content Ownership Notes

- All curriculum documents are authored with the intent of **open source release**.
- Master source format is **human-readable Markdown**, Git-backed.
- Documents must not embed platform-specific formatting (no Canvas LMS HTML export artifacts, no Google Docs smart quotes that break code blocks).
- Smart quotes (`"` `"` `'` `'`) must be replaced with straight quotes (`"` `'`) inside code blocks.

---

*Last updated: 2026 — Jim The STEAM Clown / SVCTE Mechatronics*
