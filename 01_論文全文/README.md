# 01_論文全文

## 檔案
- `MARS_碩士論文.tex`：論文完整 LaTeX 原始碼（單一檔）。
- `MARS_碩士論文.pdf`：英文含浮水印定稿 PDF（120 頁）。
- 其餘 `*.png`／`*.pdf`：論文所用之圖檔（`\includegraphics` 引用,須與 `.tex` 同目錄）。
- 圖片**原始編輯檔**（python 腳本／架構圖 pptx）見 [`../02_圖片原始檔/`](../02_圖片原始檔/)。

- `figures/`：論文所用之圖檔（`\graphicspath` 已設,`.tex` 內 `\includegraphics` 直接寫檔名即可）。

## 如何把 .tex 編譯成 PDF

**引擎**：XeLaTeX（**不可**用 pdflatex,因需系統字型與 CJK）。TeX Live 2022 以上。

**需要的字型**（Ubuntu 安裝指令）：
```bash
sudo apt install texlive-xetex texlive-lang-cjk fonts-arphic-ukai   # XeLaTeX + 中文楷體
# Times New Roman（英文正文）:安裝 msttcorefonts
sudo apt install ttf-mscorefonts-installer
```
- 英文正文字型:`Times New Roman`
- 中文正文字型:`AR PL UKai TW`（楷體;`fonts-arphic-ukai` 提供 AR PL UKai 家族）

**編譯**（在本資料夾內,執行**兩次**以解交叉引用/目錄/圖表清單）：
```bash
xelatex MARS_碩士論文.tex
xelatex MARS_碩士論文.tex
```
產出 `MARS_碩士論文.pdf`。若改內容,重跑上述兩行即可。

> 若無 `AR PL UKai TW`,系統可能 fallback 到 `AR PL UKai CN/HK`（字形相同,可正常編譯）。
> 浮水印由 `assets_watermark_faded.png` 提供;不要浮水印版可在 `.tex` 內移除該圖之 includegraphics。
