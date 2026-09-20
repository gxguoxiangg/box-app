/// Wiki 条目草稿模型测试。
library;

import 'package:demo1/features/article/models/article_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('总览编辑应回写结构化字段和关键词', () {
    const ArticleDraft draft = ArticleDraft(externalKey: 'item:test');
    final ArticleDraft updated = draft.applyMarkdownOverview('''
# 打印机离线

## 具体描述
无法连接打印机

## 产生原因
网络中断

## 解决方案
1. 检查网线

## 复盘
记录设备地址

## 关键字
- 打印机
- 网络
''');

    expect(updated.question, '打印机离线');
    expect(updated.description, '无法连接打印机');
    expect(updated.causes, '网络中断');
    expect(updated.solutions, '1. 检查网线');
    expect(updated.review, '记录设备地址');
    expect(updated.keywords, <String>['打印机', '网络']);
  });

  test('提交 JSON 应包含 Markdown 关键词和图片引用', () {
    const ArticleDraft draft = ArticleDraft(
      externalKey: 'item:test',
      question: '打印机离线',
      description: '无法连接',
      keywords: <String>['打印机', '网络'],
      images: <DraftImage>[
        DraftImage(
          imageId: 43,
          section: 'description',
          url: '/media/43.png',
          altText: 'photo.jpg',
        ),
      ],
    );

    final Map<String, dynamic> json = draft.toItemJson();
    expect(json['external_key'], 'item:test');
    expect(json['keywords'], '- 打印机\n- 网络');
    expect(json['keywords_list'], <String>['打印机', '网络']);
    expect((json['images'] as List<dynamic>).single, <String, dynamic>{
      'image_id': 43,
      'section': 'description',
      'alt_text': 'photo.jpg',
      'position': 0,
    });
  });
}
