import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors } from '../theme/colors';

export type MainTab = 'map' | 'logs';

type Props = {
  activeTab: MainTab;
  canCreate: boolean;
  onChange: (tab: MainTab) => void;
  onCreate: () => void;
};

export function MainTabBar({ activeTab, canCreate, onChange, onCreate }: Props) {
  return (
    <View style={styles.safeArea}>
      <View style={styles.bar}>
        <TabButton active={activeTab === 'map'} icon="⌖" label="Map" onPress={() => onChange('map')} />
        <Pressable
          accessibilityLabel="Create a new log"
          accessibilityRole="button"
          disabled={!canCreate}
          onPress={onCreate}
          style={[styles.createButton, !canCreate && styles.createButtonDisabled]}
        >
          <Text style={styles.createIcon}>＋</Text>
        </Pressable>
        <TabButton active={activeTab === 'logs'} icon="▤" label="Logs" onPress={() => onChange('logs')} />
      </View>
    </View>
  );
}

function TabButton({ active, icon, label, onPress }: { active: boolean; icon: string; label: string; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected: active }}
      onPress={onPress}
      style={styles.tabButton}
    >
      <Text style={[styles.tabIcon, active && styles.tabActive]}>{icon}</Text>
      <Text style={[styles.tabLabel, active && styles.tabActive]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: colors.white, paddingBottom: 15 },
  bar: {
    alignItems: 'center',
    borderTopColor: colors.line,
    borderTopWidth: 1,
    flexDirection: 'row',
    height: 66,
    justifyContent: 'space-around',
    paddingHorizontal: 32,
  },
  tabButton: { alignItems: 'center', justifyContent: 'center', minWidth: 72, paddingVertical: 8 },
  tabIcon: { color: colors.muted, fontSize: 23, fontWeight: '700' },
  tabLabel: { color: colors.muted, fontSize: 10, fontWeight: '800', marginTop: 2 },
  tabActive: { color: colors.plum },
  createButton: {
    alignItems: 'center',
    backgroundColor: colors.ink,
    borderColor: colors.white,
    borderRadius: 28,
    borderWidth: 4,
    height: 56,
    justifyContent: 'center',
    marginTop: -22,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    width: 56,
  },
  createButtonDisabled: { opacity: 0.4 },
  createIcon: { color: colors.white, fontSize: 30, lineHeight: 33 },
});
