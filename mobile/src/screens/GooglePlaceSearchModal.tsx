import { useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { GoogleMapsAttribution } from '../components/GoogleMapsAttribution';
import { PlaceImage } from '../components/PlaceImage';
import type { GooglePlaceCandidate, Place } from '../domain/types';
import { resolveGooglePlace, searchGooglePlaces } from '../services/googlePlaces';
import { colors } from '../theme/colors';

type Props = {
  visible: boolean;
  onClose: () => void;
  onSelect: (place: Place) => void;
};

export function GooglePlaceSearchModal({ visible, onClose, onSelect }: Props) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<GooglePlaceCandidate[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [resolvingId, setResolvingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function search() {
    const normalized = query.trim();
    if (normalized.length < 2 || loading) return;
    setLoading(true);
    setError(null);
    setSearched(true);
    try {
      setResults(await searchGooglePlaces(normalized));
    } catch (caught) {
      setResults([]);
      setError(caught instanceof Error ? caught.message : 'Could not search Google Maps.');
    } finally {
      setLoading(false);
    }
  }

  async function select(candidate: GooglePlaceCandidate) {
    if (resolvingId) return;
    setResolvingId(candidate.externalPlaceId);
    setError(null);
    try {
      onSelect(await resolveGooglePlace(candidate.externalPlaceId));
      onClose();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not select this place.');
    } finally {
      setResolvingId(null);
    }
  }

  return (
    <Modal animationType="slide" onRequestClose={onClose} presentationStyle="pageSheet" visible={visible}>
      <SafeAreaView style={styles.safeArea}>
        <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.safeArea}>
          <View style={styles.header}>
            <View>
              <Text style={styles.eyebrow}>REAL PLACE SEARCH</Text>
              <Text style={styles.title}>Find a restaurant</Text>
            </View>
            <Pressable accessibilityLabel="Close place search" onPress={onClose} style={styles.closeButton}>
              <Text style={styles.closeIcon}>×</Text>
            </Pressable>
          </View>

          <View style={styles.searchRow}>
            <TextInput
              accessibilityLabel="Search restaurants and cafes"
              autoCapitalize="none"
              autoCorrect={false}
              onChangeText={setQuery}
              onSubmitEditing={() => void search()}
              placeholder="Restaurant, cafe, or bakery in Korea"
              placeholderTextColor={colors.muted}
              returnKeyType="search"
              style={styles.input}
              value={query}
            />
            <Pressable
              accessibilityRole="button"
              disabled={query.trim().length < 2 || loading}
              onPress={() => void search()}
              style={[styles.searchButton, (query.trim().length < 2 || loading) && styles.searchButtonDisabled]}
            >
              {loading ? <ActivityIndicator color={colors.white} /> : <Text style={styles.searchText}>Search</Text>}
            </Pressable>
          </View>

          {error ? <Text style={styles.error}>{error}</Text> : null}

          <FlatList
            contentContainerStyle={[styles.list, results.length === 0 && styles.emptyList]}
            data={results}
            keyboardShouldPersistTaps="handled"
            keyExtractor={(item) => item.externalPlaceId}
            ListEmptyComponent={
              loading ? null : (
                <View style={styles.emptyCard}>
                  <Text style={styles.emptyIcon}>⌖</Text>
                  <Text style={styles.emptyTitle}>{searched ? 'No food places found' : 'Search real places across Korea'}</Text>
                  <Text style={styles.emptyMessage}>
                    {searched ? 'Try a venue name, neighborhood, or food type.' : 'Choose a Google Maps result, then add it to your MyLog.'}
                  </Text>
                </View>
              )
            }
            renderItem={({ item }) => (
              <View style={styles.card}>
                <PlaceImage imageStyle={styles.image} uri={item.heroImageUrl} />
                <View style={styles.cardBody}>
                  <Text numberOfLines={1} style={styles.placeName}>{item.name}</Text>
                  <Text style={styles.category}>{item.category}</Text>
                  <Text numberOfLines={2} style={styles.address}>{item.address}</Text>
                  <GoogleMapsAttribution
                    googleMapsUri={item.googleMapsUri}
                    photoAttributions={item.photoAttributions}
                    photoGoogleMapsUri={item.photoGoogleMapsUri}
                  />
                  <Pressable
                    accessibilityRole="button"
                    disabled={Boolean(resolvingId)}
                    onPress={() => void select(item)}
                    style={styles.selectButton}
                  >
                    {resolvingId === item.externalPlaceId ? (
                      <ActivityIndicator color={colors.white} size="small" />
                    ) : (
                      <Text style={styles.selectText}>Use this place</Text>
                    )}
                  </Pressable>
                </View>
              </View>
            )}
          />

          <Text style={styles.rankingNote}>Google Maps results primarily consider relevance, distance, and prominence.</Text>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  header: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between', padding: 18, paddingBottom: 12 },
  eyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.3 },
  title: { color: colors.ink, fontSize: 27, fontWeight: '900', letterSpacing: -0.8, marginTop: 3 },
  closeButton: { alignItems: 'center', backgroundColor: colors.white, borderRadius: 19, height: 38, justifyContent: 'center', width: 38 },
  closeIcon: { color: colors.ink, fontSize: 27, lineHeight: 30 },
  searchRow: { flexDirection: 'row', gap: 9, paddingHorizontal: 18, paddingBottom: 8 },
  input: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 16, borderWidth: 1, color: colors.ink, flex: 1, fontSize: 14, minHeight: 52, paddingHorizontal: 15 },
  searchButton: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 16, justifyContent: 'center', minWidth: 79, paddingHorizontal: 14 },
  searchButtonDisabled: { backgroundColor: colors.line },
  searchText: { color: colors.white, fontSize: 13, fontWeight: '900' },
  error: { color: colors.danger, fontSize: 12, lineHeight: 18, paddingHorizontal: 20, paddingTop: 7 },
  list: { gap: 12, padding: 18, paddingTop: 12 },
  emptyList: { flexGrow: 1, justifyContent: 'center' },
  emptyCard: { alignItems: 'center', paddingHorizontal: 32 },
  emptyIcon: { color: colors.coral, fontSize: 43 },
  emptyTitle: { color: colors.ink, fontSize: 21, fontWeight: '900', marginTop: 7 },
  emptyMessage: { color: colors.muted, fontSize: 13, lineHeight: 20, marginTop: 7, textAlign: 'center' },
  card: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 22, borderWidth: 1, overflow: 'hidden' },
  image: { height: 166, width: '100%' },
  cardBody: { padding: 15 },
  placeName: { color: colors.ink, fontSize: 19, fontWeight: '900' },
  category: { color: colors.coral, fontSize: 10, fontWeight: '900', letterSpacing: 0.7, marginTop: 4, textTransform: 'uppercase' },
  address: { color: colors.muted, fontSize: 12, lineHeight: 17, marginTop: 7 },
  selectButton: { alignItems: 'center', backgroundColor: colors.plum, borderRadius: 14, justifyContent: 'center', marginTop: 4, minHeight: 46 },
  selectText: { color: colors.white, fontSize: 13, fontWeight: '900' },
  rankingNote: { color: colors.muted, fontSize: 10, lineHeight: 15, paddingBottom: 8, paddingHorizontal: 20, textAlign: 'center' },
});
