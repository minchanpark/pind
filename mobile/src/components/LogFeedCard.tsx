import { Image, Pressable, StyleSheet, Text, View } from 'react-native';

import type { MapLog, PindPost, Place, TasteTag } from '../domain/types';
import { colors } from '../theme/colors';

type Props = {
  log: MapLog;
  place: Place;
  tags: TasteTag[];
  compact?: boolean;
  onDelete?: (post: PindPost) => void;
  onEdit?: (post: PindPost, place: Place) => void;
  onOpenPlace?: (place: Place) => void;
};

export function LogFeedCard({ log, place, tags, compact = false, onDelete, onEdit, onOpenPlace }: Props) {
  const source = sourcePresentation(log.source);
  const tagsByCode = new Map(tags.map((tag) => [tag.code, tag]));
  const canManage = log.source === 'mine' && Boolean(log.post);

  return (
    <View style={[styles.card, compact && styles.compactCard]}>
      <View style={styles.authorRow}>
        <View style={[styles.avatar, { backgroundColor: source.color }]}>
          <Text style={styles.avatarText}>{source.symbol}</Text>
        </View>
        <View style={styles.authorCopy}>
          <Text style={styles.author}>{log.authorName}</Text>
          <Text style={styles.source}>{source.label} · {formatDate(log.createdAt)}</Text>
        </View>
        {canManage ? <Text style={styles.owned}>YOURS</Text> : null}
      </View>

      <Pressable accessibilityLabel={`Open ${place.nameEn}`} disabled={!onOpenPlace} onPress={() => onOpenPlace?.(place)}>
        <Image source={{ uri: log.photoUrl }} style={[styles.photo, compact && styles.compactPhoto]} />
        <View style={styles.emojiBadge}><Text style={styles.emoji}>{log.emoji}</Text></View>
      </Pressable>

      <View style={styles.body}>
        <Pressable disabled={!onOpenPlace} onPress={() => onOpenPlace?.(place)}>
          <Text style={styles.placeName}>{place.nameEn}</Text>
          <Text style={styles.menuName}>{log.menuName}</Text>
        </Pressable>
        <Text style={styles.copy}>{log.body}</Text>
        <View style={styles.tags}>
          {log.tasteTagCodes.flatMap((code) => {
            const tag = tagsByCode.get(code);
            return tag ? <View key={code} style={styles.tag}><Text style={styles.tagText}>{tag.emoji} {tag.labelEn}</Text></View> : [];
          })}
        </View>

        {canManage && log.post && (onEdit || onDelete) ? (
          <View style={styles.actions}>
            {onEdit ? <Pressable onPress={() => onEdit(log.post!, place)} style={styles.editButton}><Text style={styles.editText}>Edit</Text></Pressable> : null}
            {onDelete ? <Pressable onPress={() => onDelete(log.post!)} style={styles.deleteButton}><Text style={styles.deleteText}>Delete</Text></Pressable> : null}
          </View>
        ) : null}
      </View>
    </View>
  );
}

export function sourcePresentation(source: MapLog['source']) {
  return {
    mine: { color: colors.coral, label: 'My log', symbol: 'ME' },
    friend: { color: colors.plum, label: 'Friend log', symbol: 'FR' },
    default: { color: colors.success, label: 'Pind pick', symbol: 'P' },
  }[source];
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric' }).format(new Date(value));
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.card, borderColor: colors.line, borderRadius: 26, borderWidth: 1, overflow: 'hidden' },
  compactCard: { borderRadius: 20 },
  authorRow: { alignItems: 'center', flexDirection: 'row', padding: 14 },
  avatar: { alignItems: 'center', borderRadius: 18, height: 36, justifyContent: 'center', width: 36 },
  avatarText: { color: colors.white, fontSize: 9, fontWeight: '900' },
  authorCopy: { flex: 1, marginLeft: 10 },
  author: { color: colors.ink, fontSize: 14, fontWeight: '900' },
  source: { color: colors.muted, fontSize: 10, marginTop: 2 },
  owned: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 0.8 },
  photo: { backgroundColor: colors.line, height: 285, width: '100%' },
  compactPhoto: { height: 210 },
  emojiBadge: { alignItems: 'center', backgroundColor: colors.white, borderRadius: 24, bottom: 14, height: 48, justifyContent: 'center', position: 'absolute', right: 14, shadowColor: colors.black, shadowOpacity: 0.16, shadowRadius: 8, width: 48 },
  emoji: { fontSize: 25 },
  body: { padding: 16 },
  placeName: { color: colors.coral, fontSize: 11, fontWeight: '900', letterSpacing: 0.5, textTransform: 'uppercase' },
  menuName: { color: colors.ink, fontSize: 21, fontWeight: '900', marginTop: 4 },
  copy: { color: colors.ink, fontSize: 14, lineHeight: 21, marginTop: 12 },
  tags: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, marginTop: 13 },
  tag: { backgroundColor: colors.plumSoft, borderRadius: 999, paddingHorizontal: 10, paddingVertical: 7 },
  tagText: { color: colors.plum, fontSize: 10, fontWeight: '800' },
  actions: { borderTopColor: colors.line, borderTopWidth: 1, flexDirection: 'row', gap: 8, justifyContent: 'flex-end', marginTop: 16, paddingTop: 13 },
  editButton: { backgroundColor: colors.ink, borderRadius: 12, paddingHorizontal: 17, paddingVertical: 10 },
  editText: { color: colors.white, fontSize: 11, fontWeight: '900' },
  deleteButton: { backgroundColor: colors.coralSoft, borderRadius: 12, paddingHorizontal: 15, paddingVertical: 10 },
  deleteText: { color: colors.danger, fontSize: 11, fontWeight: '900' },
});
