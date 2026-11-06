# anydoc 使用文档

## 1. 项目简介

`anydoc` 是 Firecrawl 开源的文档转 Markdown 工具，核心由 Rust 实现，可把 Word、PPT、Excel、OpenDocument、RTF、EPUB、CSV、PDF 等文件转换为 GitHub-Flavored Markdown。

使用方式说明：日常转换文档不需要保留源码，直接使用 npm、pip 或 cargo 上发布的包即可。源码仓库此前仅用于查看 README 和示例，已从本地删除。

本文档参考版本：

```bash
anydoc v0.1.8
```

## 2. 支持格式

| 类型 | 扩展名 |
| --- | --- |
| Word | `.doc`, `.docx`, `.docm` |
| PowerPoint | `.ppt`, `.pps`, `.pot`, `.pptx`, `.pptm`, `.ppsx`, `.ppsm` |
| Excel | `.xls`, `.xlsx`, `.xlsm`, `.xlsb` |
| OpenDocument | `.odt`, `.ods`, `.odp` |
| Rich Text Format | `.rtf` |
| EPUB | `.epub` |
| CSV | `.csv` |
| PDF | `.pdf` |

注意：普通文本型 PDF 可本地转换；扫描件或纯图片 PDF 不包含可提取文本，`anydoc` 不做 OCR，通常会报 `unsupported`。

## 3. 最快使用方式：CLI

不需要手动构建仓库，直接使用 npm 发布包即可：

```bash
npx @firecrawl/anydoc report.docx
```

输出到文件：

```bash
npx @firecrawl/anydoc report.docx -o report.md
```

从标准输入读取：

```bash
npx @firecrawl/anydoc - --format csv < data.csv
```

全局安装后使用：

```bash
npm install -g @firecrawl/anydoc
anydoc report.docx -o report.md
```

查看帮助：

```bash
anydoc --help
```

CLI 常用参数：

| 参数 | 说明 |
| --- | --- |
| `-o, --output <path>` | 把 Markdown 写入指定文件 |
| `-f, --format <format>` | 显式指定输入格式，例如 `csv`、`docx`、`pdf` |
| `-h, --help` | 查看帮助 |
| `-V, --version` | 查看版本 |

本地验证命令：

```bash
npx -y @firecrawl/anydoc tests/fixtures/docx/text.docx
```

该命令已在本机验证成功，可以正常输出 Markdown。

## 4. Node.js 使用

安装：

```bash
npm install @firecrawl/anydoc
```

示例：

```js
import { toDocument, toMarkdown, toMarkdownBytes } from '@firecrawl/anydoc';

const markdown = await toMarkdown('report.docx');

const fromBytes = await toMarkdownBytes(bytes);

const fromCsv = await toMarkdownBytes(bytes, 'csv');

const document = await toDocument(bytes);
console.log(document.assets);
```

错误处理：

```js
try {
  const markdown = await toMarkdown('report.docx');
  console.log(markdown);
} catch (error) {
  if (error.code === 'encrypted' || error.code === 'unsupported') {
    console.error('文件无法转换:', error.code);
  } else {
    throw error;
  }
}
```

仓库内 Node 示例：

```bash
node examples/convert.mjs tests/fixtures/docx/text.docx -o out.md
```

如果要使用仓库本地源码，需要先在 `node/` 目录构建：

```bash
cd node
npm install
npm run build
npm test
```

## 5. Python 使用

安装：

```bash
pip install firecrawl-anydoc
```

注意：包名是 `firecrawl-anydoc`，代码中导入名是 `anydoc`。

示例：

```python
import anydoc

markdown = anydoc.to_markdown("report.docx")

markdown = anydoc.to_markdown_bytes(data)

markdown = anydoc.to_markdown_bytes(data, "csv")

document = anydoc.to_document(data)
print(document.assets)
```

错误处理：

```python
import anydoc

try:
    markdown = anydoc.to_markdown("report.docx")
except (anydoc.EncryptedError, anydoc.UnsupportedError) as error:
    print("文件无法转换:", type(error).__name__)
```

仓库内 Python 示例：

```bash
python examples/convert.py tests/fixtures/docx/text.docx -o out.md
```

如果要使用仓库本地源码，需要先构建 Python 绑定：

```bash
cd python
pip install maturin
maturin develop
python -m unittest discover -s tests
```

## 6. Rust 使用

安装依赖：

```bash
cargo add anydoc
```

示例：

```rust
let markdown = anydoc::to_markdown("report.docx")?;

let markdown = anydoc::to_markdown_bytes(&bytes, None)?;

let markdown = anydoc::to_markdown_bytes(&bytes, anydoc::Format::Csv)?;

let document = anydoc::to_document(&bytes, None)?;
```

仓库内 Rust 示例：

```bash
cargo run --example convert -- tests/fixtures/docx/text.docx -o out.md
```

开发测试：

```bash
cargo test
```

要求：当前 `Cargo.toml` 声明 Rust 版本至少为 `1.88`。

## 7. 浏览器 / WebAssembly 使用

安装：

```bash
npm install @firecrawl/anydoc-wasm
```

示例：

```js
import init, { toMarkdownBytes, toDocument } from '@firecrawl/anydoc-wasm';

await init();

const markdown = toMarkdownBytes(bytes);
const fromCsv = toMarkdownBytes(bytes, 'csv');
const document = toDocument(bytes);
```

WASM 版本没有文件系统 API，需要从 `File`、`ArrayBuffer` 或网络响应中读取字节后再转换。调用是同步执行的，如果在浏览器主线程转换大文件，建议放到 Web Worker 中执行。

本地构建 demo：

```bash
wasm-pack build wasm --release --target web --no-pack --out-dir www/pkg
python -m http.server -d wasm/www
```

## 8. 格式识别

`anydoc` 优先根据文件内容识别格式，而不是只看扩展名。例如 PDF header、RTF 起始标记、OLE 流名称、ZIP 包内的 mimetype 和 content types。

CSV 没有稳定的内容签名，所以 CSV 常需要依赖扩展名或显式传入格式：

```bash
npx @firecrawl/anydoc - --format csv < data.csv
```

Node：

```js
formatFromBytes(bytes);
formatFromExtension('.pptm');
formatFromPath('report.odt');
```

Python：

```python
anydoc.format_from_bytes(data)
anydoc.format_from_extension(".pptm")
anydoc.format_from_path("report.odt")
```

Rust：

```rust
Format::from_bytes(&bytes);
Format::from_extension("pptm");
Format::from_path(Path::new("report.odt"));
```

## 9. 图片和附件

Markdown 不能直接嵌入二进制字节。文档中的图片和嵌入对象会在 Markdown 中以 alt text 形式表现，原始字节会保留在 `document.assets` 中，并带有 media type。

仓库示例支持把资源导出到目录：

```bash
node examples/convert.mjs report.docx -o report.md --assets assets
python examples/convert.py report.docx -o report.md --assets assets
cargo run --example convert -- report.docx -o report.md --assets assets
```

## 10. 常见错误

| 错误 | 含义 |
| --- | --- |
| `unsupported` / `UnsupportedError` | 未知格式，或文件无法转换，例如纯图片 PDF |
| `malformed` / `MalformedError` | 文件结构损坏，无法提取有效内容 |
| `encrypted` / `EncryptedError` | 文件加密或有密码保护 |
| `resourceLimit` / `ResourceLimitError` | 超过安全限制，例如解压、嵌套、节点数限制 |
| `missingPart` / `MissingPartError` | 文档包缺少关键组成部分 |
| `io` / `OSError` | 文件读取失败 |

CLI 退出码：

| 退出码 | 含义 |
| --- | --- |
| `0` | 转换成功 |
| `1` | 读取或转换失败 |
| `2` | 参数错误 |

## 11. 推荐使用场景

- 批量把 Office 文档、PDF、CSV 转成 Markdown。
- 构建 RAG / 知识库入库前的文档解析流程。
- 给大模型提供结构化、干净的 Markdown 上下文。
- 在 Node、Python、Rust 或浏览器端统一处理多种文档格式。

如果文档里有大量扫描图片、手写内容或图片型 PDF，需要额外接 OCR 服务；`anydoc` 本身只做本地结构化解析和文本提取。
