import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import { ReactNativeClientViewProps } from "./ReactNativeClient.types";

const NativeView: React.ComponentType<ReactNativeClientViewProps> =
  requireNativeViewManager("ReactNativeClient");

export default function ReactNativeClientView(
  props: ReactNativeClientViewProps
) {
  return <NativeView {...props} />;
}
