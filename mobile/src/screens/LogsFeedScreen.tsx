import { useMemo, useState } from 'react';
import {
  Alert,
  Pressable,
  RefreshControl,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { LogFeedCard } from '../components/LogFeedCard';
import type { MapLog, MapLogSource, PindPost, Place, TasteTag } from '../domain/types';
import { deletePost } from '../services/posts';
import { colors } from '../theme/colors';
import { PlaceDetailModal } from './PlaceDetailModal';

type FeedFilter = 'all' | MapLogSource;

type Props = {
  logs: MapLog[];
  places: Place[];
  tags: TasteTag[];
  onCreate: (place?: Place) => void;
  onEdit: (post: PindPost, place: Place) => void;
  onRefresh: () => Promise<void>;
};

export function LogsFeedScreen({ logs, places, tags, onCreate, onEdit, onRefresh }: Props) {
  const [filter, setFilter] = useState<FeedFilter>('all');
  const [refreshing, setRefreshing] = useState(false);
  const [selectedPlace, setSelectedPlace] = useState<Place | null>(null);
  const placesById = useMemo(() => new Map(places.map((place) => [place.id, place])), [places]);
  const visibleLogs = useMemo(
    () => logs.filter((log) => filter === 'all' || log.source === filter),
    [filter, logs],
  );
  const selectedPlaceLogs = selectedPlace ? logs.filter((log) => log.placeId === selectedPlace.id) : [];

  async function refresh() {
    setRefreshing(true);
    try {
      await onRefresh();
    } finally {
      setRefreshing(false);
    }
  }

  function confirmDelete(post: PindPost) {
    Alert.alert('Delete this log?', 'The post will be removed. Its visit record stays in your history.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => void remove(post),
      },
    ]);
  }

  async function remove(post: PindPost) {
    try {
      await deletePost(post);
      await onRefresh();
    } catch (caught) {
      Alert.alert('Could not delete', caught instanceof Error ? caught.message : 'Try again.');
    }
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <View>
          <Text style={styles.eyebrow}>PIND COMMUNITY</Text>
          <Text style={styles.title}>Taste logs</Text>
          <Text style={styles.subtitle}>Food memories from you, friends, and Pind.</Text>
        </View>
        <Pressable
          accessibilityLabel="Create post"
          onPress={() => onCreate()}
          style={styles.addButton}
        >
          <Text style={styles.addIcon}>＋</Text>
        </Pressable>
      </View>

      <View style={styles.filterRow}>
        <Filter active={filter === 'all'} label="All" onPress={() => setFilter('all')} />
        <Filter active={filter === 'mine'} label="Mine" onPress={() => setFilter('mine')} />
        <Filter active={filter === 'friend'} label="Friends" onPress={() => setFilter('friend')} />
        <Filter active={filter === 'default'} label="Pind" onPress={() => setFilter('default')} />
      </View>

      <ScrollView
        contentContainerStyle={[styles.content, visibleLogs.length === 0 && styles.emptyContent]}
        refreshControl={<RefreshControl onRefresh={() => void refresh()} refreshing={refreshing} tintColor={colors.coral} />}
        showsVerticalScrollIndicator={false}
      >
        {visibleLogs.length === 0 ? (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyEmoji}>📷</Text>
            <Text style={styles.emptyTitle}>No logs here yet</Text>
            <Text style={styles.emptyCopy}>Choose a real place, add a food photo, and share what it felt like.</Text>
            <Pressable onPress={() => onCreate()} style={styles.emptyButton}>
              <Text style={styles.emptyButtonText}>Create a log</Text>
            </Pressable>
          </View>
        ) : (
          visibleLogs.flatMap((log) => {
            const place = placesById.get(log.placeId);
            return place ? [
              <LogFeedCard
                key={log.id}
                log={log}
                onDelete={confirmDelete}
                onEdit={onEdit}
                onOpenPlace={setSelectedPlace}
                place={place}
                tags={tags}
              />,
            ] : [];
          })
        )}
      </ScrollView>

      <PlaceDetailModal
        logs={selectedPlaceLogs}
        onClose={() => setSelectedPlace(null)}
        onCreatePost={(place) => {
          setSelectedPlace(null);
          onCreate(place);
        }}
        place={selectedPlace}
        selectedCodes={new Set()}
        tags={tags}
      />
    </SafeAreaView>
  );
}

function Filter({ active, label, onPress }: { active: boolean; label: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" accessibilityState={{ selected: active }} onPress={onPress} style={[styles.filter, active && styles.filterActive]}>
      <Text style={[styles.filterText, active && styles.filterTextActive]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  header: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 18, paddingBottom: 13, paddingTop: 9 },
  eyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.4 },
  title: { color: colors.ink, fontSize: 30, fontWeight: '900', letterSpacing: -1, marginTop: 2 },
  subtitle: { color: colors.muted, fontSize: 11, marginTop: 3 },
  addButton: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 17, height: 46, justifyContent: 'center', width: 46 },
  addIcon: { color: colors.white, fontSize: 27 },
  filterRow: { flexDirection: 'row', gap: 7, paddingBottom: 12, paddingHorizontal: 18 },
  filter: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 999, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 9 },
  filterActive: { backgroundColor: colors.plum, borderColor: colors.plum },
  filterText: { color: colors.ink, fontSize: 11, fontWeight: '800' },
  filterTextActive: { color: colors.white },
  content: { gap: 17, padding: 15, paddingBottom: 28 },
  emptyContent: { flexGrow: 1, justifyContent: 'center' },
  emptyCard: { alignItems: 'center', backgroundColor: colors.card, borderRadius: 28, padding: 30 },
  emptyEmoji: { fontSize: 44 },
  emptyTitle: { color: colors.ink, fontSize: 24, fontWeight: '900', marginTop: 13 },
  emptyCopy: { color: colors.muted, fontSize: 13, lineHeight: 20, marginTop: 8, textAlign: 'center' },
  emptyButton: { backgroundColor: colors.plum, borderRadius: 16, marginTop: 21, paddingHorizontal: 20, paddingVertical: 13 },
  emptyButtonText: { color: colors.white, fontSize: 13, fontWeight: '900' },
});
