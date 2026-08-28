import { useColorScheme as useRNColorScheme } from 'react-native';

/**
 * React Native 0.86 widened `useColorScheme()` to return `'unspecified'` alongside
 * `'light' | 'dark'`, and it no longer returns null. `'unspecified'` cannot index the `Colors`
 * palette, so collapse it onto the two themes the app actually defines.
 */
export function useColorScheme(): 'light' | 'dark' {
  return useRNColorScheme() === 'dark' ? 'dark' : 'light';
}
