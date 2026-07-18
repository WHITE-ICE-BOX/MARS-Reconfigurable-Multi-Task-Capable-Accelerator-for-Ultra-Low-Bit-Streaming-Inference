# 04_會議論文

## 檔案
- `MARS_會議論文.tex`：IEEEtran conference 格式,5 頁。
- `MARS_會議論文.pdf`：編譯成品。
- `IEEEtran.cls`：會議 document class（已隨附,確保離線可編）。


- `figures/`：所用圖檔。

## 如何把 .tex 編譯成 PDF

**引擎**：pdfLaTeX（TeX Live 2022 以上;IEEEtran.cls 已隨附）。

**編譯**（在本資料夾內,執行**兩次**）：
```bash
pdflatex MARS_會議論文.tex
pdflatex MARS_會議論文.tex
```
產出 `MARS_會議論文.pdf`。書目已內嵌於 `.tex`。
