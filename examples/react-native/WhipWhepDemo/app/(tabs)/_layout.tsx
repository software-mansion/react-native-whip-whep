import { Tabs } from 'expo-router';
import React from 'react';

import { TabBarIcon } from '@/components/navigation/TabBarIcon';
import { Colors } from '@/constants/Colors';
import { useColorScheme } from '@/hooks/useColorScheme';

export default function TabLayout() {
  const colorScheme = useColorScheme();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Colors[colorScheme ?? 'light'].tabIconSelected,
        tabBarInactiveTintColor: Colors[colorScheme ?? 'light'].tabIconDefault,
        headerShown: false,
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Whep',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              name={focused ? 'log-in' : 'log-in-outline'}
              color={color}
            />
          ),
          freezeOnBlur: true,
        }}
      />
      <Tabs.Screen
        name="whipTab"
        options={{
          title: 'Whip',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              name={focused ? 'log-out' : 'log-out-outline'}
              color={color}
            />
          ),
          freezeOnBlur: true,
        }}
      />
    </Tabs>
  );
}
