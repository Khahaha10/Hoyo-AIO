import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';

abstract interface class NotesRepository {
  Future<NoteResult?> cached(SavedRole role);

  Future<NoteResult> refresh(SavedRole role);
}
