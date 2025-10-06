import { Button, View } from 'react-native';
import React from 'react';
import { Link } from 'expo-router';
import { styles } from '../../styles/styles';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const { tint } = useThemeColor();

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <Link href="/whep" asChild>
          <Button title="Open WHEP Player" color={tint} onPress={() => {}} />
        </Link>
      </View>
    </View>
  );
}
