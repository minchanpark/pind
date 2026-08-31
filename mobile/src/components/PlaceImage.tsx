import { Image, StyleSheet, Text, View, type ImageStyle, type StyleProp, type ViewStyle } from 'react-native';

import { colors } from '../theme/colors';

type Props = {
  uri: string | null;
  imageStyle: StyleProp<ImageStyle>;
  placeholderStyle?: StyleProp<ViewStyle>;
};

export function PlaceImage({ uri, imageStyle, placeholderStyle }: Props) {
  if (uri) return <Image source={{ uri }} style={imageStyle} />;

  return (
    <View style={[styles.placeholder, imageStyle as StyleProp<ViewStyle>, placeholderStyle]}>
      <Text style={styles.icon}>⌖</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  placeholder: { alignItems: 'center', backgroundColor: colors.line, justifyContent: 'center' },
  icon: { color: colors.muted, fontSize: 28, fontWeight: '700' },
});
