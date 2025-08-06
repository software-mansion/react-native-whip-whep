import { requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

import {
  WhipConfigurationOptions,
  CameraId,
  ConnectOptions,
  WhepConfigurationOptions,
} from "./ReactNativeMobileWhepClient.types";

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

type RNMobileWhepClientModule = {
  createWhepClient: (configurationOptions?: WhepConfigurationOptions) => void;
  connectWhep: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnectWhep: () => void;
  pauseWhep: () => void;
  unpauseWhep: () => void;
  createWhipClient: (configurationOptions: WhipConfigurationOptions) => void;
  connectWhip: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnectWhip: () => void;
  cameras: readonly Camera[];
  whepPeerConnectionState: PeerConnectionState | null;
  whipPeerConnectionState: PeerConnectionState | null;
  getSupportedSenderVideoCodecsNames: () => Promise<string[]>;
};

export const ReceivableEvents = {
  WhepPeerConnectionStateChanged: "WhepPeerConnectionStateChanged",
  WhipPeerConnectionStateChanged: "WhipPeerConnectionStateChanged",
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
  [ReceivableEvents.WhipPeerConnectionStateChanged]: PeerConnectionState;
  [ReceivableEvents.Warning]: string;
};

const nativeModule = requireNativeModule(
  "ReactNativeMobileWhepClient",
) as RNMobileWhepClientModule &
  NativeModule<Record<keyof typeof ReceivableEvents, (payload: any) => void>>;

/** Creates a WHEP client based on the `configurationOptions`.
 *  It is a first step before connecting to the server.
 */
export function createWhepClient(
  /** Additional configuration options. */
  configurationOptions?: WhepConfigurationOptions,
) {
  return nativeModule.createWhepClient(configurationOptions);
}

/** Connects to the WHEP server defined while creating WHEP client.
 * Allows user to receive video and audio stream.
 */
export async function connectWhepClient(connectOptions: ConnectOptions) {
  return await nativeModule.connectWhep(
    connectOptions.serverUrl,
    connectOptions.authToken,
  );
}

/** Disconnects from the WHEP server defined while creating WHEP client.
 * Frees the resources.
 */
export function disconnectWhepClient() {
  return nativeModule.disconnectWhep();
}

/** Pauses the WHEP stream, making the view black and disabling the sound. */
export function pauseWhepClient() {
  return nativeModule.pauseWhep();
}

/** Restarts the WHEP stream. Makes the view reappear along with sound. */
export function unpauseWhepClient() {
  return nativeModule.unpauseWhep();
}

export class WhipClient {
  private isInitialized = false;

  constructor(private readonly configurationOptions: WhipConfigurationOptions) {
    this.initializeIfNeeded();
    console.warn("WhipClient constructor");
  }

  private initializeIfNeeded() {
    if (!this.isInitialized) {
      nativeModule.createWhipClient(this.configurationOptions);
      this.isInitialized = true;
    }
  }

  async connect(connectOptions: ConnectOptions) {
    this.initializeIfNeeded();
    await nativeModule.connectWhip(
      connectOptions.serverUrl,
      connectOptions.authToken,
    );
  }

  disconnect() {
    nativeModule.disconnectWhip();
    this.isInitialized = false;
  }
}

/** Gives access to the cameras available on the device.*/
export const cameras = nativeModule.cameras;

/** Gives access to the current state of the WHEP peer connection. */
export const whepPeerConnectionState = nativeModule.whepPeerConnectionState;

/** Gives access to the current state of the WHIP peer connection. */
export const whipPeerConnectionState = nativeModule.whipPeerConnectionState;

export default nativeModule;
