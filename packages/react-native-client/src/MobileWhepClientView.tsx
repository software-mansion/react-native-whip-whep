import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { MobileWhepClientViewProps } from './MobileWhepClient.types';

const NativeView: React.ComponentType<MobileWhepClientViewProps> =
  requireNativeViewManager('MobileWhepClient');

export default function MobileWhepClientView(props: MobileWhepClientViewProps) {
  return <NativeView {...props} />;
}
