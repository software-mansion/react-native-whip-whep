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

export class WhepClient {
  private isInitialized = false;

  constructor(private readonly configurationOptions: WhepConfigurationOptions) {
    this.initializeIfNeeded();
  }

  private initializeIfNeeded() {
    if (!this.isInitialized) {
      nativeModule.createWhepClient(this.configurationOptions);
      this.isInitialized = true;
    }
  }

  /**
   * Connects to the WHEP server defined while creating WHEP client.
   * Allows user to receive video and audio stream.
   */
  async connect(connectOptions: ConnectOptions) {
    this.initializeIfNeeded();
    await nativeModule.connectWhep(
      connectOptions.serverUrl,
      connectOptions.authToken,
    );
  }

  /**
   * Disconnects from the WHEP server defined while creating WHEP client.
   * Frees the resources.
   */
  disconnect() {
    nativeModule.disconnectWhep();
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
