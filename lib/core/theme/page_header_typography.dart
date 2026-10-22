/// 顶栏文字的共享规格；颜色由各页面传入，保留现有主题语义。
library;

import 'package:flutter/material.dart';

/// 后期扩展：全局调整顶栏字号时只修改此处，品牌入场动画独立保留。
abstract final class PageHeaderTypography {
  /// 页面名称统一使用 18px 粗体。
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  /// 副标题统一使用 12px 常规字重。
  static const subtitle = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
}
