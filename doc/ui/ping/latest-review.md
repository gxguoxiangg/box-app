# 最新三页 Stitch 复核

已调用 get_screen/download_file 重新获取首页、结果及运行中三页，资源为 latest-home/result/running.html 和 jpg。

主要差异：运行状态缺少进度、采样和实时说明；缺少原字体与虚线边框；图表无渐变；运行时可导出。已接入真实进度和统计、运行时禁用导出、终止按钮、IBM Plex Sans三个字重及许可证、虚线边框、图表渐变、历史计数及清空图标。

ADB设备 emulator-5554，780×1768、320dpi。new-home-v1、new-running-v1/v2、new-result-v1 是实际截图。裁掉104px状态栏与48px导航区，宽度等比缩至390px，生成对应overlay和diff。运行中第一轮发现摘要卡过高及发送说明换行，修正状态/RTT同行、地址下进度条和说明文字后重拍new-running-v2。

用户已确认修复原图排版异常并增加图片导出。导出面板按HTML补齐28px顶部圆角、拖动条、18px标题、关闭按钮和分隔线。完整结果使用RepaintBoundary生成PNG，保存通过系统文件选择器，分享通过系统分享面板。运行中及生成图片期间禁用导出，重测在导出期间禁用，取消保存不报成功。

ADB实际验证：保存生成的PNG到模拟器Downloads，拉取为exported-report.png；系统分享面板成功显示图片预览（export-system-share.png）。面板截图export-sheet.png→export-sheet-final.png记录第二轮样式修正。

已通过11项Ping测试（含320px明暗主题导出面板打开/取消、运行时禁用导出），模块静态分析无问题。

限制：模拟器没有微信，未验证微信内发送；保存到用户选择的本地目录，未直接写入系统相册。Material Symbols原字体仍未打包，部分图标为Flutter对应图标；IBM Plex Sans不含中文字形，中文由系统回退。设计中的预测曲线、网关别名和优良评价不作为真实测量数据。真实探测全丢包，不能用这些截图验证成功曲线的像素匹配。尚未完成所有多目标长页面逐段对比，不声称逐像素1:1验收。
