import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import { ReactNativeClientViewProps } from "./ReactNativeClient.types";

const NativeView: React.ComponentType<ReactNativeClientViewProps> =
  requireNativeViewManager("ReactNativeClientViewModule");

export const ReactNativeClientView = React.forwardRef<
  React.ComponentType<ReactNativeClientViewProps>,
  ReactNativeClientViewProps
>((props, ref) => (
  // @ts-expect-error ref prop needs to be updated
  <NativeView {...props} ref={ref} />
));
