import { Image, Modal, Pressable, SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

import { GoogleMapsAttribution } from '../components/GoogleMapsAttribution';
import { PlaceImage } from '../components/PlaceImage';
import type { MapLog, MapLogSource, Place, TasteTag } from '../domain/types';
import { colors } from '../theme/colors';

type Props = {
  log: MapLog | null;
  place: Place | null;
  tags: TasteTag[];
  onClose: () => void;
  onCreatePost: (place: Place) => void;
  onOpenPlace: (place: Place) => void;
};

export function MapLogDetailModal({ log, place, tags, onClose, onCreatePost, onOpenPlace }: Props) {
  if (!log || !place) return null;

  const source = sourcePresentation(log.source);
  const tagsByCode = new Map(tags.map((tag) => [tag.code, tag]));

  return (
    <Modal animationType="slide" onRequestClose={onClose} presentationStyle="pageSheet" visible>
      <SafeAreaView style={styles.safeArea}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <View style={styles.topRow}>
            <View style={[styles.sourceBadge, { backgroundColor: source.softColor }]}>
              <Text style={[styles.sourceSymbol, { color: source.color }]}>{source.symbol}</Text>
              <Text style={[styles.sourceText, { color: source.color }]}>{source.label}</Text>
            </View>
            <Pressable accessibilityLabel="Close log" onPress={onClose} style={styles.closeButton}>
              <Text style={styles.closeIcon}>×</Text>
            </Pressable>
          </View>

          <Image source={{ uri: log.photoUrl }} style={styles.photo} />

          <View style={styles.authorRow}>
            <View style={[styles.emojiBadge, { backgroundColor: source.softColor }]}>
              <Text style={styles.emoji}>{log.emoji}</Text>
            </View>
            <View style={styles.authorCopy}>
              <Text style={styles.menuName}>{log.menuName}</Text>
              <Text style={styles.authorName}>{log.authorName}</Text>
            </View>
          </View>

          <Text style={styles.body}>{log.body}</Text>

          <View style={styles.tagRow}>
            {log.tasteTagCodes.flatMap((code) => {
              const tag = tagsByCode.get(code);
              return tag ? (
                <View key={code} style={styles.tag}>
                  <Text style={styles.tagText}>{tag.emoji} {tag.labelEn}</Text>
                </View>
              ) : [];
            })}
          </View>

          <View style={styles.placeCard}>
            <PlaceImage imageStyle={styles.placeImage} uri={place.heroImageUrl} />
            <View style={styles.placeCopy}>
              <Text style={styles.placeEyebrow}>FROM PLACE DATA</Text>
              <Text style={styles.placeName}>{place.nameEn}</Text>
              <Text style={styles.placeMeta}>{place.nameKo} · {place.category}</Text>
              <Text numberOfLines={1} style={styles.placeAddress}>{place.addressEn}</Text>
            </View>
          </View>
          <GoogleMapsAttribution
            googleMapsUri={place.googleMapsUri}
            photoAttributions={place.photoAttributions}
            photoGoogleMapsUri={place.photoGoogleMapsUri}
          />

          <Pressable onPress={() => onOpenPlace(place)} style={styles.secondaryButton}>
            <Text style={styles.secondaryButtonText}>View place information</Text>
          </Pressable>
          <Pressable onPress={() => onCreatePost(place)} style={styles.primaryButton}>
            <Text style={styles.primaryButtonIcon}>＋</Text>
            <Text style={styles.primaryButtonText}>Add my log here</Text>
          </Pressable>
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
}

export function sourcePresentation(source: MapLogSource) {
  return {
    mine: { label: 'MY LOG', symbol: 'ME', color: colors.coral, softColor: colors.coralSoft },
    friend: { label: 'FRIEND LOG', symbol: 'FR', color: colors.plum, softColor: colors.plumSoft },
    default: { label: 'PIND PICK', symbol: 'P', color: colors.success, softColor: colors.mint },
  }[source];
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  content: { padding: 20, paddingBottom: 36 },
  topRow: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between', marginBottom: 14 },
  sourceBadge: { alignItems: 'center', borderRadius: 999, flexDirection: 'row', gap: 7, paddingHorizontal: 11, paddingVertical: 8 },
  sourceSymbol: { fontSize: 9, fontWeight: '900' },
  sourceText: { fontSize: 10, fontWeight: '900', letterSpacing: 1 },
  closeButton: { alignItems: 'center', backgroundColor: colors.white, borderRadius: 19, height: 38, justifyContent: 'center', width: 38 },
  closeIcon: { color: colors.ink, fontSize: 27, lineHeight: 30 },
  photo: { backgroundColor: colors.line, borderRadius: 26, height: 300, width: '100%' },
  authorRow: { alignItems: 'center', flexDirection: 'row', marginTop: 20 },
  emojiBadge: { alignItems: 'center', borderRadius: 17, height: 54, justifyContent: 'center', width: 54 },
  emoji: { fontSize: 27 },
  authorCopy: { flex: 1, marginLeft: 13 },
  menuName: { color: colors.ink, fontSize: 25, fontWeight: '900', letterSpacing: -0.6 },
  authorName: { color: colors.muted, fontSize: 13, marginTop: 3 },
  body: { color: colors.ink, fontSize: 16, lineHeight: 24, marginTop: 19 },
  tagRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 17 },
  tag: { backgroundColor: colors.white, borderColor: colors.line, borderRadius: 999, borderWidth: 1, paddingHorizontal: 11, paddingVertical: 8 },
  tagText: { color: colors.ink, fontSize: 11, fontWeight: '700' },
  placeCard: { backgroundColor: colors.card, borderColor: colors.line, borderRadius: 20, borderWidth: 1, flexDirection: 'row', marginTop: 24, padding: 12 },
  placeImage: { borderRadius: 14, height: 78, width: 78 },
  placeCopy: { flex: 1, justifyContent: 'center', marginLeft: 13 },
  placeEyebrow: { color: colors.coral, fontSize: 8, fontWeight: '900', letterSpacing: 1 },
  placeName: { color: colors.ink, fontSize: 17, fontWeight: '900', marginTop: 5 },
  placeMeta: { color: colors.muted, fontSize: 11, marginTop: 3 },
  placeAddress: { color: colors.muted, fontSize: 10, marginTop: 4 },
  secondaryButton: { alignItems: 'center', borderColor: colors.ink, borderRadius: 18, borderWidth: 1, justifyContent: 'center', marginTop: 22, minHeight: 56 },
  secondaryButtonText: { color: colors.ink, fontSize: 15, fontWeight: '800' },
  primaryButton: { alignItems: 'center', backgroundColor: colors.ink, borderRadius: 18, flexDirection: 'row', justifyContent: 'center', marginTop: 10, minHeight: 58 },
  primaryButtonIcon: { color: colors.coral, fontSize: 21, marginRight: 8 },
  primaryButtonText: { color: colors.white, fontSize: 16, fontWeight: '900' },
});
