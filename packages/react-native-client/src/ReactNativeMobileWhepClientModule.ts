import { requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

import {
  WhipConfigurationOptions,
  CameraId,
  ConnectOptions,
  WhepConfigurationOptions,
  SenderAudioCodecName,
  SenderVideoCodecName,
  ReceiverAudioCodecName,
  ReceiverVideoCodecName,
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
  cameras: readonly Camera[];
  whepPeerConnectionState: PeerConnectionState | null;
  whipPeerConnectionState: PeerConnectionState | null;
  createWhepClient: (
    configurationOptions: WhepConfigurationOptions,
    preferredVideoCodecs: ReceiverVideoCodecName[],
    preferredAudioCodecs: ReceiverAudioCodecName[],
  ) => void;
  connectWhep: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnectWhep: () => Promise<void>;
  pauseWhep: () => void;
  unpauseWhep: () => void;
  createWhipClient: (
    configurationOptions: WhipConfigurationOptions,
    preferredVideoCodecs: SenderVideoCodecName[],
    preferredAudioCodecs: SenderAudioCodecName[],
  ) => void;
  connectWhip: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnectWhip: () => Promise<void>;
  switchCamera: (deviceId: string) => Promise<void>;
  cleanupWhip: () => void;

  // Codecs
  getSupportedSenderVideoCodecsNames: () => SenderVideoCodecName[];
  getSupportedReceiverVideoCodecsNames: () => ReceiverVideoCodecName[];
  getSupportedReceiverAudioCodecsNames: () => ReceiverAudioCodecName[];
  getSupportedSenderAudioCodecsNames: () => SenderAudioCodecName[];
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

  constructor(
    private readonly configurationOptions: WhipConfigurationOptions,
    private readonly preferredVideoCodecs: SenderVideoCodecName[] = [],
    private readonly preferredAudioCodecs: SenderAudioCodecName[] = [],
  ) {
    this.initializeIfNeeded();
  }

  private initializeIfNeeded() {
    if (!this.isInitialized) {
      nativeModule.createWhipClient(
        this.configurationOptions,
        this.preferredVideoCodecs,
        this.preferredAudioCodecs,
      );
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
  async disconnect() {
    await nativeModule.disconnectWhip();
    this.isInitialized = false;
  }

  async cleanup() {
    nativeModule.cleanupWhip();
  }

  async switchCamera(deviceId: string) {
    nativeModule.switchCamera(deviceId);
  }

  async flipCamera(): Promise<CameraId | undefined> {
    // Find the opposite camera (front/back)
    const currentCamera = cameras.find(
      (cam) => cam.id === this.configurationOptions.videoDeviceId,
    );
    const oppositeCamera = cameras.find(
      (cam) =>
        cam.facingDirection !== currentCamera?.facingDirection &&
        cam.facingDirection !== "unspecified",
    );

    if (oppositeCamera) {
      await this.switchCamera(oppositeCamera.id);
      this.configurationOptions.videoDeviceId = oppositeCamera.id;
      return oppositeCamera.id;
    } else {
      console.warn("Unable to find opposite camera to switch to");
      return undefined;
    }
  }

  static getSupportedAudioCodecs() {
    return nativeModule.getSupportedSenderAudioCodecsNames();
  }

  static getSupportedVideoCodecs() {
    return nativeModule.getSupportedSenderVideoCodecsNames();
  }
}

export class WhepClient {
  private isInitialized = false;

  constructor(
    private readonly configurationOptions: WhepConfigurationOptions,
    private readonly preferredVideoCodecs: ReceiverVideoCodecName[] = [],
    private readonly preferredAudioCodecs: ReceiverAudioCodecName[] = [],
  ) {
    this.initializeIfNeeded();
  }

  private initializeIfNeeded() {
    if (!this.isInitialized) {
      nativeModule.createWhepClient(
        this.configurationOptions,
        this.preferredVideoCodecs,
        this.preferredAudioCodecs,
      );
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
  async disconnect() {
    await nativeModule.disconnectWhep();
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
