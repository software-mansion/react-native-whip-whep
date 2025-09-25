import { requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

import {
  ConnectOptions,
  WhepConfigurationOptions,
  ReceiverAudioCodecName,
  ReceiverVideoCodecName,
} from "./ReactNativeMobileWhepClient.types";

type RNMobileWhepClientModule = {
  whepPeerConnectionState: PeerConnectionState | null;
  createWhepClient: (
    configurationOptions: WhepConfigurationOptions,
    preferredVideoCodecs: ReceiverVideoCodecName[],
    preferredAudioCodecs: ReceiverAudioCodecName[],
  ) => void;
  connectWhep: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnectWhep: () => Promise<void>;
  pauseWhep: () => void;
  unpauseWhep: () => void;

  // Codecs
  getSupportedReceiverVideoCodecsNames: () => ReceiverVideoCodecName[];
  getSupportedReceiverAudioCodecsNames: () => ReceiverAudioCodecName[];
};

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

const nativeModule = requireNativeModule(
  "ReactNativeMobileWhepClient",
) as RNMobileWhepClientModule &
  NativeModule<Record<keyof typeof ReceivableEvents, (payload: any) => void>>;

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

/** Gives access to the current state of the WHEP peer connection. */
export const whepPeerConnectionState = nativeModule.whepPeerConnectionState;

export default nativeModule;
