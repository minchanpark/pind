import { Image, Linking, Pressable, StyleSheet, Text, View } from 'react-native';

import type { GooglePhotoAttribution } from '../domain/types';
import { colors } from '../theme/colors';

type Props = {
  googleMapsUri: string | null;
  photoGoogleMapsUri: string | null;
  photoAttributions: GooglePhotoAttribution[];
};

export function GoogleMapsAttribution({ googleMapsUri, photoGoogleMapsUri, photoAttributions }: Props) {
  if (!googleMapsUri) return null;
  const sourceUri = photoGoogleMapsUri ?? googleMapsUri;

  return (
    <View style={styles.container}>
      <Pressable accessibilityRole="link" onPress={() => void Linking.openURL(sourceUri)} style={styles.sourceLink}>
        <Text style={styles.googleText}>Google Maps</Text>
        <Text style={styles.openText}>View source ↗</Text>
      </Pressable>
      {photoAttributions.map((attribution, index) => (
        <Pressable
          accessibilityRole={attribution.uri ? 'link' : undefined}
          disabled={!attribution.uri}
          key={`${attribution.displayName}-${index}`}
          onPress={() => attribution.uri && void Linking.openURL(attribution.uri)}
          style={styles.authorRow}
        >
          {attribution.photoUri ? <Image source={{ uri: attribution.photoUri }} style={styles.avatar} /> : null}
          <Text numberOfLines={1} style={styles.authorText}>Photo by {attribution.displayName}</Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: 7, paddingHorizontal: 2, paddingVertical: 9 },
  sourceLink: { alignItems: 'center', flexDirection: 'row', justifyContent: 'space-between' },
  googleText: { color: '#5E5E5E', fontSize: 12, fontWeight: '400' },
  openText: { color: colors.plum, fontSize: 11, fontWeight: '700' },
  authorRow: { alignItems: 'center', flexDirection: 'row', gap: 7 },
  avatar: { borderRadius: 10, height: 20, width: 20 },
  authorText: { color: colors.muted, flex: 1, fontSize: 11 },
});
