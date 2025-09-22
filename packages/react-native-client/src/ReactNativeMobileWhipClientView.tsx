import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhipClientViewProps,
} from "./ReactNativeMobileWhepClient.types";

const NativeViewBase: React.ComponentType<
  ReactNativeMobileWhipClientViewProps  & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeMobileWhipClientViewModule");

const NativeView = NativeViewBase as React.ComponentType<
  ReactNativeMobileWhipClientViewProps  & {
    playerType: PlayerType;
  }
>;

/**
 * A component that renders a native view for WHIP player type.
 *
 * This component accepts style and other props defined in
 * ReactNativeMobileWhipClientViewProps.
 *
 * @param {ReactNativeMobileWhipClientViewProps} props - The properties to customize the component.
 * @returns {JSX.Element} The rendered component.
 */
export const WhipClientView: React.FC<ReactNativeMobileWhipClientViewProps> = (props) => (
  <NativeView {...props} playerType={PlayerType.WHIP} />
);
