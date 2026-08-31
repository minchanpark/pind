import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  Pressable,
  RefreshControl,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import type { PindPost, Place, TasteTag } from '../domain/types';
import { deletePost, fetchMyPosts } from '../services/posts';
import { colors } from '../theme/colors';

type Props = {
  places: Place[];
  refreshToken: number;
  tags: TasteTag[];
  onBack: () => void;
  onCreate: (place: Place) => void;
  onEdit: (post: PindPost, place: Place) => void;
  onPostsChanged: () => void;
};

export function MyPostsScreen({ places, refreshToken, tags, onBack, onCreate, onEdit, onPostsChanged }: Props) {
  const [posts, setPosts] = useState<PindPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const placesById = useMemo(() => new Map(places.map((place) => [place.id, place])), [places]);
  const tagsByCode = useMemo(() => new Map(tags.map((tag) => [tag.code, tag])), [tags]);

  const load = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      setPosts(await fetchMyPosts());
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not load your posts.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load, refreshToken]);

  function confirmDelete(post: PindPost) {
    Alert.alert('Delete this log?', 'The post will be removed. Its visit record stays in your history.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => {
          void remove(post);
        },
      },
    ]);
  }

  async function remove(post: PindPost) {
    try {
      await deletePost(post);
      setPosts((current) => current.filter((candidate) => candidate.id !== post.id));
      onPostsChanged();
    } catch (caught) {
      Alert.alert('Could not delete', caught instanceof Error ? caught.message : 'Try again.');
    }
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <Pressable accessibilityLabel="Back to map" onPress={onBack} style={styles.backButton}>
          <Text style={styles.backIcon}>‹</Text>
        </Pressable>
        <View style={styles.headerCopy}>
          <Text style={styles.eyebrow}>MY PIND</Text>
          <Text style={styles.title}>Taste logs</Text>
        </View>
        <Pressable
          accessibilityLabel="Create post"
          disabled={places.length === 0}
          onPress={() => places[0] && onCreate(places[0])}
          style={styles.addButton}
        >
          <Text style={styles.addIcon}>＋</Text>
        </Pressable>
      </View>

      {loading ? (
        <View style={styles.centered}>
          <ActivityIndicator color={colors.coral} size="large" />
          <Text style={styles.centerHint}>Opening your taste diary…</Text>
        </View>
      ) : error ? (
        <View style={styles.centered}>
          <Text style={styles.errorTitle}>Your logs are paused.</Text>
          <Text style={styles.errorMessage}>{error}</Text>
          <Pressable onPress={() => void load()} style={styles.retryButton}>
            <Text style={styles.retryText}>Try again</Text>
          </Pressable>
        </View>
      ) : (
        <ScrollView
          contentContainerStyle={[styles.content, posts.length === 0 && styles.emptyContent]}
          refreshControl={<RefreshControl onRefresh={() => void load(true)} refreshing={refreshing} tintColor={colors.coral} />}
          showsVerticalScrollIndicator={false}
        >
          {posts.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyEmoji}>📍</Text>
              <Text style={styles.emptyTitle}>No taste logs yet</Text>
              <Text style={styles.emptyMessage}>Pick a place, add a dish photo, and remember it without stars.</Text>
              <Pressable disabled={places.length === 0} onPress={() => places[0] && onCreate(places[0])} style={styles.emptyButton}>
                <Text style={styles.emptyButtonText}>Create first log</Text>
              </Pressable>
            </View>
          ) : (
            posts.map((post) => {
              const place = placesById.get(post.placeId);
              return (
                <View key={post.id} style={styles.card}>
                  <Image source={{ uri: post.photoUrl }} style={styles.photo} />
                  <View style={styles.cardBody}>
                    <View style={styles.metaRow}>
                      <View style={styles.emojiBadge}>
                        <Text style={styles.emoji}>{post.emoji}</Text>
                      </View>
                      <View style={styles.metaCopy}>
                        <Text style={styles.menuName}>{post.menuName}</Text>
                        <Text style={styles.placeName}>{place?.nameEn ?? 'Unknown place'}</Text>
                      </View>
                      <Text style={styles.visibility}>{post.isPublic ? 'PUBLIC' : 'PRIVATE'}</Text>
                    </View>

                    <Text style={styles.body}>{post.body}</Text>
                    <View style={styles.tagRow}>
                      {post.tasteTagCodes.flatMap((code) => {
                        const tag = tagsByCode.get(code);
                        return tag ? (
                          <View key={code} style={styles.tag}>
                            <Text style={styles.tagText}>{tag.emoji} {tag.labelEn}</Text>
                          </View>
                        ) : [];
                      })}
                    </View>

                    <View style={styles.footerRow}>
                      <Text style={styles.date}>{formatDate(post.createdAt)}</Text>
                      <View style={styles.actions}>
                        <Pressable disabled={!place} onPress={() => place && onEdit(post, place)} style={styles.editButton}>
                          <Text style={styles.editText}>Edit</Text>
                        </Pressable>
                        <Pressable onPress={() => confirmDelete(post)} style={styles.deleteButton}>
                          <Text style={styles.deleteText}>Delete</Text>
                        </Pressable>
                      </View>
                    </View>
                  </View>
                </View>
              );
            })
          )}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value));
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  header: {
    alignItems: 'center',
    borderBottomColor: colors.line,
    borderBottomWidth: 1,
    flexDirection: 'row',
    minHeight: 72,
    paddingHorizontal: 16,
  },
  backButton: { alignItems: 'center', height: 44, justifyContent: 'center', width: 44 },
  backIcon: { color: colors.ink, fontSize: 38, lineHeight: 40 },
  headerCopy: { flex: 1, marginLeft: 8 },
  eyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.4 },
  title: { color: colors.ink, fontSize: 27, fontWeight: '900', letterSpacing: -0.8, marginTop: 1 },
  addButton: {
    alignItems: 'center',
    backgroundColor: colors.ink,
    borderRadius: 16,
    height: 44,
    justifyContent: 'center',
    width: 44,
  },
  addIcon: { color: colors.white, fontSize: 25, fontWeight: '400' },
  centered: { alignItems: 'center', flex: 1, justifyContent: 'center', padding: 28 },
  centerHint: { color: colors.muted, fontSize: 14, marginTop: 14 },
  errorTitle: { color: colors.ink, fontSize: 25, fontWeight: '900' },
  errorMessage: { color: colors.muted, fontSize: 14, lineHeight: 21, marginTop: 10, textAlign: 'center' },
  retryButton: { backgroundColor: colors.ink, borderRadius: 15, marginTop: 20, paddingHorizontal: 22, paddingVertical: 13 },
  retryText: { color: colors.white, fontSize: 14, fontWeight: '800' },
  content: { gap: 18, padding: 16, paddingBottom: 40 },
  emptyContent: { flexGrow: 1, justifyContent: 'center' },
  emptyCard: { alignItems: 'center', backgroundColor: colors.card, borderRadius: 28, padding: 28 },
  emptyEmoji: { fontSize: 46 },
  emptyTitle: { color: colors.ink, fontSize: 25, fontWeight: '900', marginTop: 15 },
  emptyMessage: { color: colors.muted, fontSize: 14, lineHeight: 21, marginTop: 9, textAlign: 'center' },
  emptyButton: { backgroundColor: colors.plum, borderRadius: 17, marginTop: 22, paddingHorizontal: 22, paddingVertical: 14 },
  emptyButtonText: { color: colors.white, fontSize: 14, fontWeight: '900' },
  card: { backgroundColor: colors.card, borderColor: colors.line, borderRadius: 26, borderWidth: 1, overflow: 'hidden' },
  photo: { backgroundColor: colors.line, height: 235, width: '100%' },
  cardBody: { padding: 17 },
  metaRow: { alignItems: 'center', flexDirection: 'row' },
  emojiBadge: { alignItems: 'center', backgroundColor: colors.coralSoft, borderRadius: 15, height: 48, justifyContent: 'center', width: 48 },
  emoji: { fontSize: 24 },
  metaCopy: { flex: 1, marginLeft: 11 },
  menuName: { color: colors.ink, fontSize: 19, fontWeight: '900' },
  placeName: { color: colors.muted, fontSize: 12, marginTop: 3 },
  visibility: { color: colors.plum, fontSize: 9, fontWeight: '900', letterSpacing: 0.8 },
  body: { color: colors.ink, fontSize: 15, lineHeight: 22, marginTop: 15 },
  tagRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, marginTop: 14 },
  tag: { backgroundColor: colors.plumSoft, borderRadius: 999, paddingHorizontal: 10, paddingVertical: 7 },
  tagText: { color: colors.plum, fontSize: 11, fontWeight: '700' },
  footerRow: { alignItems: 'center', borderTopColor: colors.line, borderTopWidth: 1, flexDirection: 'row', justifyContent: 'space-between', marginTop: 17, paddingTop: 14 },
  date: { color: colors.muted, fontSize: 11 },
  actions: { flexDirection: 'row', gap: 8 },
  editButton: { backgroundColor: colors.ink, borderRadius: 12, paddingHorizontal: 15, paddingVertical: 10 },
  editText: { color: colors.white, fontSize: 12, fontWeight: '800' },
  deleteButton: { backgroundColor: colors.coralSoft, borderRadius: 12, paddingHorizontal: 13, paddingVertical: 10 },
  deleteText: { color: colors.danger, fontSize: 12, fontWeight: '800' },
});
