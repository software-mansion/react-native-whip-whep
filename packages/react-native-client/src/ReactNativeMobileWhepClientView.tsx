import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhepClientViewProps,
} from "./ReactNativeMobileWhepClient.types";

const NativeView: React.ComponentType<
  ReactNativeMobileWhepClientViewProps & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeMobileWhepClientViewModule");

/**
 * A component that renders a native view for WHEP player type.
 *
 * This component forwards a ref to the native view, allowing for direct manipulation
 * of the component instance. It accepts style and other props defined in
 * ReactNativeMobileWhepClientViewProps.
 *
 * @param {ReactNativeMobileWhepClientViewProps} props - The properties to customize the component.
 * @param {React.ForwardedRef<React.ComponentType<ReactNativeMobileWhepClientViewProps>>} ref - Ref to the component instance.
 * @returns {JSX.Element} The rendered component.
 */
export const WhepClientView = React.forwardRef<
  React.ComponentType<ReactNativeMobileWhepClientViewProps>,
  ReactNativeMobileWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHEP} ref={ref} />
));

/**
 * A component that renders a native view for WHIP player type.
 *
 * This component forwards a ref to the native view, allowing for direct manipulation
 * of the component instance. It accepts style and other props defined in
 * ReactNativeMobileWhepClientViewProps.
 *
 * @param {ReactNativeMobileWhepClientViewProps} props - The properties to customize the component.
 * @param {React.ForwardedRef<React.ComponentType<ReactNativeMobileWhepClientViewProps>>} ref - Ref to the component instance.
 * @returns {JSX.Element} The rendered component.
 */
export const WhipClientView = React.forwardRef<
  React.ComponentType<ReactNativeMobileWhepClientViewProps>,
  ReactNativeMobileWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHIP} ref={ref} />
));
