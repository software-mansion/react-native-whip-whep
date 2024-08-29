import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';
const NativeView = requireNativeViewManager('MobileWhepClient');
export default function MobileWhepClientView(props) {
    return <NativeView {...props}/>;
}
//# sourceMappingURL=MobileWhepClientView.js.map