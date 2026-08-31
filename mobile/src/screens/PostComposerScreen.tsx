import * as ImagePicker from 'expo-image-picker';
import { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { TastePill } from '../components/TastePill';
import { GoogleMapsAttribution } from '../components/GoogleMapsAttribution';
import { PlaceImage } from '../components/PlaceImage';
import type { PindPost, Place, TasteTag } from '../domain/types';
import { savePost, type LocalPostPhoto } from '../services/posts';
import { colors } from '../theme/colors';
import { GooglePlaceSearchModal } from './GooglePlaceSearchModal';

const moodEmojis = ['🤤', '🔥', '✨', '🥹', '💜', '😌'];

type Props = {
  initialPlace?: Place;
  places: Place[];
  post?: PindPost;
  tags: TasteTag[];
  onCancel: () => void;
  onPlaceSelected: (place: Place) => void;
  onSaved: () => void;
};

export function PostComposerScreen({ initialPlace, places, post, tags, onCancel, onPlaceSelected, onSaved }: Props) {
  const [placeId, setPlaceId] = useState<number | null>(post?.placeId ?? initialPlace?.id ?? null);
  const [localPlace, setLocalPlace] = useState<Place | null>(null);
  const [menuName, setMenuName] = useState(post?.menuName ?? '');
  const [photo, setPhoto] = useState<LocalPostPhoto | null>(null);
  const [emoji, setEmoji] = useState(post?.emoji ?? moodEmojis[0]);
  const [body, setBody] = useState(post?.body ?? '');
  const [tagCodes, setTagCodes] = useState<string[]>(post?.tasteTagCodes ?? []);
  const [isPublic, setIsPublic] = useState(post?.isPublic ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchingPlaces, setSearchingPlaces] = useState(false);

  useEffect(() => {
    setPlaceId(post?.placeId ?? initialPlace?.id ?? null);
    setLocalPlace(null);
    setMenuName(post?.menuName ?? '');
    setPhoto(null);
    setEmoji(post?.emoji ?? moodEmojis[0]);
    setBody(post?.body ?? '');
    setTagCodes(post?.tasteTagCodes ?? []);
    setIsPublic(post?.isPublic ?? true);
    setError(null);
  }, [initialPlace?.id, post]);

  const photoUri = photo?.uri ?? post?.photoUrl ?? null;
  const selectedPlace = useMemo(() => {
    if (placeId === null) return null;
    return places.find((place) => place.id === placeId) ??
      (localPlace?.id === placeId ? localPlace : null) ??
      (initialPlace?.id === placeId ? initialPlace : null);
  }, [initialPlace, localPlace, placeId, places]);
  const canSave = useMemo(
    () => Boolean(placeId !== null && photoUri && menuName.trim() && body.trim() && tagCodes.length > 0 && !saving),
    [body, menuName, photoUri, placeId, saving, tagCodes.length],
  );

  async function choosePhoto() {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Photo access needed', 'Allow photo access to attach a dish to your Pind log.');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: false,
      quality: 0.82,
    });

    if (result.canceled || !result.assets[0]) return;
    const asset = result.assets[0];
    setPhoto({ uri: asset.uri, mimeType: asset.mimeType ?? null, fileName: asset.fileName ?? null });
  }

  function toggleTag(code: string) {
    setTagCodes((current) =>
      current.includes(code) ? current.filter((selectedCode) => selectedCode !== code) : [...current, code],
    );
  }

  function chooseGooglePlace(place: Place) {
    setLocalPlace(place);
    setPlaceId(place.id);
    onPlaceSelected(place);
  }

  async function submit() {
    if (!canSave || placeId === null) return;
    setSaving(true);
    setError(null);

    try {
      await savePost({ post, placeId, menuName, photo, emoji, body, tasteTagCodes: tagCodes, isPublic });
      onSaved();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not save this post.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.safeArea}>
        <View style={styles.header}>
          <Pressable accessibilityRole="button" onPress={onCancel} style={styles.headerButton}>
            <Text style={styles.headerButtonText}>Cancel</Text>
          </Pressable>
          <View style={styles.headerTitleWrap}>
            <Text style={styles.eyebrow}>{post ? 'EDIT LOG' : 'NEW LOG'}</Text>
            <Text style={styles.headerTitle}>{post ? 'Tune your memory' : 'Pin this taste'}</Text>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityState={{ disabled: !canSave }}
            disabled={!canSave}
            onPress={submit}
            style={[styles.saveButton, !canSave && styles.saveButtonDisabled]}
          >
            {saving ? <ActivityIndicator color={colors.white} size="small" /> : <Text style={styles.saveText}>Save</Text>}
          </Pressable>
        </View>

        <ScrollView
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <Pressable accessibilityLabel="Choose food photo" onPress={choosePhoto} style={styles.photoPicker}>
            {photoUri ? (
              <>
                <Image source={{ uri: photoUri }} style={styles.photo} />
                <View style={styles.changePhotoBadge}>
                  <Text style={styles.changePhotoText}>Change photo</Text>
                </View>
              </>
            ) : (
              <View style={styles.photoPlaceholder}>
                <Text style={styles.photoIcon}>＋</Text>
                <Text style={styles.photoTitle}>Start with the dish</Text>
                <Text style={styles.photoHint}>Choose one food photo</Text>
              </View>
            )}
          </Pressable>

          <SectionLabel label="PLACE" required />
          {selectedPlace ? (
            <>
              <View style={styles.selectedPlaceCard}>
                <PlaceImage imageStyle={styles.selectedPlaceImage} uri={selectedPlace.heroImageUrl} />
                <View style={styles.selectedPlaceCopy}>
                  <Text style={styles.selectedPlaceEyebrow}>
                    {selectedPlace.provider === 'google_places' ? 'LIVE PLACE' : 'FROM PLACE DATA'}
                  </Text>
                  <Text style={styles.selectedPlaceName}>{selectedPlace.nameEn}</Text>
                  <Text style={styles.selectedPlaceMeta}>{selectedPlace.nameKo} · {selectedPlace.category}</Text>
                  <Text numberOfLines={1} style={styles.selectedPlaceAddress}>{selectedPlace.addressEn}</Text>
                </View>
              </View>
              <GoogleMapsAttribution
                googleMapsUri={selectedPlace.googleMapsUri}
                photoAttributions={selectedPlace.photoAttributions}
                photoGoogleMapsUri={selectedPlace.photoGoogleMapsUri}
              />
            </>
          ) : (
            <Pressable onPress={() => setSearchingPlaces(true)} style={styles.emptyPlaceCard}>
              <Text style={styles.emptyPlaceIcon}>⌖</Text>
              <View style={styles.emptyPlaceCopy}>
                <Text style={styles.emptyPlaceTitle}>No place selected</Text>
                <Text style={styles.emptyPlaceHint}>Search Google Maps to choose the place you visited.</Text>
              </View>
            </Pressable>
          )}
          <Pressable accessibilityRole="button" onPress={() => setSearchingPlaces(true)} style={styles.realPlaceButton}>
            <View>
              <Text style={styles.realPlaceEyebrow}>GOOGLE MAPS</Text>
              <Text style={styles.realPlaceTitle}>{selectedPlace ? 'Change restaurant or cafe' : 'Choose a restaurant or cafe'}</Text>
            </View>
            <Text style={styles.realPlaceArrow}>⌕</Text>
          </Pressable>

          <SectionLabel label="WHAT DID YOU EAT?" required />
          <TextInput
            accessibilityLabel="Menu name"
            maxLength={80}
            onChangeText={setMenuName}
            placeholder="e.g. Spicy pork rice bowl"
            placeholderTextColor={colors.muted}
            style={styles.input}
            value={menuName}
          />

          <SectionLabel label="REACTION" required />
          <View style={styles.emojiRow}>
            {moodEmojis.map((option) => (
              <Pressable
                accessibilityRole="radio"
                accessibilityState={{ selected: emoji === option }}
                key={option}
                onPress={() => setEmoji(option)}
                style={[styles.emojiButton, emoji === option && styles.emojiButtonSelected]}
              >
                <Text style={styles.emoji}>{option}</Text>
              </Pressable>
            ))}
          </View>

          <SectionLabel label="TASTE TAGS" required />
          <View style={styles.tagWrap}>
            {tags.map((tag) => (
              <TastePill key={tag.code} onPress={() => toggleTag(tag.code)} selected={tagCodes.includes(tag.code)} tag={tag} />
            ))}
          </View>

          <SectionLabel label="TELL IT LIKE A FRIEND" required />
          <TextInput
            accessibilityLabel="Post body"
            maxLength={2000}
            multiline
            onChangeText={setBody}
            placeholder="What stood out? Who would love it?"
            placeholderTextColor={colors.muted}
            style={[styles.input, styles.bodyInput]}
            textAlignVertical="top"
            value={body}
          />

          <Pressable
            accessibilityRole="switch"
            accessibilityState={{ checked: isPublic }}
            onPress={() => setIsPublic((current) => !current)}
            style={styles.visibilityCard}
          >
            <View style={styles.visibilityCopy}>
              <Text style={styles.visibilityTitle}>{isPublic ? 'Public log' : 'Only me'}</Text>
              <Text style={styles.visibilityHint}>
                {isPublic ? 'Other Pind visitors can discover this taste.' : 'This stays in your personal logs.'}
              </Text>
            </View>
            <View style={[styles.switchTrack, isPublic && styles.switchTrackActive]}>
              <View style={[styles.switchThumb, isPublic && styles.switchThumbActive]} />
            </View>
          </Pressable>

          {error ? <Text style={styles.error}>{error}</Text> : null}
          <Text style={styles.note}>Saving also records this place as visited. Pind never asks for a star rating.</Text>
        </ScrollView>
      </KeyboardAvoidingView>
      <GooglePlaceSearchModal
        onClose={() => setSearchingPlaces(false)}
        onSelect={chooseGooglePlace}
        visible={searchingPlaces}
      />
    </SafeAreaView>
  );
}

function SectionLabel({ label, required = false }: { label: string; required?: boolean }) {
  return (
    <View style={styles.sectionLabelRow}>
      <Text style={styles.sectionLabel}>{label}</Text>
      {required ? <Text style={styles.required}>REQUIRED</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.canvas, flex: 1 },
  header: {
    alignItems: 'center',
    borderBottomColor: colors.line,
    borderBottomWidth: 1,
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'space-between',
    minHeight: 70,
    paddingHorizontal: 16,
  },
  headerButton: { minWidth: 55, paddingVertical: 12 },
  headerButtonText: { color: colors.muted, fontSize: 15, fontWeight: '700' },
  headerTitleWrap: { alignItems: 'center', flex: 1 },
  eyebrow: { color: colors.coral, fontSize: 9, fontWeight: '900', letterSpacing: 1.5 },
  headerTitle: { color: colors.ink, fontSize: 18, fontWeight: '900', marginTop: 2 },
  saveButton: {
    alignItems: 'center',
    backgroundColor: colors.plum,
    borderRadius: 14,
    justifyContent: 'center',
    minHeight: 42,
    minWidth: 64,
    paddingHorizontal: 14,
  },
  saveButtonDisabled: { backgroundColor: colors.line },
  saveText: { color: colors.white, fontSize: 14, fontWeight: '900' },
  content: { padding: 18, paddingBottom: 44 },
  photoPicker: { backgroundColor: colors.card, borderRadius: 26, height: 285, overflow: 'hidden' },
  photo: { height: '100%', width: '100%' },
  photoPlaceholder: { alignItems: 'center', flex: 1, justifyContent: 'center' },
  photoIcon: { color: colors.coral, fontSize: 44, fontWeight: '300' },
  photoTitle: { color: colors.ink, fontSize: 22, fontWeight: '900', marginTop: 8 },
  photoHint: { color: colors.muted, fontSize: 14, marginTop: 6 },
  changePhotoBadge: {
    backgroundColor: colors.ink,
    borderRadius: 999,
    bottom: 14,
    paddingHorizontal: 14,
    paddingVertical: 9,
    position: 'absolute',
    right: 14,
  },
  changePhotoText: { color: colors.white, fontSize: 12, fontWeight: '800' },
  sectionLabelRow: { alignItems: 'center', flexDirection: 'row', gap: 8, marginBottom: 10, marginTop: 26 },
  sectionLabel: { color: colors.ink, fontSize: 11, fontWeight: '900', letterSpacing: 1.2 },
  required: { color: colors.coral, fontSize: 8, fontWeight: '900', letterSpacing: 0.8 },
  selectedPlaceCard: {
    backgroundColor: colors.card,
    borderColor: colors.coral,
    borderRadius: 20,
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: 11,
    padding: 11,
  },
  selectedPlaceImage: { borderRadius: 14, height: 74, width: 74 },
  selectedPlaceCopy: { flex: 1, justifyContent: 'center', marginLeft: 13 },
  selectedPlaceEyebrow: { color: colors.coral, fontSize: 8, fontWeight: '900', letterSpacing: 1 },
  selectedPlaceName: { color: colors.ink, fontSize: 17, fontWeight: '900', marginTop: 4 },
  selectedPlaceMeta: { color: colors.muted, fontSize: 11, marginTop: 3 },
  selectedPlaceAddress: { color: colors.muted, fontSize: 10, marginTop: 4 },
  emptyPlaceCard: {
    alignItems: 'center',
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderRadius: 20,
    borderStyle: 'dashed',
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: 11,
    minHeight: 96,
    padding: 16,
  },
  emptyPlaceIcon: { color: colors.coral, fontSize: 29, fontWeight: '700' },
  emptyPlaceCopy: { flex: 1, marginLeft: 13 },
  emptyPlaceTitle: { color: colors.ink, fontSize: 16, fontWeight: '900' },
  emptyPlaceHint: { color: colors.muted, fontSize: 12, lineHeight: 17, marginTop: 4 },
  realPlaceButton: {
    alignItems: 'center',
    backgroundColor: colors.white,
    borderColor: colors.plum,
    borderRadius: 17,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 11,
    paddingHorizontal: 15,
    paddingVertical: 13,
  },
  realPlaceEyebrow: { color: '#5E5E5E', fontSize: 12, fontWeight: '400' },
  realPlaceTitle: { color: colors.ink, fontSize: 14, fontWeight: '800', marginTop: 3 },
  realPlaceArrow: { color: colors.plum, fontSize: 26 },
  input: {
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderRadius: 17,
    borderWidth: 1,
    color: colors.ink,
    fontSize: 16,
    minHeight: 56,
    paddingHorizontal: 16,
  },
  bodyInput: { lineHeight: 23, minHeight: 132, paddingTop: 15 },
  emojiRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  emojiButton: {
    alignItems: 'center',
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderRadius: 16,
    borderWidth: 1,
    height: 52,
    justifyContent: 'center',
    width: 52,
  },
  emojiButtonSelected: { backgroundColor: colors.coralSoft, borderColor: colors.coral },
  emoji: { fontSize: 25 },
  tagWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  visibilityCard: {
    alignItems: 'center',
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 26,
    padding: 16,
  },
  visibilityCopy: { flex: 1, paddingRight: 16 },
  visibilityTitle: { color: colors.ink, fontSize: 15, fontWeight: '800' },
  visibilityHint: { color: colors.muted, fontSize: 12, lineHeight: 17, marginTop: 4 },
  switchTrack: { backgroundColor: colors.line, borderRadius: 14, height: 28, padding: 3, width: 48 },
  switchTrackActive: { backgroundColor: colors.plum },
  switchThumb: { backgroundColor: colors.white, borderRadius: 11, height: 22, width: 22 },
  switchThumbActive: { alignSelf: 'flex-end' },
  error: { color: colors.danger, fontSize: 13, lineHeight: 19, marginTop: 16, textAlign: 'center' },
  note: { color: colors.muted, fontSize: 11, lineHeight: 17, marginTop: 18, textAlign: 'center' },
});
