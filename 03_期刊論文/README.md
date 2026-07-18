# 03_期刊論文

## 檔案
- `MARS_期刊論文.tex`：IEEEtran journal 格式（雙欄 10pt）,11 頁。
- `MARS_期刊論文.pdf`：編譯成品。
- `IEEEtran.cls`：期刊 document class（已隨附,確保離線可編）。
- `bibitems.json`：書目來源（`\thebibliography` 內嵌,無需外部 .bib）。
- `*.png`／`*.pdf`：所用圖檔（與論文共用）。

## 如何把 .tex 編譯成 PDF

**引擎**：pdfLaTeX（TeX Live 2022 以上;IEEEtran.cls 已隨附,不需另裝）。

**編譯**（在本資料夾內,執行**兩次**解交叉引用）：
```bash
pdflatex MARS_期刊論文.tex
pdflatex MARS_期刊論文.tex
```
產出 `MARS_期刊論文.pdf`。書目已內嵌於 `.tex`,不需跑 bibtex。
