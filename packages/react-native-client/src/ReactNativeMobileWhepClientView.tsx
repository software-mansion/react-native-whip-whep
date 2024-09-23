import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhepClientViewProps,
} from "./ReactNativeMobileWhepClient.types";

const NativeView: React.ComponentType<
  ReactNativeMobileWhepClientViewProps & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeMobileWhepClientViewModule");

export const WhepClientView = React.forwardRef<
  React.ComponentType<ReactNativeMobileWhepClientViewProps>,
  ReactNativeMobileWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHEP} ref={ref} />
));

export const WhipClientView = React.forwardRef<
  React.ComponentType<ReactNativeMobileWhepClientViewProps>,
  ReactNativeMobileWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHIP} ref={ref} />
));
