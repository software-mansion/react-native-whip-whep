import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

const NativeView: React.ComponentType = requireNativeViewManager(
  "ReactNativeClientViewModule"
);

export const ReactNativeClientView = React.forwardRef<React.ComponentType>(
  (props, ref) => (
    // @ts-expect-error ref prop needs to be updated
    <NativeView {...props} ref={ref} />
  )
);
