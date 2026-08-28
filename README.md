# 神州万象 · China Atlas

沉浸式中国地理文化百科应用，以 Apple 液态玻璃（Liquid Glass）设计语言重构，融合 iOS 与 macOS 交互规范。

## 特性

- 🗺️ **交互式 SVG 地图**：34 省级行政区可点击探索，精确省界
- 📖 **省份百科**：6 大板块（地缘/历史/文化/世遗/城市/美食），滑动卡片式阅读
- 🏙️ **城市浏览**：358 座城市简介，底部 Sheet 弹出式详情
- 🖼️ **摄影图库**：340 张精选风光，按省份筛选，瀑布流布局
- 🔍 **全局搜索**：省份、城市、景点快速定位
- 📱 **响应式适配**：桌面端与移动端完美适配，iPhone 安全区域兼容
- ✨ **液态玻璃设计**：全局毛玻璃材质、动态渐变背景、弹性动画

## 技术栈

- 纯前端单文件 HTML（内联 CSS + JS）
- 36 张真实摄影风格图片 base64 内嵌，完全离线可用
- 无任何外部依赖，双击即可运行

## 快速开始

直接双击 `神州万象.html` 即可在浏览器中打开，无需服务器、无需联网。

## 项目结构

```
.
├── 神州万象.html          # 主交付文件（单文件，9.4MB，图片全内嵌）
├── build_html_ios.py      # HTML 构建脚本
├── data_merged.js         # 合并后的数据文件
├── images/gallery/        # 36 张图库源图
├── README.md
└── .gitignore
```

## 构建

如需重新生成 HTML：

```bash
python build_html_ios.py
```

## 设计说明

采用 Apple Design 理念：
- **液态玻璃**：`backdrop-filter: blur + saturate`，半透明材质 + 内高光 + 外投影
- **弹性动画**：spring 缓动曲线，中断可重定向
- **空间层次**：浮起底栏、底部 Sheet、模态弹窗，z-index 分层清晰
- **排版**：SF Pro 字体栈，光学字距，大标题收紧 tracking

## 浏览器兼容

Chrome / Edge / Firefox / Safari 最新版本，需支持 `backdrop-filter`。
