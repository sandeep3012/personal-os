import 'package:feature_documents/src/data/dao/document_dao.dart';
import 'package:feature_documents/src/data/mappers/document_mapper.dart';
import 'package:feature_documents/src/data/models/document_query_filter.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_page.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IDocumentRepository].
///
/// Pure orchestration: delegates all SQL to [DocumentDao] and all entity/row
/// conversion to [DocumentMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Notes' `NoteRepository`.
final class DocumentRepository implements IDocumentRepository {
  const DocumentRepository({
    required DocumentDao documentDao,
    required DocumentMapper documentMapper,
  })  : _documentDao = documentDao,
        _documentMapper = documentMapper;

  final DocumentDao _documentDao;
  final DocumentMapper _documentMapper;

  @override
  FutureResult<Document?> findById(
    DocumentId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _documentDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_documentMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Document>> findAll({required String workspaceId}) async {
    try {
      final rows = await _documentDao.findAll(workspaceId);
      return Result.success(rows.map(_documentMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Document>> findByStatus(
    DocumentStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _documentDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_documentMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<DocumentPage> search(DocumentQuery query) async {
    try {
      final filter = DocumentQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        titleContains: query.titleContains,
        typeContains: query.typeContains,
        tagContains: query.tagContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _documentDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(DocumentPage(
        items: result.items.map(_documentMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Document document) async {
    try {
      final row = _documentMapper.toRow(document);
      final alreadyExists = await _documentDao.exists(
        document.id.value,
        workspaceId: document.workspaceId,
      );
      if (alreadyExists) {
        await _documentDao.update(row);
      } else {
        await _documentDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    DocumentId id, {
    required String workspaceId,
  }) async {
    try {
      await _documentDao.softDelete(
        id.value,
        workspaceId: workspaceId,
        deletedAt: DateTime.now(),
      );
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  /// Translates any failure raised by the DAO or mapper into a
  /// [DocumentsException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return DocumentsException(
      message: 'Document repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
