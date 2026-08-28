/**
 * Learn more about light and dark modes:
 * https://docs.expo.dev/guides/color-schemes/
 */

import { useColorScheme } from '@/hooks/useColorScheme';

import { Colors } from '@/constants/Colors';

export function useThemeColor() {
  const theme = useColorScheme();

  return Colors[theme];
}
