import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { TasteTag } from '../domain/types';
import { colors } from '../theme/colors';

type Props = {
  tag: TasteTag;
  selected?: boolean;
  compact?: boolean;
  onPress?: () => void;
};

export function TastePill({ tag, selected = false, compact = false, onPress }: Props) {
  const content = (
    <View style={[styles.pill, selected && styles.selected, compact && styles.compact]}>
      <Text style={styles.emoji}>{tag.emoji}</Text>
      <Text style={[styles.label, selected && styles.selectedLabel]}>{tag.labelEn}</Text>
    </View>
  );

  if (!onPress) {
    return content;
  }

  return (
    <Pressable
      accessibilityRole="checkbox"
      accessibilityState={{ checked: selected }}
      accessibilityLabel={tag.labelEn}
      onPress={onPress}
      style={({ pressed }) => pressed && styles.pressed}
    >
      {content}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignItems: 'center',
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: 'row',
    gap: 7,
    minHeight: 44,
    paddingHorizontal: 15,
  },
  selected: {
    backgroundColor: colors.plumSoft,
    borderColor: colors.plum,
  },
  compact: {
    minHeight: 34,
    paddingHorizontal: 11,
  },
  emoji: {
    fontSize: 16,
  },
  label: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: '600',
  },
  selectedLabel: {
    color: colors.plum,
  },
  pressed: {
    opacity: 0.72,
  },
});
