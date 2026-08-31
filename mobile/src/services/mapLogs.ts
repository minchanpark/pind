import type { MapLog, PindPost } from '../domain/types';
import { supabase } from '../lib/supabase';
import { ensureWriterSession, fetchMyPosts, publicPhotoUrl } from './posts';

type FriendshipRow = {
  requester_id: string;
  addressee_id: string;
};

type ProfileRow = {
  id: string;
  display_name: string;
};

type PostRow = {
  id: number;
  author_id: string;
  place_id: number;
  menu_name: string;
  photo_path: string;
  emoji: string;
  body: string;
  created_at: string;
};

type PostTasteTagRow = {
  post_id: number;
  taste_tag_code: string;
};

type EditorialLogRow = {
  id: number;
  place_id: number;
  author_name: string;
  menu_name: string;
  photo_url: string;
  emoji: string;
  body: string;
  created_at: string;
};

type EditorialTasteTagRow = {
  editorial_log_id: number;
  taste_tag_code: string;
};

export async function fetchMapLogs(): Promise<MapLog[]> {
  const userId = await ensureWriterSession();
  const [myPosts, friendshipsResult, editorialsResult, editorialTagsResult] = await Promise.all([
    fetchMyPosts(),
    supabase.from('friendships').select('requester_id,addressee_id').eq('status', 'accepted'),
    supabase
      .from('editorial_logs')
      .select('id,place_id,author_name,menu_name,photo_url,emoji,body,created_at')
      .eq('is_published', true),
    supabase.from('editorial_log_taste_tags').select('editorial_log_id,taste_tag_code'),
  ]);

  if (friendshipsResult.error) throw new Error(friendshipsResult.error.message);
  if (editorialsResult.error) throw new Error(editorialsResult.error.message);
  if (editorialTagsResult.error) throw new Error(editorialTagsResult.error.message);

  const friendships = (friendshipsResult.data ?? []) as FriendshipRow[];
  const friendIds = [
    ...new Set(
      friendships.map((friendship) =>
        friendship.requester_id === userId ? friendship.addressee_id : friendship.requester_id,
      ),
    ),
  ];

  const friendLogs = await fetchFriendLogs(friendIds);
  const editorialTags = (editorialTagsResult.data ?? []) as EditorialTasteTagRow[];
  const defaultLogs = ((editorialsResult.data ?? []) as EditorialLogRow[]).map<MapLog>((row) => ({
    id: `default:${row.id}`,
    source: 'default',
    placeId: row.place_id,
    authorName: row.author_name,
    menuName: row.menu_name,
    photoUrl: row.photo_url,
    emoji: row.emoji,
    body: row.body,
    tasteTagCodes: editorialTags
      .filter((tag) => tag.editorial_log_id === row.id)
      .map((tag) => tag.taste_tag_code),
    createdAt: row.created_at,
  }));

  return [...myPosts.map(toMyMapLog), ...friendLogs, ...defaultLogs].sort(
    (left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt),
  );
}

async function fetchFriendLogs(friendIds: string[]): Promise<MapLog[]> {
  if (friendIds.length === 0) return [];

  const [postsResult, profilesResult] = await Promise.all([
    supabase
      .from('posts')
      .select('id,author_id,place_id,menu_name,photo_path,emoji,body,created_at')
      .in('author_id', friendIds)
      .eq('is_public', true),
    supabase.from('profiles').select('id,display_name').in('id', friendIds),
  ]);

  if (postsResult.error) throw new Error(postsResult.error.message);
  if (profilesResult.error) throw new Error(profilesResult.error.message);

  const posts = (postsResult.data ?? []) as PostRow[];
  if (posts.length === 0) return [];

  const tagsResult = await supabase
    .from('post_taste_tags')
    .select('post_id,taste_tag_code')
    .in(
      'post_id',
      posts.map((post) => post.id),
    );
  if (tagsResult.error) throw new Error(tagsResult.error.message);

  const profilesById = new Map(
    ((profilesResult.data ?? []) as ProfileRow[]).map((profile) => [profile.id, profile.display_name]),
  );
  const tags = (tagsResult.data ?? []) as PostTasteTagRow[];

  return posts.map((row) => ({
    id: `post:${row.id}`,
    source: 'friend',
    placeId: row.place_id,
    authorName: profilesById.get(row.author_id) ?? 'Pind friend',
    menuName: row.menu_name,
    photoUrl: publicPhotoUrl(row.photo_path),
    emoji: row.emoji,
    body: row.body,
    tasteTagCodes: tags.filter((tag) => tag.post_id === row.id).map((tag) => tag.taste_tag_code),
    createdAt: row.created_at,
  }));
}

function toMyMapLog(post: PindPost): MapLog {
  return {
    id: `post:${post.id}`,
    source: 'mine',
    placeId: post.placeId,
    authorName: 'You',
    menuName: post.menuName,
    photoUrl: post.photoUrl,
    emoji: post.emoji,
    body: post.body,
    tasteTagCodes: post.tasteTagCodes,
    createdAt: post.createdAt,
    post,
  };
}
