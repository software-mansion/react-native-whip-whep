import { View, type ViewProps } from 'react-native';

import { useThemeColor } from '@/hooks/useThemeColor';

export function ThemedView({ style, ...otherProps }: ViewProps) {
  const { background: backgroundColor } = useThemeColor();

  return <View style={[{ backgroundColor }, style]} {...otherProps} />;
}
