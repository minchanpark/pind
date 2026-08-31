import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  Linking,
  Modal,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { GoogleMapsAttribution } from '../components/GoogleMapsAttribution';
import { LogFeedCard } from '../components/LogFeedCard';
import { PlaceImage } from '../components/PlaceImage';
import { TastePill } from '../components/TastePill';
import { matchPlace } from '../domain/matching';
import type { GooglePlacePhoto, MapLog, Place, TasteTag } from '../domain/types';
import { fetchGooglePlaceDetails } from '../services/googlePlaces';
import { colors } from '../theme/colors';

type Props = {
  place: Place | null;
  logs: MapLog[];
  tags: TasteTag[];
  selectedCodes: ReadonlySet<string>;
  onClose: () => void;
  onCreatePost: (place: Place) => void;
};

export function PlaceDetailModal({ place, logs, tags, selectedCodes, onClose, onCreatePost }: Props) {
  const [livePlace, setLivePlace] = useState<Place | null>(null);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLivePlace(place);
    setDetailError(null);
    if (!place || place.provider !== 'google_places') {
      setLoadingDetails(false);
      return () => { active = false; };
    }

    setLoadingDetails(true);
    void fetchGooglePlaceDetails(place.id)
      .then((details) => {
        if (active) setLivePlace(details);
      })
      .catch((caught) => {
        if (active) setDetailError(caught instanceof Error ? caught.message : 'Could not load more place details.');
      })
      .finally(() => {
        if (active) setLoadingDetails(false);
      });
    return () => { active = false; };
  }, [place?.id, place?.provider]);

  const displayedPlace = livePlace?.id === place?.id ? livePlace : place;
  if (!displayedPlace) return null;
  const match = matchPlace(displayedPlace, selectedCodes);
  const menuItems = uniqueMenuItems(logs);
  const gallery = displayedPlace.gallery ?? [];
  const directionsUrl = displayedPlace.googleMapsUri ??
    `https://www.google.com/maps/search/?api=1&query=${displayedPlace.latitude},${displayedPlace.longitude}`;

  async function openDirections() {
    await Linking.openURL(directionsUrl);
  }

  return (
    <Modal animationType="slide" onRequestClose={onClose} presentationStyle="pageSheet" visible>
      <SafeAreaView style={styles.safeArea}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <View style={styles.topRow}>
            <View style={styles.liveBadge}>
              <View style={styles.liveDot} />
              <Text style={styles.liveText}>
                {displayedPlace.provider === 'google_places' ? 'LIVE GOOGLE PLACE' : displayedPlace.isDemo ? 'PIND STARTER PLACE' : 'PIND PLACE'}
              </Text>
            </View>
            <Pressable accessibilityLabel="Close place details" accessibilityRole="button" onPress={onClose} style={styles.closeButton}>
              <Text style={styles.closeIcon}>×</Text>
            </Pressable>
          </View>

          <PlaceImage imageStyle={styles.hero} uri={displayedPlace.heroImageUrl} />
          <GoogleMapsAttribution
            googleMapsUri={displayedPlace.googleMapsUri}
            photoAttributions={displayedPlace.photoAttributions}
            photoGoogleMapsUri={displayedPlace.photoGoogleMapsUri}
          />

          <View style={styles.headingRow}>
            <View style={styles.headingCopy}>
              <Text style={styles.category}>{displayedPlace.category.toUpperCase()}</Text>
              <Text style={styles.name}>{displayedPlace.nameEn}</Text>
              {displayedPlace.nameKo !== displayedPlace.nameEn ? <Text style={styles.koreanName}>{displayedPlace.nameKo}</Text> : null}
            </View>
            {displayedPlace.tastes.length > 0 ? (
              <View style={styles.scoreBadge}>
                <Text style={styles.score}>{match.score}</Text>
                <Text style={styles.scoreLabel}>MATCH</Text>
              </View>
            ) : null}
          </View>

          <Text style={styles.aboutEyebrow}>ABOUT THIS PLACE</Text>
          <Text style={styles.description}>{displayedPlace.editorialSummary ?? displayedPlace.shortDescriptionEn}</Text>

          {gallery.length > 1 ? (
            <View style={styles.gallerySection}>
              <View style={styles.sectionHeadingRow}>
                <View>
                  <Text style={styles.sectionEyebrow}>GOOGLE PLACE PHOTOS</Text>
                  <Text style={styles.sectionTitle}>See the space</Text>
                </View>
                <Text style={styles.sectionCount}>{gallery.length}</Text>
              </View>
              <ScrollView contentContainerStyle={styles.galleryContent} horizontal showsHorizontalScrollIndicator={false}>
                {gallery.slice(1).map((photo, index) => (
                  <GalleryPhotoCard
                    googleMapsUri={displayedPlace.googleMapsUri}
                    key={`${photo.uri}-${index}`}
                    photo={photo}
                  />
                ))}
              </ScrollView>
            </View>
          ) : null}

          <View style={styles.addressCard}>
            <Text style={styles.addressIcon}>⌖</Text>
            <View style={styles.addressCopy}>
              <Text style={styles.address}>{displayedPlace.addressEn}</Text>
              {displayedPlace.addressKo !== displayedPlace.addressEn ? <Text style={styles.addressKo}>{displayedPlace.addressKo}</Text> : null}
            </View>
          </View>

          {loadingDetails ? (
            <View style={styles.loadingRow}><ActivityIndicator color={colors.plum} size="small" /><Text style={styles.loadingText}>Loading live opening and contact details…</Text></View>
          ) : null}
          {detailError ? <Text style={styles.detailError}>{detailError}</Text> : null}

          {displayedPlace.provider === 'google_places' ? (
            <View style={styles.infoCard}>
              <View style={styles.infoHeadingRow}>
                <Text style={styles.infoEyebrow}>VISIT INFO</Text>
                {displayedPlace.businessStatus ? <Text style={styles.businessStatus}>{businessStatus(displayedPlace.businessStatus)}</Text> : null}
              </View>
              {displayedPlace.isOpenNow !== null ? (
                <Text style={[styles.openState, displayedPlace.isOpenNow ? styles.open : styles.closed]}>
                  {displayedPlace.isOpenNow ? 'Open now' : 'Closed now'}
                </Text>
              ) : null}
              {displayedPlace.weekdayDescriptions.length > 0 ? (
                <View style={styles.hours}>
                  {displayedPlace.weekdayDescriptions.map((line) => <Text key={line} style={styles.hourLine}>{line}</Text>)}
                </View>
              ) : !loadingDetails ? <Text style={styles.missingInfo}>Opening hours are not available from Google Maps.</Text> : null}

              <View style={styles.contactRow}>
                {displayedPlace.phoneNumber ? (
                  <Pressable onPress={() => void Linking.openURL(`tel:${displayedPlace.phoneNumber}`)} style={styles.secondaryButton}>
                    <Text style={styles.secondaryButtonText}>Call</Text>
                  </Pressable>
                ) : null}
                {displayedPlace.websiteUri ? (
                  <Pressable onPress={() => void Linking.openURL(displayedPlace.websiteUri!)} style={styles.secondaryButton}>
                    <Text style={styles.secondaryButtonText}>Website ↗</Text>
                  </Pressable>
                ) : null}
              </View>
            </View>
          ) : null}

          {displayedPlace.tastes.length > 0 ? (
            <View style={styles.reasonCard}>
              <Text style={styles.reasonEyebrow}>WHY IT FITS YOU</Text>
              <Text style={styles.reasonTitle}>{match.reasons.length > 0 ? 'Your taste shows up here.' : 'Try this when you want something different.'}</Text>
              {match.reasons.length > 0 ? <View style={styles.pillWrap}>{match.reasons.map((tag) => <TastePill key={tag.code} compact selected tag={tag} />)}</View> : null}
            </View>
          ) : null}

          <View style={styles.menuSection}>
            <View style={styles.sectionHeadingRow}>
              <View>
                <Text style={styles.sectionEyebrow}>MENU FROM PIND LOGS</Text>
                <Text style={styles.sectionTitle}>Dishes people tried</Text>
              </View>
              <Text style={styles.sectionCount}>{menuItems.length}</Text>
            </View>
            {menuItems.length > 0 ? (
              <ScrollView contentContainerStyle={styles.menuContent} horizontal showsHorizontalScrollIndicator={false}>
                {menuItems.map((log) => (
                  <View key={log.id} style={styles.menuCard}>
                    <Image source={{ uri: log.photoUrl }} style={styles.menuPhoto} />
                    <View style={styles.menuCopy}>
                      <Text numberOfLines={2} style={styles.menuName}>{log.emoji} {log.menuName}</Text>
                      <Text numberOfLines={1} style={styles.menuAuthor}>Logged by {log.authorName}</Text>
                    </View>
                  </View>
                ))}
              </ScrollView>
            ) : (
              <View style={styles.emptyMenu}>
                <Text style={styles.emptyMenuTitle}>No menu photos yet.</Text>
                <Text style={styles.emptyMenuCopy}>Menu items appear here when someone posts a food log with a dish name and photo.</Text>
              </View>
            )}
            <Text style={styles.menuSourceNote}>Community menu photos from Pind logs—not an official restaurant menu.</Text>
          </View>

          <View style={styles.actionRow}>
            <Pressable accessibilityRole="button" onPress={() => onCreatePost(displayedPlace)} style={styles.postButton}>
              <Text style={styles.postButtonIcon}>＋</Text><Text style={styles.postButtonText}>Write a log</Text>
            </Pressable>
            <Pressable accessibilityRole="button" onPress={() => void openDirections()} style={styles.mapsButton}>
              <Text style={styles.mapsButtonText}>Maps ↗</Text>
            </Pressable>
          </View>

          <View style={styles.logsHeading}>
            <View>
              <Text style={styles.logsEyebrow}>PIND LOGS HERE</Text>
              <Text style={styles.logsTitle}>What people ate</Text>
            </View>
            <Text style={styles.logsCount}>{logs.length}</Text>
          </View>
          {logs.length > 0 ? (
            <View style={styles.logList}>
              {logs.map((log) => <LogFeedCard compact key={log.id} log={log} place={displayedPlace} tags={tags} />)}
            </View>
          ) : (
            <View style={styles.emptyLogs}>
              <Text style={styles.emptyLogsTitle}>Be the first to log this place.</Text>
              <Text style={styles.emptyLogsCopy}>A photo, a reaction, and taste tags are enough—never a star rating.</Text>
            </View>
          )}

          <Text style={styles.disclaimer}>
            {displayedPlace.provider === 'google_places'
              ? 'Place details are fetched live from Google Maps. Verify venue information before visiting.'
              : 'Pind starter data · verify venue information before visiting'}
          </Text>
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
}

function GalleryPhotoCard({ photo, googleMapsUri }: { photo: GooglePlacePhoto; googleMapsUri: string | null }) {
  const sourceUri = photo.googleMapsUri ?? googleMapsUri;
  return (
    <View style={styles.galleryCard}>
      <Image source={{ uri: photo.uri }} style={styles.galleryPhoto} />
      <View style={styles.galleryAttribution}>
        <Pressable disabled={!sourceUri} onPress={() => sourceUri && void Linking.openURL(sourceUri)}>
          <Text style={styles.galleryGoogle}>Google Maps ↗</Text>
        </Pressable>
        {photo.attributions.map((item, index) => (
          <Pressable
            disabled={!item.uri}
            key={`${item.displayName}-${index}`}
            onPress={() => item.uri && void Linking.openURL(item.uri)}
          >
            <Text numberOfLines={1} style={styles.galleryAuthor}>Photo by {item.displayName}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

function uniqueMenuItems(logs: MapLog[]): MapLog[] {
  const seen = new Set<string>();
  return logs.filter((log) => {
    const key = log.menuName.trim().toLocaleLowerCase();
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function businessStatus(value: string): string {
  return value === 'OPERATIONAL' ? 'Operating' : value.toLowerCase().replaceAll('_', ' ');
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  content: { padding: 20, paddingBottom: 38 },
  topRow: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between', marginBottom: 14 },
  liveBadge: { alignItems: 'center', backgroundColor: colors.coralSoft, borderRadius: 99, flexDirection: 'row', gap: 7, paddingHorizontal: 11, paddingVertical: 7 },
  liveDot: { backgroundColor: colors.coral, borderRadius: 4, height: 7, width: 7 },
  liveText: { color: colors.coral, fontSize: 10, fontWeight: '900', letterSpacing: 1 },
  closeButton: { alignItems: 'center', backgroundColor: colors.white, borderRadius: 19, height: 38, justifyContent: 'center', width: 38 },
  closeIcon: { color: colors.ink, fontSize: 27, lineHeight: 30 },
  hero: { backgroundColor: colors.line, borderRadius: 26, height: 272, width: '100%' },
  headingRow: { alignItems: 'flex-start', flexDirection: 'row', gap: 16, justifyContent: 'space-between', marginTop: 22 },
  headingCopy: { flex: 1 },
  category: { color: colors.coral, fontSize: 11, fontWeight: '900', letterSpacing: 1.3, marginBottom: 7 },
  name: { color: colors.ink, fontSize: 31, fontWeight: '900', letterSpacing: -1.2, lineHeight: 34 },
  koreanName: { color: colors.muted, fontSize: 15, marginTop: 5 },
  scoreBadge: { alignItems: 'center', backgroundColor: colors.plum, borderRadius: 20, minWidth: 72, paddingHorizontal: 13, paddingVertical: 11 },
  score: { color: colors.white, fontSize: 27, fontWeight: '900', letterSpacing: -1 },
  scoreLabel: { color: colors.plumSoft, fontSize: 8, fontWeight: '900', letterSpacing: 1 },
  aboutEyebrow: { color: colors.plum, fontSize: 9, fontWeight: '900', letterSpacing: 1.3, marginTop: 20 },
  description: { color: colors.ink, fontSize: 17, lineHeight: 26, marginTop: 7 },
  gallerySection: { marginTop: 25 },
  sectionHeadingRow: { alignItems: 'flex-end', flexDirection: 'row', justifyContent: 'space-between', marginBottom: 13 },
  sectionEyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.3 },
  sectionTitle: { color: colors.ink, fontSize: 22, fontWeight: '900', marginTop: 3 },
  sectionCount: { color: colors.plum, fontSize: 22, fontWeight: '900' },
  galleryContent: { gap: 12, paddingRight: 20 },
  galleryCard: { backgroundColor: colors.white, borderRadius: 18, overflow: 'hidden', width: 240 },
  galleryPhoto: { backgroundColor: colors.line, height: 165, width: '100%' },
  galleryAttribution: { gap: 4, padding: 11 },
  galleryGoogle: { color: '#5E5E5E', fontSize: 10, fontWeight: '700' },
  galleryAuthor: { color: colors.muted, fontSize: 10 },
  addressCard: { alignItems: 'center', backgroundColor: colors.white, borderColor: colors.line, borderRadius: 18, borderWidth: 1, flexDirection: 'row', marginTop: 22, padding: 15 },
  addressIcon: { color: colors.coral, fontSize: 25 },
  addressCopy: { flex: 1, marginLeft: 12 },
  address: { color: colors.ink, fontSize: 14, fontWeight: '700', lineHeight: 20 },
  addressKo: { color: colors.muted, fontSize: 12, marginTop: 3 },
  loadingRow: { alignItems: 'center', flexDirection: 'row', gap: 9, marginTop: 16 },
  loadingText: { color: colors.muted, fontSize: 12 },
  detailError: { color: colors.danger, fontSize: 12, lineHeight: 18, marginTop: 14 },
  infoCard: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 22, borderWidth: 1, marginTop: 18, padding: 18 },
  infoHeadingRow: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between' },
  infoEyebrow: { color: colors.plum, fontSize: 10, fontWeight: '900', letterSpacing: 1.3 },
  businessStatus: { color: colors.success, fontSize: 10, fontWeight: '900', textTransform: 'capitalize' },
  openState: { fontSize: 18, fontWeight: '900', marginTop: 12 },
  open: { color: colors.success },
  closed: { color: colors.danger },
  hours: { gap: 5, marginTop: 13 },
  hourLine: { color: colors.ink, fontSize: 12, lineHeight: 17 },
  missingInfo: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 12 },
  contactRow: { flexDirection: 'row', gap: 9, marginTop: 15 },
  secondaryButton: { backgroundColor: colors.plumSoft, borderRadius: 13, paddingHorizontal: 15, paddingVertical: 11 },
  secondaryButtonText: { color: colors.plum, fontSize: 12, fontWeight: '900' },
  reasonCard: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 22, borderWidth: 1, marginTop: 18, padding: 18 },
  reasonEyebrow: { color: colors.plum, fontSize: 10, fontWeight: '900', letterSpacing: 1.4 },
  reasonTitle: { color: colors.ink, fontSize: 20, fontWeight: '800', marginTop: 8 },
  pillWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 14 },
  menuSection: { marginTop: 28 },
  menuContent: { gap: 12, paddingRight: 20 },
  menuCard: { backgroundColor: colors.white, borderRadius: 19, overflow: 'hidden', width: 190 },
  menuPhoto: { backgroundColor: colors.line, height: 150, width: '100%' },
  menuCopy: { padding: 13 },
  menuName: { color: colors.ink, fontSize: 15, fontWeight: '900', lineHeight: 20 },
  menuAuthor: { color: colors.muted, fontSize: 10, marginTop: 6 },
  emptyMenu: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 20, borderWidth: 1, padding: 18 },
  emptyMenuTitle: { color: colors.ink, fontSize: 16, fontWeight: '900' },
  emptyMenuCopy: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 6 },
  menuSourceNote: { color: colors.muted, fontSize: 10, lineHeight: 15, marginTop: 9 },
  actionRow: { flexDirection: 'row', gap: 9, marginTop: 22 },
  postButton: { alignItems: 'center', backgroundColor: colors.coral, borderRadius: 18, flex: 1, flexDirection: 'row', justifyContent: 'center', minHeight: 58 },
  postButtonIcon: { color: colors.white, fontSize: 22, marginRight: 7 },
  postButtonText: { color: colors.white, fontSize: 15, fontWeight: '900' },
  mapsButton: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 18, justifyContent: 'center', minHeight: 58, paddingHorizontal: 20 },
  mapsButtonText: { color: colors.white, fontSize: 13, fontWeight: '900' },
  logsHeading: { alignItems: 'flex-end', flexDirection: 'row', justifyContent: 'space-between', marginTop: 34, marginBottom: 14 },
  logsEyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.3 },
  logsTitle: { color: colors.ink, fontSize: 24, fontWeight: '900', marginTop: 3 },
  logsCount: { color: colors.plum, fontSize: 24, fontWeight: '900' },
  logList: { gap: 14 },
  emptyLogs: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 22, borderWidth: 1, padding: 20 },
  emptyLogsTitle: { color: colors.ink, fontSize: 17, fontWeight: '900' },
  emptyLogsCopy: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 6 },
  disclaimer: { color: colors.muted, fontSize: 10, lineHeight: 15, marginTop: 20, textAlign: 'center' },
});
