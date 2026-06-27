# Dolphin 文档预览结论

目标：Dolphin 右侧信息面板选中文件后，尽量像图片一样自动显示 docx、xlsx、pdf、txt、md
等文件内容。

## 结论

Dolphin 23.08 的右侧信息面板不是完整文档阅读器。它调用 KDE 的 `KIO::PreviewJob` 生成
缩略图，并在面板里显示单个预览图；图片看起来像“内容预览”，但文档通常只能显示第一页、
封面或文本开头，不能在右侧面板内像 Okular/LibreOffice 那样翻页、滚动、搜索或编辑。

本机可实现的范围：

- `pdf`：已有 `gsthumbnail.so`，声明支持 `application/pdf`。
- `docx/xlsx/pptx`：已有 `opendocumentthumbnail.so`，声明支持 Office OpenXML MIME；
  但它不是调用 LibreOffice 渲染第一页，而是读取文档包里已有的内嵌缩略图。很多 Word/Excel
  文件没有保存这张缩略图，因此会没有右侧内容预览。
- `txt`：已有 `textthumbnail.so`，声明支持 `text/plain`。
- `md`：系统识别为 `text/markdown`，但 Dolphin 23.08 本机的 `textthumbnail.so`
  元数据只声明 `text/plain`，没有声明 `text/markdown`；`markdownpart` 也只是 KPart
  阅读组件，不是 Dolphin 信息面板 thumbnailer。因此 `.md` 不能依赖当前预览链路显示内容。

想要真正查看完整内容，应让 Dolphin 双击或回车打开外部应用：

- PDF：`okular`
- docx/xlsx：`libreoffice-writer`、`libreoffice-calc`
- Markdown：`kate`、`marktext`、`typora`，或安装 `markdownpart` 供支持 KPart 的应用使用

这些外部应用只影响双击/回车打开文件，不改变 Dolphin 右侧信息面板的预览能力。

## 本机状态

已确认本机：

- Dolphin：`23.08.5`
- Dolphin 缩略图链路依赖：`kio-extras`、`kdegraphics-thumbnailers`、`ffmpegthumbs`
- Dolphin 用户配置已写入 `PreviewSettings/Plugins`，显式启用已安装的 KDE thumbnailer。

## 应用配置

运行：

```bash
./scripts/dolphin-document-preview.sh
```

脚本会：

- 检查关键 thumbnailer 插件和 MIME 声明。
- 写入用户级 Dolphin 预览大小限制。
- 写入 `PreviewSettings/Plugins`，显式启用已安装的 KDE thumbnailer。
- 为全局视图属性打开预览。
- 尝试打开右侧信息面板的预览开关配置。

如果要顺手安装 Dolphin 缩略图相关包：

```bash
./scripts/dolphin-document-preview.sh --install
```

`--install` 只安装 Dolphin 缩略图相关包：`dolphin`、`kio-extras`、
`kdegraphics-thumbnailers`、`ffmpegthumbs`。它不会安装 `okular`、
`libreoffice-writer`、`libreoffice-calc`、`markdownpart`。

需要输入 sudo 密码。安装后重新打开 Dolphin；若旧缩略图缓存影响显示，可删除
`~/.cache/thumbnails/` 后重新打开相关目录。

## 手动检查

在 Dolphin 中：

1. 按 `F11` 显示右侧信息面板。
2. 右键右侧信息面板，确认 `Preview` / `预览` 已勾选。
3. 工具栏启用 `Show Previews` / `显示预览`。
4. 进入 `Settings -> Configure Dolphin -> General -> Previews`，确认文档、文本、PDF 等预览项已勾选。

若目标是“像 Windows 资源管理器预览窗格一样直接阅读 docx/xlsx/pdf/md”，Dolphin 23.08
本身不支持；需要换支持嵌入阅读器的文件管理器/插件，或接受双击用 Okular/LibreOffice/Kate
打开。安装 `okular`、`libreoffice-*`、`markdownpart` 可以改善双击打开体验，但不会把
Dolphin 右侧信息面板变成完整阅读器。
