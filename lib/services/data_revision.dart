import 'dart:async';

import '../model/profile_model.dart';

/// Bumped after every server write that My Page shows (saves, views, posts,
/// follows, likes, profile and taste edits). Screens that cache server data
/// refetch only when this moved since their last load.
int dataRevision = 0;

void markDataChanged() => dataRevision++;

/// My profile right after I edit it (photo, name, bio). Screens that show my
/// name or photo inside other data (feed posts) patch it in place.
final myProfileEdits = StreamController<UserProfile>.broadcast();
