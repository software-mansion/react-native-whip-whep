import { Button, View } from 'react-native';
import React from 'react';
import { Link } from 'expo-router';
import { styles } from '../../styles/styles';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function WhipTab() {
  const { tint } = useThemeColor();

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <Link href="/whip" asChild>
          <Button title="Open WHIP Player" color={tint} />
        </Link>
      </View>
    </View>
  );
}
