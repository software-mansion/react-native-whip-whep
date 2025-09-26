import { requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

export const ReceivableEvents = {
  WhepPeerConnectionStateChanged: "WhepPeerConnectionStateChanged",
  ReconnectionStatusChanged: "ReconnectionStatusChanged",
  Warning: "Warning",
} as const;

export type PeerConnectionState =
  | "new"
  | "connecting"
  | "connected"
  | "disconnected"
  | "failed"
  | "closed"
  | "unknown";

export type ReceivableEventPayloads = {
  [ReceivableEvents.ReconnectionStatusChanged]:
    | "reconnectionStarted"
    | "reconnected"
    | "reconnectionRetriesLimitReached";

  [ReceivableEvents.WhepPeerConnectionStateChanged]: PeerConnectionState;
  [ReceivableEvents.Warning]: string;
};

type RNMobileWhepClientViewModule = {
  whepPeerConnectionState: PeerConnectionState | null;
};

const nativeViewModule = requireNativeModule(
  "ReactNativeMobileWhepClientViewModule",
) as RNMobileWhepClientViewModule &
  NativeModule<Record<keyof typeof ReceivableEvents, (payload: any) => void>>;

/** Gives access to the current state of the WHEP peer connection. */
export const whepPeerConnectionState = nativeViewModule.whepPeerConnectionState;

export default nativeViewModule;
