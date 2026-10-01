/// Bumped after every server write that My Page shows (saves, views, posts,
/// follows, likes, profile and taste edits). Screens that cache server data
/// refetch only when this moved since their last load.
int dataRevision = 0;

void markDataChanged() => dataRevision++;
