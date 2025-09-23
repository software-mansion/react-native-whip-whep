import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhepClientViewProps,
  WhepClientViewRef,
} from "./ReactNativeMobileWhepClient.types";

const NativeViewBase: React.ComponentType<
  ReactNativeMobileWhepClientViewProps & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeMobileWhepClientViewModule");

const NativeView = NativeViewBase as React.ComponentType<
  ReactNativeMobileWhepClientViewProps & {
    playerType: PlayerType;
    ref?: React.Ref<WhepClientViewRef>;
  }
>;

/**
 * A component that renders a native view for WHEP player type.
 *
 * This component forwards a ref to the native view, allowing for direct manipulation
 * of the component instance. It accepts style and other props defined in
 * ReactNativeMobileWhepClientViewProps.
 *
 * @param {ReactNativeMobileWhepClientViewProps} props - The properties to customize the component.
 * @param {React.ForwardedRef<WhepClientViewRef>} ref - Ref to the component instance.
 * @returns {JSX.Element} The rendered component.
 */
export const WhepClientView = React.forwardRef<
  WhepClientViewRef,
  ReactNativeMobileWhepClientViewProps
>((props, ref) => (
  <NativeView {...props} playerType={PlayerType.WHEP} ref={ref} />
));
