/// Wiki 条目编辑器 ViewModel。
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/models/auth_session.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../data/article_submission_repository.dart';
import '../models/article_draft.dart';
import '../models/article_submission.dart';

/// 条目编辑器状态。
class ArticleDraftState {
  final ArticleDraft draft;
  final bool isUploading;
  final bool isSubmitting;
  final String? errorMessage;

  const ArticleDraftState({
    required this.draft,
    this.isUploading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  ArticleDraftState copyWith({
    ArticleDraft? draft,
    bool? isUploading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ArticleDraftState(
      draft: draft ?? this.draft,
      isUploading: isUploading ?? this.isUploading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// 管理草稿、图片上传与最终提交。
class ArticleDraftController extends Notifier<ArticleDraftState> {
  @override
  ArticleDraftState build() => ArticleDraftState(draft: _newDraft());

  ArticleDraft _newDraft() {
    final int randomPart = Random.secure().nextInt(1 << 32);
    return ArticleDraft(
      externalKey:
          'item:flutter-${DateTime.now().microsecondsSinceEpoch}-$randomPart',
    );
  }

  /// 更新一个文字小节。
  void updateText(DraftSection section, String value) {
    state = state.copyWith(
      draft: state.draft.updateText(section, value),
      clearError: true,
    );
  }

  /// 从可编辑总览回写全部结构化字段。
  void updateOverview(String markdown) {
    state = state.copyWith(
      draft: state.draft.applyMarkdownOverview(markdown),
      clearError: true,
    );
  }

  /// 切换一个关键词的选中状态。
  void toggleKeyword(String keyword) {
    final List<String> keywords = List<String>.from(state.draft.keywords);
    keywords.contains(keyword) ? keywords.remove(keyword) : keywords.add(keyword);
    state = state.copyWith(
      draft: state.draft.copyWith(keywords: keywords),
      clearError: true,
    );
  }

  /// 上传图片并把服务端返回的引用加入草稿。
  Future<DraftImage?> uploadImage({
    required List<int> bytes,
    required String filename,
    required DraftSection section,
  }) async {
    final AuthSession? session =
        ref.read(authSessionProvider.notifier).validSession;
    if (session == null) {
      state = state.copyWith(errorMessage: '登录状态已过期，请重新登录');
      return null;
    }

    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final DraftImage image =
          await ref.read(articleSubmissionRepositoryProvider).uploadImage(
                token: session.accessToken,
                bytes: bytes,
                filename: filename,
                section: section,
              );
      state = state.copyWith(
        isUploading: false,
        draft: state.draft.copyWith(
          images: <DraftImage>[...state.draft.images, image],
        ),
      );
      return image;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        ref.read(authSessionProvider.notifier).clear();
      }
      state = state.copyWith(
        isUploading: false,
        errorMessage: error.message,
      );
      return null;
    }
  }

  /// 提交当前草稿，成功时返回新增条目 ID。
  Future<ArticleSubmission?> submit() async {
    if (state.draft.question.trim().isEmpty) {
      state = state.copyWith(errorMessage: '请先填写问题标题');
      return null;
    }
    final AuthSession? session =
        ref.read(authSessionProvider.notifier).validSession;
    if (session == null) {
      state = state.copyWith(errorMessage: '登录状态已过期，请重新登录');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final ArticleSubmission result =
          await ref.read(articleSubmissionRepositoryProvider).submit(
                token: session.accessToken,
                draft: state.draft,
              );
      state = state.copyWith(isSubmitting: false);
      return result;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        ref.read(authSessionProvider.notifier).clear();
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '提交失败，请稍后再试',
      );
      return null;
    }
  }

  /// 删除当前内存草稿并生成新的业务标识。
  void clear() => state = ArticleDraftState(draft: _newDraft());
}

/// 条目编辑器 Provider。
final articleDraftControllerProvider =
    NotifierProvider<ArticleDraftController, ArticleDraftState>(
  ArticleDraftController.new,
);

/// 后期扩展：可将上传中图片单独建模，提供进度、重试与孤立图片清理提示。
