import { supabase } from '../lib/supabase';
import type { PindPost } from '../domain/types';

const postMediaBucket = 'post-media';

type PostRow = {
  id: number;
  author_id: string;
  place_id: number;
  menu_name: string;
  photo_path: string;
  emoji: string;
  body: string;
  is_public: boolean;
  created_at: string;
  updated_at: string;
};

type PostTasteTagRow = {
  post_id: number;
  taste_tag_code: string;
};

export type LocalPostPhoto = {
  uri: string;
  mimeType: string | null;
  fileName: string | null;
};

export type SavePostInput = {
  post?: PindPost;
  placeId: number;
  menuName: string;
  photo: LocalPostPhoto | null;
  emoji: string;
  body: string;
  tasteTagCodes: string[];
  isPublic: boolean;
};

export async function ensureWriterSession(): Promise<string> {
  const sessionResult = await supabase.auth.getSession();
  if (sessionResult.error) throw new Error(sessionResult.error.message);

  if (sessionResult.data.session) {
    return sessionResult.data.session.user.id;
  }

  const signInResult = await supabase.auth.signInAnonymously();
  if (signInResult.error) {
    throw new Error(`Writing is not available yet: ${signInResult.error.message}`);
  }

  if (!signInResult.data.user) {
    throw new Error('Supabase did not create a writer session.');
  }

  return signInResult.data.user.id;
}

export async function fetchMyPosts(): Promise<PindPost[]> {
  const userId = await ensureWriterSession();
  return fetchPostsForOwner(userId);
}

export async function savePost(input: SavePostInput): Promise<void> {
  const userId = await ensureWriterSession();
  const normalizedTagCodes = [...new Set(input.tasteTagCodes)];
  let photoPath = input.post?.photoPath ?? null;
  let uploadedPath: string | null = null;

  if (input.photo) {
    uploadedPath = await uploadPhoto(userId, input.photo);
    photoPath = uploadedPath;
  }

  if (!photoPath) {
    throw new Error('Choose a food photo before posting.');
  }

  const parameters = {
    p_place_id: input.placeId,
    p_menu_name: input.menuName.trim(),
    p_photo_path: photoPath,
    p_emoji: input.emoji,
    p_body: input.body.trim(),
    p_taste_tag_codes: normalizedTagCodes,
    p_is_public: input.isPublic,
  };

  const result = input.post
    ? await supabase.rpc('update_post', { p_post_id: input.post.id, ...parameters })
    : await supabase.rpc('create_post', parameters);

  if (result.error) {
    if (uploadedPath) await removePhoto(uploadedPath);
    throw new Error(result.error.message);
  }

  if (uploadedPath && input.post?.photoPath && uploadedPath !== input.post.photoPath) {
    await removePhoto(input.post.photoPath);
  }
}

export async function deletePost(post: PindPost): Promise<void> {
  await ensureWriterSession();
  const result = await supabase.from('posts').delete().eq('id', post.id).select('id').maybeSingle();

  if (result.error) throw new Error(result.error.message);
  if (!result.data) throw new Error('Post not found or you do not own it.');

  await removePhoto(post.photoPath);
}

async function fetchPostsForOwner(userId: string): Promise<PindPost[]> {
  const postsResult = await supabase
    .from('posts')
    .select('id,author_id,place_id,menu_name,photo_path,emoji,body,is_public,created_at,updated_at')
    .eq('author_id', userId)
    .order('created_at', { ascending: false });

  if (postsResult.error) throw new Error(postsResult.error.message);

  const rows = (postsResult.data ?? []) as PostRow[];
  if (rows.length === 0) return [];

  const linksResult = await supabase
    .from('post_taste_tags')
    .select('post_id,taste_tag_code')
    .in(
      'post_id',
      rows.map((row) => row.id),
    );

  if (linksResult.error) throw new Error(linksResult.error.message);
  const links = (linksResult.data ?? []) as PostTasteTagRow[];

  return rows.map((row) => ({
    id: row.id,
    authorId: row.author_id,
    placeId: row.place_id,
    menuName: row.menu_name,
    photoPath: row.photo_path,
    photoUrl: publicPhotoUrl(row.photo_path),
    emoji: row.emoji,
    body: row.body,
    isPublic: row.is_public,
    tasteTagCodes: links.filter((link) => link.post_id === row.id).map((link) => link.taste_tag_code),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }));
}

async function uploadPhoto(userId: string, photo: LocalPostPhoto): Promise<string> {
  const response = await fetch(photo.uri);
  if (!response.ok) throw new Error('Could not read the selected photo.');

  const contentType = supportedMimeType(photo.mimeType);
  const extension = fileExtension(photo.fileName, contentType);
  const uniquePart = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  const path = `${userId}/${uniquePart}.${extension}`;
  const uploadResult = await supabase.storage.from(postMediaBucket).upload(path, await response.arrayBuffer(), {
    contentType,
    upsert: false,
  });

  if (uploadResult.error) throw new Error(uploadResult.error.message);
  return uploadResult.data.path;
}

async function removePhoto(path: string): Promise<void> {
  const result = await supabase.storage.from(postMediaBucket).remove([path]);
  if (result.error) {
    console.warn(`Could not remove post photo ${path}: ${result.error.message}`);
  }
}

export function publicPhotoUrl(path: string): string {
  return supabase.storage.from(postMediaBucket).getPublicUrl(path).data.publicUrl;
}

function supportedMimeType(mimeType: string | null): string {
  const supported = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']);
  return mimeType && supported.has(mimeType) ? mimeType : 'image/jpeg';
}

function fileExtension(fileName: string | null, mimeType: string): string {
  const fromName = fileName?.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '');
  if (fromName && ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].includes(fromName)) return fromName;

  return {
    'image/png': 'png',
    'image/webp': 'webp',
    'image/heic': 'heic',
    'image/heif': 'heif',
  }[mimeType] ?? 'jpg';
}
