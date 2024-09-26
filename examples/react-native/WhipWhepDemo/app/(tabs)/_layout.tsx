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
              name={focused ? 'globe' : 'globe-outline'}
              color={color}
            />
          ),
          unmountOnBlur: true,
        }}
      />
      <Tabs.Screen
        name="whep"
        options={{
          title: 'Whep (server)',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              name={focused ? 'log-out' : 'log-out-outline'}
              color={color}
            />
          ),
          unmountOnBlur: true,
        }}
      />
      <Tabs.Screen
        name="whip"
        options={{
          title: 'Whip (server)',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              name={focused ? 'log-out' : 'log-out-outline'}
              color={color}
            />
          ),
          unmountOnBlur: true,
        }}
      />
    </Tabs>
  );
}
