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
        tabBarActiveTintColor: Colors[colorScheme ?? 'light'].tint,
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
        }}
      />
      <Tabs.Screen
        name="whip"
        options={{
          title: 'Whip',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              name={focused ? 'log-out' : 'log-out-outline'}
              color={color}
            />
          ),
        }}
      />
    </Tabs>
  );
}
