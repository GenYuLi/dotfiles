---
name: export-excalidraw
description: Export .excalidraw files to PNG for embedding in mdBook, docs, or READMEs. Use when the user says "export excalidraw", "convert to png", "excalidraw to png", or after creating/editing .excalidraw diagram files. Works on single files or entire directories.
---

# Export Excalidraw to PNG

Convert `.excalidraw` files to `.png` for embedding in markdown (mdBook, GitHub, etc.).

## Input

$ARGUMENTS

If no arguments given, search the current project for all `.excalidraw` files and offer to export them.

## Strategy

Use one of these methods in order of preference:

### Method 1: @excalidraw/cli (Node.js)

```bash
npx @excalidraw/cli export --format png --scale 2 INPUT.excalidraw --output OUTPUT.png
```

If `npx` fails or the package doesn't exist, fall back to Method 2.

### Method 2: Puppeteer headless browser

Write a small Node.js script that:
1. Starts a headless Chromium via Puppeteer
2. Loads excalidraw.com
3. Imports the .excalidraw JSON via the Excalidraw API
4. Exports to PNG at 2x scale
5. Saves to the same directory with `.png` extension

```javascript
// Pseudocode — adapt as needed
const puppeteer = require('puppeteer');
const fs = require('fs');

async function exportExcalidraw(inputPath, outputPath) {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    await page.goto('https://excalidraw.com');

    const sceneData = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

    // Use Excalidraw's exportToBlob API
    const pngBuffer = await page.evaluate(async (scene) => {
        // Load scene into Excalidraw
        // Use window.EXCALIDRAW_ASSET_PATH or direct API
        // Export via canvas.toBlob()
    }, sceneData);

    fs.writeFileSync(outputPath, pngBuffer);
    await browser.close();
}
```

### Method 3: resvg / Inkscape (if SVG intermediate)

If the above don't work, check for `resvg` or `inkscape`:
```bash
# Convert excalidraw JSON to SVG first (manual), then:
resvg input.svg output.png --width 1600
# or
inkscape input.svg --export-type=png --export-width=1600 --export-filename=output.png
```

### Method 4: Manual fallback

If no automated method works, instruct the user:
1. Open the `.excalidraw` file at excalidraw.com (drag & drop or Open menu)
2. Select all elements (Ctrl+A)
3. Export → PNG → 2x scale → Save
4. Name it the same as the `.excalidraw` file but with `.png` extension
5. Place in the same directory

## Workflow

1. **Find files**: If no path given, use `find . -name "*.excalidraw"` to list all files
2. **Check tools**: Try `npx @excalidraw/cli --version`, then check for `puppeteer`, `resvg`, `inkscape`
3. **Export**: Use the best available method
4. **Verify**: Check the PNG was created and has reasonable file size (> 1KB)
5. **Update markdown**: Search for `<!-- 有 PNG 後替換為` comments and offer to replace with actual `![](path.png)` image embeds
6. **Report**: List all exported files and their sizes

## Post-export: Update Markdown References

After exporting, search for TODO comments in markdown files that reference the exported diagrams:

```bash
grep -rn "有 PNG 後替換為" --include="*.md" .
```

For each match, replace the placeholder link + comment block with the actual image embed:

**Before:**
```markdown
**[圖：Title](./diagrams/file.excalidraw)** — 用 Excalidraw 開啟

<!-- 有 PNG 後替換為：![Title](./diagrams/file.png) -->
```

**After:**
```markdown
![Title](./diagrams/file.png)

> 原始檔：[file.excalidraw](./diagrams/file.excalidraw)
```
