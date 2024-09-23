import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { PlayerType, WhipWhepClientViewProps } from "./ReactNativeClient.types";

const NativeView: React.ComponentType<
  WhipWhepClientViewProps & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeClientViewModule");

export const WhepClientView = React.forwardRef<
  React.ComponentType<WhipWhepClientViewProps>,
  WhipWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHEP} ref={ref} />
));

export const WhipClientView = React.forwardRef<
  React.ComponentType<WhipWhepClientViewProps>,
  WhipWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHIP} ref={ref} />
));
