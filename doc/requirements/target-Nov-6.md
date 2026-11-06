# 	Nov 6 需求说明

## 修复

本次主要是对网络计算器功能模块的UI界面进行修复，

请连接下面的 Stitch MCP 获取目标页面的完整设计数据，并严格按照设计稿修改当前 Flutter 页面。要求：

1. 首先调用 get_screen，获取截图、HTML/CSS、画布尺寸及相关设计数据。
2. 分析设计稿的布局结构、颜色、字体、间距、圆角、阴影和图标资源。
3. 对照现有 Flutter 页面，列出主要差异。
4. 在不破坏 Riverpod、MVVM、GoRouter 及业务逻辑的前提下修改 UI。
5. 不允许自行重新设计，不允许用默认 Material 样式代替设计稿。
6. 修改完成后运行 Flutter 应用，使用 ADB 获取实际页面截图。
7. 将实际截图与 Stitch 原图进行尺寸归一化、叠加及差异对比。
8. 根据差异继续修正，至少完成一次实际截图验证和差异修正循环。
9. 对于无法精确还原的内容，明确说明原因，不得直接忽略。

最终请输出修改文件、截图路径、主要视觉差异、修复结果和未解决问题。

注意：任务目标不是生成一个风格相似的页面，而是尽可能精确地复现 Stitch 设计稿。

## Stitch Instructions

Get the images and code for the following Stitch project's screens:

## Project

Title: Modular Utility Flutter App
ID: 2299265049139915786

## Screens:

1. 工具魔盒 - 网络计算器
   ID: b52e17b535f74d9fa3e9b51de5e4c96b

Use a utility like `curl -L` to download the hosted URLs.
