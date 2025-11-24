import { requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

import { CameraId } from "./ReactNativeMobileWhepClient.types";

/** Describes whether the camera is front-facing or back-facing. */
export type CameraFacingDirection = "front" | "back" | "unspecified";

/** Contains information about the camera available on the device. */
export type Camera = {
  /** A unique ID of the camera.  */
  id: CameraId;
  /** A string describing camera name. */
  name: string;
  /** Information about the camera being a front one or back one. */
  facingDirection: CameraFacingDirection;
};

type RNMobileWhipClientViewModule = {
  cameras: readonly Camera[];
};

export const ReceivableEvents = {
  WhipPeerConnectionStateChanged: "WhipPeerConnectionStateChanged",
  Warning: "Warning",
  ScreenSharingPermissionDenied: "ScreenSharingPermissionDenied",
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
  [ReceivableEvents.WhipPeerConnectionStateChanged]: PeerConnectionState;
  [ReceivableEvents.Warning]: string;
  [ReceivableEvents.ScreenSharingPermissionDenied]: string;
};

const nativeViewModule = requireNativeModule(
  "ReactNativeMobileWhipClientViewModule",
) as RNMobileWhipClientViewModule &
  NativeModule<Record<keyof typeof ReceivableEvents, (payload: any) => void>>;

/** Gives access to the cameras available on the device.*/
export const cameras = nativeViewModule.cameras;

export default nativeViewModule;
