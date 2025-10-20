import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import {
  PlayerType,
  ReactNativeMobileWhepClientViewProps,
  WhepClientViewRef,
  WhepConfigurationOptions,
  ReceiverVideoCodecName,
  ReceiverAudioCodecName,
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
 * This component accepts style and other props defined in
 * ReactNativeMobileWhepClientViewProps.
 *
 * @param {ReactNativeMobileWhepClientViewProps & { ref?: React.Ref<WhepClientViewRef> }} props - The properties to customize the component.
 * @returns {JSX.Element} The rendered component.
 */
export function WhepClientView(
  props: ReactNativeMobileWhepClientViewProps & {
    ref?: React.Ref<WhepClientViewRef>;
  },
) {
  const { ref, ...rest } = props;
  const nativeRef = React.useRef<WhepClientViewRef>(null);

  /**
   * WORKAROUND: Race condition with Expo's ConcurrentFunctionDefinition
   *
   * The native view is created on a different queue than the function initialization,
   * which can cause functions to be called before the view is fully created.
   *
   * This results in errors like:
   * ```
   * Error: Calling the function has failed
   *   Caused by: The 1st argument cannot be cast to type View<ReactNativeMobileWhepClientView>
   *   Caused by: Unable to find the 'ReactNativeMobileWhepClientView' view with tag 'XXX'
   *   code: 'ERR_ARGUMENT_CAST'
   * ```
   *
   * Additionally, without this workaround, the video renderer may not have a valid surface,
   * causing "EglRenderer: Dropping frame - No surface" errors.
   *
   * The `setTimeout(0)` defers execution to the next event loop tick, which seems like enough for the view to be created.
   *
   * This is the how they are trying to solving as of writing this comment: https://github.com/expo/expo/blob/3f3ad4f6f9ea096bb003c4345f0a09f2a41b3f25/packages/expo-modules-core/ios/Core/Functions/AsyncFunctionDefinition.swift#L125
   * This might get fixed in the future and setTimeout won't be needed anymore.
   */
  React.useImperativeHandle(ref, () => ({
    createWhepClient: async (
      configurationOptions: WhepConfigurationOptions,
      preferredVideoCodecs?: ReceiverVideoCodecName[],
      preferredAudioCodecs?: ReceiverAudioCodecName[],
    ) => {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          nativeRef.current
            ?.createWhepClient(
              configurationOptions,
              preferredVideoCodecs,
              preferredAudioCodecs,
            )
            .then(() => {
              resolve();
            })
            .catch((error) => {
              reject(error);
            });
        }, 0);
      });
    },
    connect: async (options) => {
      await nativeRef.current?.connect(options);
    },
    disconnect: async () => {
      await nativeRef.current?.disconnect();
    },
    pause: async () => {
      await nativeRef.current?.pause();
    },
    unpause: async () => {
      await nativeRef.current?.unpause();
    },
    cleanup: async () => {
      await nativeRef.current?.cleanup();
    },
    getSupportedReceiverVideoCodecsNames: async () => {
      return (
        (await nativeRef.current?.getSupportedReceiverVideoCodecsNames()) ?? []
      );
    },
    getSupportedReceiverAudioCodecsNames: async () => {
      return (
        (await nativeRef.current?.getSupportedReceiverAudioCodecsNames()) ?? []
      );
    },
    setPreferredReceiverVideoCodecs: async (preferredCodecs) => {
      await nativeRef.current?.setPreferredReceiverVideoCodecs(preferredCodecs);
    },
    setPreferredReceiverAudioCodecs: async (preferredCodecs) => {
      await nativeRef.current?.setPreferredReceiverAudioCodecs(preferredCodecs);
    },
    startPip: async () => {
      await nativeRef.current?.startPip();
    },
    stopPip: async () => {
      await nativeRef.current?.stopPip();
    },
    togglePip: async () => {
      await nativeRef.current?.togglePip();
    },
  }));

  return <NativeView {...rest} playerType={PlayerType.WHEP} ref={nativeRef} />;
}
