import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Modal, Pressable, SafeAreaView, StyleSheet, Text, View } from 'react-native';

import { MainTabBar, type MainTab } from './src/components/MainTabBar';
import type { MapLog, PindPost, Place, TasteTag } from './src/domain/types';
import { initialMapRegion, isRegionCenterInKorea, regionQueryKey, type MapRegion } from './src/domain/mapRegion';
import { ExploreMapScreen } from './src/screens/ExploreMapScreen';
import { LogsFeedScreen } from './src/screens/LogsFeedScreen';
import { PostComposerScreen } from './src/screens/PostComposerScreen';
import { TasteOnboardingScreen } from './src/screens/TasteOnboardingScreen';
import { fetchDiscoveryData } from './src/services/discovery';
import { fetchNearbyGooglePlaces, hydrateGooglePlaces } from './src/services/googlePlaces';
import { fetchMapLogs } from './src/services/mapLogs';
import { colors } from './src/theme/colors';

const tasteProfileKey = 'pind:taste-profile:v1';

type MainView =
  | { name: 'main'; tab: MainTab }
  | { name: 'composer'; initialPlace?: Place; post?: PindPost; cancelTo: MainTab };

export default function App() {
  const [tags, setTags] = useState<TasteTag[]>([]);
  const [places, setPlaces] = useState<Place[]>([]);
  const [mapLogs, setMapLogs] = useState<MapLog[]>([]);
  const [selectedCodes, setSelectedCodes] = useState<string[]>(loadTasteProfile);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingTastes, setEditingTastes] = useState(false);
  const [areaLoading, setAreaLoading] = useState(false);
  const [areaMessage, setAreaMessage] = useState<string | null>(null);
  const [mainView, setMainView] = useState<MainView>({ name: 'main', tab: 'map' });
  const loadedAreaKey = useRef<string | null>(null);
  const latestAreaRequest = useRef(0);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [data, logs] = await retryFutureJwt(() => Promise.all([fetchDiscoveryData(), fetchMapLogs()]));
      const livePlaces = await hydrateLogPlaces(logs, data.places);
      loadedAreaKey.current = regionQueryKey(initialMapRegion);
      const nearbyPlaces = await loadNearbyPlaces(initialMapRegion);
      if (nearbyPlaces.length === 0) loadedAreaKey.current = null;
      setTags(data.tags);
      setPlaces(mergePlaces(nearbyPlaces, [...data.places, ...livePlaces]));
      setMapLogs(logs);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not load Pind data.');
    } finally {
      setLoading(false);
    }
  }, []);

  const refreshPlacesForRegion = useCallback(async (region: MapRegion) => {
    if (!isRegionCenterInKorea(region)) {
      latestAreaRequest.current += 1;
      setAreaLoading(false);
      setAreaMessage('Move the map within South Korea to load food places.');
      return;
    }

    const queryKey = regionQueryKey(region);
    if (loadedAreaKey.current === queryKey) {
      setAreaMessage(null);
      return;
    }
    loadedAreaKey.current = queryKey;
    const requestId = ++latestAreaRequest.current;
    setAreaLoading(true);
    setAreaMessage(null);
    try {
      const nearbyPlaces = await fetchNearbyGooglePlaces(region);
      if (requestId === latestAreaRequest.current) {
        setPlaces((current) => mergePlaces(current, nearbyPlaces));
      }
    } catch (caught) {
      if (requestId === latestAreaRequest.current) {
        loadedAreaKey.current = null;
        setAreaMessage(caught instanceof Error ? caught.message : 'Could not load this map area.');
      }
    } finally {
      if (requestId === latestAreaRequest.current) setAreaLoading(false);
    }
  }, []);

  const refreshMapLogs = useCallback(async () => {
    try {
      const logs = await fetchMapLogs();
      const livePlaces = await hydrateLogPlaces(logs, places);
      setPlaces((current) => mergePlaces(current, livePlaces));
      setMapLogs(logs);
    } catch (caught) {
      console.warn(caught instanceof Error ? caught.message : 'Could not refresh map logs.');
    }
  }, [places]);

  useEffect(() => {
    void load();
  }, [load]);

  function saveTasteProfile(codes: string[]) {
    globalThis.localStorage.setItem(tasteProfileKey, JSON.stringify(codes));
    setSelectedCodes(codes);
    setEditingTastes(false);
  }

  if (loading) {
    return <LoadingScreen />;
  }

  if (error) {
    return <ErrorScreen message={error} onRetry={load} />;
  }

  if (selectedCodes.length < 3) {
    return (
      <>
        <StatusBar style="dark" />
        <TasteOnboardingScreen onComplete={saveTasteProfile} tags={tags} />
      </>
    );
  }

  if (mainView.name === 'composer') {
    return (
      <>
        <StatusBar style="dark" />
        <PostComposerScreen
          initialPlace={mainView.initialPlace}
          onCancel={() => setMainView({ name: 'main', tab: mainView.cancelTo })}
          onSaved={() => {
            void refreshMapLogs();
            setMainView({ name: 'main', tab: 'logs' });
          }}
          onPlaceSelected={(place) => setPlaces((current) => mergePlaces(current, [place]))}
          places={places}
          post={mainView.post}
          tags={tags}
        />
      </>
    );
  }

  const activeTab = mainView.tab;

  return (
    <View style={styles.app}>
      <StatusBar style="dark" />
      <View style={styles.mainContent}>
        {activeTab === 'map' ? (
          <ExploreMapScreen
            logs={mapLogs}
            areaLoading={areaLoading}
            areaMessage={areaMessage}
            onCreatePost={(place) => setMainView({ name: 'composer', initialPlace: place, cancelTo: 'map' })}
            onEditTastes={() => setEditingTastes(true)}
            onRegionChanged={refreshPlacesForRegion}
            places={places}
            selectedCodes={selectedCodes}
            tags={tags}
          />
        ) : (
          <LogsFeedScreen
            logs={mapLogs}
            onCreate={(place) => setMainView({ name: 'composer', initialPlace: place, cancelTo: 'logs' })}
            onEdit={(post, place) => setMainView({ name: 'composer', initialPlace: place, post, cancelTo: 'logs' })}
            onRefresh={refreshMapLogs}
            places={places}
            tags={tags}
          />
        )}
      </View>
      <MainTabBar
        activeTab={activeTab}
        canCreate
        onChange={(tab) => setMainView({ name: 'main', tab })}
        onCreate={() => setMainView({ name: 'composer', cancelTo: activeTab })}
      />
      <Modal animationType="slide" presentationStyle="fullScreen" visible={editingTastes}>
        <TasteOnboardingScreen
          editing
          initialSelected={selectedCodes}
          onCancel={() => setEditingTastes(false)}
          onComplete={saveTasteProfile}
          tags={tags}
        />
      </Modal>
    </View>
  );
}

async function loadNearbyPlaces(region: MapRegion): Promise<Place[]> {
  try {
    return await fetchNearbyGooglePlaces(region);
  } catch (caught) {
    console.warn(caught instanceof Error ? caught.message : 'Could not load nearby Google places.');
    return [];
  }
}

async function hydrateLogPlaces(logs: MapLog[], knownPlaces: Place[]): Promise<Place[]> {
  const knownIds = new Set(knownPlaces.map((place) => place.id));
  const missingIds = logs.map((log) => log.placeId).filter((placeId) => !knownIds.has(placeId));
  if (missingIds.length === 0) return [];
  try {
    return await hydrateGooglePlaces(missingIds);
  } catch (caught) {
    console.warn(caught instanceof Error ? caught.message : 'Could not refresh Google place details.');
    return [];
  }
}

function mergePlaces(current: Place[], incoming: Place[]): Place[] {
  const byId = new Map(current.map((place) => [place.id, place]));
  incoming.forEach((place) => byId.set(place.id, place));
  return [...byId.values()];
}

async function retryFutureJwt<T>(operation: () => Promise<T>): Promise<T> {
  try {
    return await operation();
  } catch (caught) {
    const message = caught instanceof Error ? caught.message : '';
    if (!message.toLowerCase().includes('jwt issued at future')) throw caught;
    await new Promise((resolve) => setTimeout(resolve, 1000));
    return operation();
  }
}

function loadTasteProfile(): string[] {
  try {
    const saved = globalThis.localStorage.getItem(tasteProfileKey);
    const parsed = saved ? JSON.parse(saved) : [];
    return Array.isArray(parsed) ? parsed.filter((value): value is string => typeof value === 'string') : [];
  } catch {
    return [];
  }
}

function LoadingScreen() {
  return (
    <SafeAreaView style={styles.centered}>
      <View style={styles.brandRow}>
        <View style={styles.logoDot} />
        <Text style={styles.brand}>pind</Text>
      </View>
      <ActivityIndicator color={colors.coral} size="large" />
      <Text style={styles.loadingText}>Drawing your Korea taste map…</Text>
      <StatusBar style="dark" />
    </SafeAreaView>
  );
}

function ErrorScreen({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <SafeAreaView style={styles.centered}>
      <Text style={styles.errorEyebrow}>CONNECTION PAUSED</Text>
      <Text style={styles.errorTitle}>We couldn’t load Korea.</Text>
      <Text style={styles.errorMessage}>{message}</Text>
      <Pressable accessibilityRole="button" onPress={onRetry} style={styles.retryButton}>
        <Text style={styles.retryText}>Try again</Text>
      </Pressable>
      <StatusBar style="dark" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  app: { backgroundColor: colors.canvas, flex: 1 },
  mainContent: { flex: 1 },
  centered: {
    alignItems: 'center',
    backgroundColor: colors.canvas,
    flex: 1,
    justifyContent: 'center',
    padding: 28,
  },
  brandRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 10,
    marginBottom: 38,
  },
  logoDot: {
    backgroundColor: colors.coral,
    borderRadius: 9,
    height: 18,
    transform: [{ rotate: '45deg' }],
    width: 18,
  },
  brand: {
    color: colors.ink,
    fontSize: 34,
    fontWeight: '900',
    letterSpacing: -1.5,
  },
  loadingText: {
    color: colors.muted,
    fontSize: 15,
    marginTop: 18,
  },
  errorEyebrow: {
    color: colors.coral,
    fontSize: 11,
    fontWeight: '900',
    letterSpacing: 1.5,
  },
  errorTitle: {
    color: colors.ink,
    fontSize: 34,
    fontWeight: '900',
    letterSpacing: -1.2,
    marginTop: 12,
    textAlign: 'center',
  },
  errorMessage: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginTop: 14,
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: colors.ink,
    borderRadius: 16,
    marginTop: 26,
    paddingHorizontal: 28,
    paddingVertical: 16,
  },
  retryText: {
    color: colors.white,
    fontSize: 15,
    fontWeight: '800',
  },
});
