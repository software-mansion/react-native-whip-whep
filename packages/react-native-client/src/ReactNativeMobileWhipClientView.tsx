import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  ReactNativeMobileWhipClientViewProps,
} from "./ReactNativeMobileWhepClient.types";

const NativeViewBase: React.ComponentType<
  ReactNativeMobileWhipClientViewProps
> = requireNativeViewManager("ReactNativeMobileWhipClientViewModule");

const NativeView = NativeViewBase as React.ComponentType<
  ReactNativeMobileWhipClientViewProps
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
  <NativeView {...props} />
);
