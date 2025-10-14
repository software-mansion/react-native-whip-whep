import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhipClientViewProps,
  WhipClientViewRef,
  WhipConfigurationOptions,
} from "./ReactNativeMobileWhepClient.types";

const NativeViewBase: React.ComponentType<
  ReactNativeMobileWhipClientViewProps & { playerType: PlayerType }
> = requireNativeViewManager("ReactNativeMobileWhipClientViewModule");

const NativeView = NativeViewBase as React.ComponentType<
  ReactNativeMobileWhipClientViewProps & {
    playerType: PlayerType;
    ref?: React.Ref<WhipClientViewRef>;
  }
>;

/**
 * A component that renders a native view for WHIP player type.
 *
 * This component accepts style and other props defined in
 * ReactNativeMobileWhipClientViewProps.
 *
 * @param {ReactNativeMobileWhipClientViewProps & { ref?: React.Ref<WhipClientViewRef> }} props - The properties to customize the component.
 * @returns {JSX.Element} The rendered component.
 */
export function WhipClientView(
  props: ReactNativeMobileWhipClientViewProps & {
    ref?: React.Ref<WhipClientViewRef>;
  },
) {
  const { ref, ...rest } = props;
  const nativeRef = React.useRef<WhipClientViewRef>(null);

  /**
   * WORKAROUND: Race condition with Expo's ConcurrentFunctionDefinition
   *
   * The native view is created on a different queue than the function initialization,
   * which can cause `initializeCamera` to be called before the view is fully created.
   *
   * This results in the following error:
   * ```
   * Error: Calling the 'initializeCamera' function has failed
   *   Caused by: The 1st argument cannot be cast to type View<ReactNativeMobileWhipClientView>
   *   Caused by: Unable to find the 'ReactNativeMobileWhipClientView' view with tag '122'
   *   code: 'ERR_ARGUMENT_CAST'
   * ```
   *
   * The `setTimeout(0)` defers execution to the next event loop tick, which seems like enough for the view to be created.
   *
   * This is the how they are trying to solving as of writing this comment: https://github.com/expo/expo/blob/3f3ad4f6f9ea096bb003c4345f0a09f2a41b3f25/packages/expo-modules-core/ios/Core/Functions/AsyncFunctionDefinition.swift#L125
   * This might get fixed in the future and setTimeout won't be needed anymore.
   */
  React.useImperativeHandle(ref, () => ({
    initializeCamera: async (options: WhipConfigurationOptions) => {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          nativeRef.current
            ?.initializeCamera(options)
            .then(() => {
              resolve();
            })
            .catch((error) => {
              reject(error);
            });
        }, 0);
      });
    },
    connect: async (serverUrl: string, authToken?: string) => {
      await nativeRef.current?.connect(serverUrl, authToken);
    },
    disconnect: async () => {
      await nativeRef.current?.disconnect();
    },
    switchCamera: async (deviceId: string) => {
      await nativeRef.current?.switchCamera(deviceId);
    },
    flipCamera: async () => {
      await nativeRef.current?.flipCamera();
    },
    cleanupWhip: async () => {
      await nativeRef.current?.cleanupWhip();
    },
    setPreferredSenderVideoCodecs: async (preferredCodecs) => {
      await nativeRef.current?.setPreferredSenderVideoCodecs(preferredCodecs);
    },
    setPreferredSenderAudioCodecs: async (preferredCodecs) => {
      await nativeRef.current?.setPreferredSenderAudioCodecs(preferredCodecs);
    },
    getSupportedSenderVideoCodecsNames: async () => {
      return (
        (await nativeRef.current?.getSupportedSenderVideoCodecsNames()) ?? []
      );
    },
    getSupportedSenderAudioCodecsNames: async () => {
      return (
        (await nativeRef.current?.getSupportedSenderAudioCodecsNames()) ?? []
      );
    },
    currentCameraDeviceId: async () => {
      return (await nativeRef.current?.currentCameraDeviceId()) ?? "";
    },
  }));

  return <NativeView {...rest} playerType={PlayerType.WHIP} ref={nativeRef} />;
}
