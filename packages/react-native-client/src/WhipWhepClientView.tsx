import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { WhipWhepClientViewProps } from "./ReactNativeClient.types";

const NativeView: React.ComponentType<WhipWhepClientViewProps> =
  requireNativeViewManager("ReactNativeClientViewModule");

export const WhipWhepClientView = React.forwardRef<
  React.ComponentType<WhipWhepClientViewProps>,
  WhipWhepClientViewProps
>((props, ref) => (
  // @ts-expect-error ref prop needs to be updated
  <NativeView {...props} ref={ref} />
));
