import { useMemo, useState } from 'react';
import { Pressable, SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

import { TastePill } from '../components/TastePill';
import type { TasteAxis, TasteTag } from '../domain/types';
import { colors } from '../theme/colors';

const axisOrder: TasteAxis[] = ['taste', 'texture', 'vibe', 'for'];
const axisLabels: Record<TasteAxis, string> = {
  taste: 'TASTE',
  texture: 'TEXTURE',
  vibe: 'VIBE',
  for: 'GOOD FOR',
};

type Props = {
  tags: TasteTag[];
  initialSelected?: readonly string[];
  editing?: boolean;
  onComplete: (selectedCodes: string[]) => void;
  onCancel?: () => void;
};

export function TasteOnboardingScreen({
  tags,
  initialSelected = [],
  editing = false,
  onComplete,
  onCancel,
}: Props) {
  const [selectedCodes, setSelectedCodes] = useState(() => new Set(initialSelected));
  const groupedTags = useMemo(
    () => new Map(axisOrder.map((axis) => [axis, tags.filter((tag) => tag.axis === axis)])),
    [tags],
  );
  const canContinue = selectedCodes.size >= 3;

  function toggle(code: string) {
    setSelectedCodes((current) => {
      const next = new Set(current);
      if (next.has(code)) next.delete(code);
      else next.add(code);
      return next;
    });
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.topRow}>
          <View style={styles.wordmarkRow}>
            <View style={styles.logoDot} />
            <Text style={styles.wordmark}>pind</Text>
          </View>
          {onCancel ? (
            <Pressable accessibilityRole="button" onPress={onCancel} style={styles.closeButton}>
              <Text style={styles.closeText}>Close</Text>
            </Pressable>
          ) : (
            <Text style={styles.city}>KOREA · FAST MVP</Text>
          )}
        </View>

        <Text style={styles.eyebrow}>{editing ? 'YOUR TASTE PROFILE' : 'MAKE IT YOURS'}</Text>
        <Text style={styles.title}>Find food that feels like you.</Text>
        <Text style={styles.subtitle}>
          Skip the stars. Pick at least three things you genuinely enjoy and we’ll shape your Korea map.
        </Text>

        <View style={styles.groups}>
          {axisOrder.map((axis) => (
            <View key={axis} style={styles.group}>
              <Text style={styles.groupLabel}>{axisLabels[axis]}</Text>
              <View style={styles.pillWrap}>
                {(groupedTags.get(axis) ?? []).map((tag) => (
                  <TastePill
                    key={tag.code}
                    tag={tag}
                    selected={selectedCodes.has(tag.code)}
                    onPress={() => toggle(tag.code)}
                  />
                ))}
              </View>
            </View>
          ))}
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <Text style={styles.selectionCount}>
          {selectedCodes.size < 3 ? `${3 - selectedCodes.size} more to go` : `${selectedCodes.size} tastes selected`}
        </Text>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ disabled: !canContinue }}
          disabled={!canContinue}
          onPress={() => onComplete([...selectedCodes])}
          style={({ pressed }) => [styles.primaryButton, !canContinue && styles.buttonDisabled, pressed && canContinue && styles.buttonPressed]}
        >
          <Text style={styles.primaryButtonText}>{editing ? 'Update my map' : 'Taste Korea this way'}</Text>
          <Text style={styles.arrow}>→</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: colors.canvas,
    flex: 1,
  },
  content: {
    paddingBottom: 30,
    paddingHorizontal: 22,
    paddingTop: 10,
  },
  topRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 56,
  },
  wordmarkRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 9,
  },
  logoDot: {
    backgroundColor: colors.coral,
    borderRadius: 8,
    height: 16,
    transform: [{ rotate: '45deg' }],
    width: 16,
  },
  wordmark: {
    color: colors.ink,
    fontSize: 24,
    fontWeight: '900',
    letterSpacing: -1,
  },
  city: {
    color: colors.muted,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.2,
  },
  closeButton: {
    padding: 8,
  },
  closeText: {
    color: colors.plum,
    fontSize: 15,
    fontWeight: '700',
  },
  eyebrow: {
    color: colors.coral,
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.8,
    marginBottom: 12,
  },
  title: {
    color: colors.ink,
    fontSize: 43,
    fontWeight: '900',
    letterSpacing: -2.1,
    lineHeight: 46,
    maxWidth: 330,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 17,
    lineHeight: 25,
    marginTop: 18,
    maxWidth: 350,
  },
  groups: {
    gap: 30,
    marginTop: 42,
  },
  group: {
    gap: 12,
  },
  groupLabel: {
    color: colors.muted,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.5,
  },
  pillWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  footer: {
    backgroundColor: colors.canvas,
    borderTopColor: colors.line,
    borderTopWidth: 1,
    paddingBottom: 10,
    paddingHorizontal: 22,
    paddingTop: 12,
  },
  selectionCount: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 9,
    textAlign: 'center',
  },
  primaryButton: {
    alignItems: 'center',
    backgroundColor: colors.ink,
    borderRadius: 18,
    flexDirection: 'row',
    justifyContent: 'center',
    minHeight: 58,
    paddingHorizontal: 22,
  },
  buttonDisabled: {
    opacity: 0.28,
  },
  buttonPressed: {
    transform: [{ scale: 0.99 }],
  },
  primaryButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '800',
  },
  arrow: {
    color: colors.coral,
    fontSize: 24,
    marginLeft: 12,
  },
});
