import * as Location from 'expo-location';
import { useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  Linking,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import MapView, { Marker, PROVIDER_GOOGLE } from 'react-native-maps';

import {
  initialMapRegion,
  isCoordinateVisible,
  mapRegionAtCoordinate,
  zoomedMapRegion,
  type MapRegion,
} from '../domain/mapRegion';
import type { MapLog, MapLogSource, Place, TasteTag } from '../domain/types';
import { colors } from '../theme/colors';
import { PlaceDetailModal } from './PlaceDetailModal';

const googleMapsEnabled = process.env.EXPO_PUBLIC_GOOGLE_MAPS_ENABLED === 'true';

type MapFilter = 'all' | MapLogSource;

type Props = {
  logs: MapLog[];
  places: Place[];
  selectedCodes: readonly string[];
  tags: TasteTag[];
  areaLoading: boolean;
  areaMessage: string | null;
  onCreatePost: (place: Place) => void;
  onEditTastes: () => void;
  onRegionChanged: (region: MapRegion) => void;
};

export function ExploreMapScreen({
  logs,
  places,
  selectedCodes,
  tags,
  areaLoading,
  areaMessage,
  onCreatePost,
  onEditTastes,
  onRegionChanged,
}: Props) {
  const mapRef = useRef<MapView | null>(null);
  const [activeFilter, setActiveFilter] = useState<MapFilter>('all');
  const [query, setQuery] = useState('');
  const [selectedPlace, setSelectedPlace] = useState<Place | null>(null);
  const [mapRegion, setMapRegion] = useState<MapRegion>(initialMapRegion);
  const [locating, setLocating] = useState(false);
  const [showsUserLocation, setShowsUserLocation] = useState(false);
  const selectedCodeSet = useMemo(() => new Set(selectedCodes), [selectedCodes]);
  const logsByPlace = useMemo(() => {
    const result = new Map<number, MapLog[]>();
    logs.forEach((log) => result.set(log.placeId, [...(result.get(log.placeId) ?? []), log]));
    return result;
  }, [logs]);

  const visiblePlaces = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase();
    return places.filter((place) => {
      if (!isCoordinateVisible(place, mapRegion)) return false;
      const placeLogs = logsByPlace.get(place.id) ?? [];
      if (activeFilter !== 'all' && !placeLogs.some((log) => log.source === activeFilter)) return false;
      if (!normalizedQuery) return true;
      return [
        place.nameEn,
        place.nameKo,
        place.category,
        place.addressEn,
        place.editorialSummary,
        ...placeLogs.flatMap((log) => [log.menuName, log.body, log.authorName]),
      ]
        .filter(Boolean)
        .join(' ')
        .toLocaleLowerCase()
        .includes(normalizedQuery);
    });
  }, [activeFilter, logsByPlace, mapRegion, places, query]);

  const selectedPlaceLogs = selectedPlace ? logsByPlace.get(selectedPlace.id) ?? [] : [];
  const livePlaceCount = visiblePlaces.filter((place) => place.provider === 'google_places').length;

  function changeZoom(scale: number) {
    mapRef.current?.animateToRegion(zoomedMapRegion(mapRegion, scale), 260);
  }

  async function returnToCurrentLocation() {
    if (locating) return;
    setLocating(true);
    try {
      if (!await Location.hasServicesEnabledAsync()) {
        Alert.alert('Location is unavailable', 'Turn on Location Services to return to your current position.');
        return;
      }

      const permission = await Location.requestForegroundPermissionsAsync();
      if (permission.status !== 'granted') {
        Alert.alert(
          'Location access is off',
          'Allow location access to center the map. Search and manual map movement still work without it.',
          [
            { text: 'Not now', style: 'cancel' },
            { text: 'Open Settings', onPress: () => void Linking.openSettings() },
          ],
        );
        return;
      }

      setShowsUserLocation(true);
      const cachedLocation = await Location.getLastKnownPositionAsync({ maxAge: 60_000, requiredAccuracy: 1_000 });
      const location = cachedLocation ?? await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
      mapRef.current?.animateToRegion(mapRegionAtCoordinate(location.coords, mapRegion), 420);
    } catch (caught) {
      Alert.alert(
        'Could not find your location',
        caught instanceof Error ? caught.message : 'Try again in a moment.',
      );
    } finally {
      setLocating(false);
    }
  }

  return (
    <View style={styles.container}>
      <MapView
        initialRegion={initialMapRegion}
        mapPadding={{ top: 150, right: 12, bottom: 88, left: 12 }}
        pitchEnabled={false}
        onRegionChangeComplete={(region) => {
          setMapRegion(region);
          onRegionChanged(region);
        }}
        provider={googleMapsEnabled ? PROVIDER_GOOGLE : undefined}
        ref={mapRef}
        rotateEnabled={false}
        showsMyLocationButton={false}
        showsUserLocation={showsUserLocation}
        style={StyleSheet.absoluteFill}
        toolbarEnabled={false}
        zoomEnabled
      >
        {visiblePlaces.map((place) => {
          const placeLogs = logsByPlace.get(place.id) ?? [];
          const accent = pinAccent(activeFilter, placeLogs);
          return (
            <Marker
              accessibilityLabel={`${place.nameEn}, ${place.category}`}
              anchor={{ x: 0.5, y: 0.5 }}
              coordinate={{ latitude: place.latitude, longitude: place.longitude }}
              key={place.id}
              onPress={() => setSelectedPlace(place)}
            >
              <View style={[styles.pinOuter, { borderColor: accent }]}>
                <Image source={place.heroImageUrl ? { uri: place.heroImageUrl } : undefined} style={styles.pinImage} />
                {placeLogs.length > 0 ? (
                  <View style={[styles.logCount, { backgroundColor: accent }]}>
                    <Text style={styles.logCountText}>{placeLogs.length}</Text>
                  </View>
                ) : null}
              </View>
            </Marker>
          );
        })}
      </MapView>

      <SafeAreaView pointerEvents="box-none" style={styles.topSafeArea}>
        <View style={styles.header}>
          <View style={styles.searchRow}>
            <View style={styles.searchBox}>
              <Text style={styles.searchIcon}>⌕</Text>
              <TextInput
                accessibilityLabel="Search places, food, or vibes"
                autoCapitalize="none"
                onChangeText={setQuery}
                placeholder="Place, food, or vibe"
                placeholderTextColor={colors.muted}
                returnKeyType="search"
                style={styles.searchInput}
                value={query}
              />
              {query ? <Pressable accessibilityLabel="Clear search" onPress={() => setQuery('')}><Text style={styles.clearIcon}>×</Text></Pressable> : null}
            </View>
            <Pressable accessibilityLabel="Edit taste profile" onPress={onEditTastes} style={styles.tuneButton}>
              <Text style={styles.tuneIcon}>☷</Text>
            </Pressable>
          </View>

          <ScrollView contentContainerStyle={styles.filters} horizontal showsHorizontalScrollIndicator={false}>
            <FilterButton active={activeFilter === 'all'} color={colors.ink} label="All places" onPress={() => setActiveFilter('all')} />
            <FilterButton active={activeFilter === 'mine'} color={colors.coral} label="My visits" onPress={() => setActiveFilter('mine')} />
            <FilterButton active={activeFilter === 'friend'} color={colors.plum} label="Friends" onPress={() => setActiveFilter('friend')} />
            <FilterButton active={activeFilter === 'default'} color={colors.success} label="Pind picks" onPress={() => setActiveFilter('default')} />
          </ScrollView>
        </View>
      </SafeAreaView>

      <View style={styles.mapControls}>
        <View style={styles.zoomControls}>
          <Pressable accessibilityLabel="Zoom in" accessibilityRole="button" hitSlop={8} onPress={() => changeZoom(0.5)} style={styles.mapControlButton}>
            <Text style={styles.zoomControlText}>＋</Text>
          </Pressable>
          <View style={styles.controlDivider} />
          <Pressable accessibilityLabel="Zoom out" accessibilityRole="button" hitSlop={8} onPress={() => changeZoom(2)} style={styles.mapControlButton}>
            <Text style={styles.zoomControlText}>−</Text>
          </Pressable>
        </View>
        <Pressable
          accessibilityLabel="Return to current location"
          accessibilityRole="button"
          accessibilityState={{ busy: locating }}
          disabled={locating}
          hitSlop={8}
          onPress={() => void returnToCurrentLocation()}
          style={[styles.locationButton, locating && styles.locationButtonBusy]}
        >
          {locating ? <ActivityIndicator color={colors.plum} size="small" /> : <Text style={styles.locationIcon}>◎</Text>}
        </Pressable>
      </View>

      <SafeAreaView pointerEvents="box-none" style={styles.bottomSafeArea}>
        <View style={styles.bottomCard}>
          <View style={styles.resultsCopy}>
            <Text style={styles.resultsCount}>{visiblePlaces.length} PLACES ON THIS MAP</Text>
            <Text style={styles.resultsHint}>
              {areaLoading
                ? 'Loading food places in this area…'
                : areaMessage
                  ? areaMessage
                  : activeFilter === 'all'
                    ? `${livePlaceCount} live Google places · move anywhere in Korea`
                : filterHint(activeFilter)}
            </Text>
          </View>
          <View style={styles.googleBadge}>
            {areaLoading ? <ActivityIndicator color={colors.plum} size="small" /> : <Text style={styles.googleText}>Google Maps</Text>}
          </View>
        </View>
      </SafeAreaView>

      <PlaceDetailModal
        logs={selectedPlaceLogs}
        onClose={() => setSelectedPlace(null)}
        onCreatePost={(place) => {
          setSelectedPlace(null);
          onCreatePost(place);
        }}
        place={selectedPlace}
        selectedCodes={selectedCodeSet}
        tags={tags}
      />
    </View>
  );
}

function FilterButton({ active, color, label, onPress }: { active: boolean; color: string; label: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" accessibilityState={{ selected: active }} onPress={onPress} style={[styles.filterButton, active && { backgroundColor: color, borderColor: color }]}>
      <Text style={[styles.filterLabel, active && styles.activeFilterText]}>{label}</Text>
    </Pressable>
  );
}

function pinAccent(filter: MapFilter, logs: MapLog[]): string {
  if (filter === 'mine') return colors.coral;
  if (filter === 'friend') return colors.plum;
  if (filter === 'default') return colors.success;
  if (logs.some((log) => log.source === 'mine')) return colors.coral;
  if (logs.some((log) => log.source === 'friend')) return colors.plum;
  if (logs.some((log) => log.source === 'default')) return colors.success;
  return colors.ink;
}

function filterHint(filter: Exclude<MapFilter, 'all'>): string {
  return {
    mine: 'Places where you posted a log.',
    friend: 'Places shared by accepted friends.',
    default: 'Food places selected by Pind.',
  }[filter];
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.canvas, flex: 1 },
  topSafeArea: { left: 0, position: 'absolute', right: 0, top: 0 },
  header: { paddingHorizontal: 14, paddingTop: 7 },
  searchRow: { alignItems: 'center', flexDirection: 'row', gap: 10 },
  searchBox: { alignItems: 'center', backgroundColor: colors.white, borderColor: colors.line, borderRadius: 18, borderWidth: 1, flex: 1, flexDirection: 'row', height: 55, paddingHorizontal: 15, shadowColor: colors.black, shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.1, shadowRadius: 15 },
  searchIcon: { color: colors.ink, fontSize: 24, marginRight: 9, transform: [{ rotate: '-15deg' }] },
  searchInput: { color: colors.ink, flex: 1, fontSize: 15, fontWeight: '600' },
  clearIcon: { color: colors.muted, fontSize: 22, padding: 4 },
  tuneButton: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 18, height: 55, justifyContent: 'center', shadowColor: colors.black, shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.14, shadowRadius: 15, width: 55 },
  tuneIcon: { color: colors.white, fontSize: 24, transform: [{ rotate: '90deg' }] },
  filters: { gap: 9, paddingRight: 14, paddingTop: 11 },
  filterButton: { alignItems: 'center', backgroundColor: colors.white, borderColor: colors.line, borderRadius: 999, borderWidth: 1, height: 42, justifyContent: 'center', paddingHorizontal: 15 },
  filterLabel: { color: colors.ink, fontSize: 12, fontWeight: '800' },
  activeFilterText: { color: colors.white },
  mapControls: { gap: 10, position: 'absolute', right: 14, top: 172 },
  zoomControls: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 16, borderWidth: 1, overflow: 'hidden', shadowColor: colors.black, shadowOffset: { width: 0, height: 5 }, shadowOpacity: 0.14, shadowRadius: 10 },
  mapControlButton: { alignItems: 'center', height: 46, justifyContent: 'center', width: 46 },
  zoomControlText: { color: colors.ink, fontSize: 26, fontWeight: '700', lineHeight: 29 },
  controlDivider: { backgroundColor: colors.line, height: 1, marginHorizontal: 8 },
  locationButton: { alignItems: 'center', backgroundColor: colors.white, borderColor: colors.line, borderRadius: 16, borderWidth: 1, height: 46, justifyContent: 'center', shadowColor: colors.black, shadowOffset: { width: 0, height: 5 }, shadowOpacity: 0.14, shadowRadius: 10, width: 46 },
  locationButtonBusy: { opacity: 0.72 },
  locationIcon: { color: colors.plum, fontSize: 27, fontWeight: '900', lineHeight: 29 },
  pinOuter: { backgroundColor: colors.white, borderRadius: 32, borderWidth: 4, height: 62, padding: 3, shadowColor: colors.black, shadowOffset: { width: 0, height: 5 }, shadowOpacity: 0.22, shadowRadius: 7, width: 62 },
  pinImage: { backgroundColor: colors.line, borderRadius: 25, height: 48, width: 48 },
  logCount: { alignItems: 'center', borderColor: colors.white, borderRadius: 11, borderWidth: 2, bottom: -4, height: 23, justifyContent: 'center', minWidth: 23, position: 'absolute', right: -4 },
  logCountText: { color: colors.white, fontSize: 9, fontWeight: '900' },
  bottomSafeArea: { bottom: 0, left: 0, position: 'absolute', right: 0 },
  bottomCard: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 18, flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8, marginHorizontal: 14, minHeight: 66, paddingHorizontal: 17 },
  resultsCopy: { flex: 1, paddingRight: 10 },
  resultsCount: { color: colors.white, fontSize: 10, fontWeight: '900', letterSpacing: 1 },
  resultsHint: { color: '#BDB7C8', fontSize: 11, marginTop: 4 },
  googleBadge: { backgroundColor: colors.white, borderRadius: 11, paddingHorizontal: 10, paddingVertical: 8 },
  googleText: { color: '#5E5E5E', fontSize: 9, fontWeight: '700' },
});
