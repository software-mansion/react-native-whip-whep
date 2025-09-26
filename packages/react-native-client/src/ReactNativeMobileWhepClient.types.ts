// branded types are useful for restricting where given value can be passed
declare const brand: unique symbol;
export type Brand<T, TBrand extends string> = T & { [brand]: TBrand };

/** A unique ID of the camera.  */
export type CameraId = Brand<string, "CameraId">;

/** Name of the codec.  */
export type SenderAudioCodecName = Brand<string, "SenderAudioCodecName">;
export type SenderVideoCodecName = Brand<string, "SenderVideoCodecName">;
export type ReceiverAudioCodecName = Brand<string, "ReceiverAudioCodecName">;
export type ReceiverVideoCodecName = Brand<string, "ReceiverVideoCodecName">;

export type ConnectOptions = {
  /** Authorization token that might be required to access the server. */
  authToken?: string;
  /** URL address of the server. */
  serverUrl: string;
};

/** Defines initial WHIP Client options. */
export type WhipConfigurationOptions = {
  /** A variable deciding whether the audio should be streamed or not. Defaults to true. */
  audioEnabled?: boolean;
  /** A variable deciding whether the video should be streamed or not. Defaults to true. */
  videoEnabled?: boolean;
  /** ID of the camera.  */
  videoDeviceId?: CameraId;
  /** Defines the parameters of the video. Defaults to HD43. */
  videoParameters?: VideoParameters;
  /** URL address of the STUN server. The default one is `stun.l.google.com`. */
  stunServerUrl?: string;
};

/** Defines initial WHEP Client options. */
export type WhepConfigurationOptions = {
  /** A variable deciding whether the audio should be streamed or not. Defaults to true. */
  audioEnabled?: boolean;
  /** A variable deciding whether the video should be streamed or not. Defaults to true. */
  videoEnabled?: boolean;
  /** URL address of the STUN server. The default one is `stun.l.google.com`. */
  stunServerUrl?: string;
};

/**
 * A type that represents the ref to the WhepClientView component.
 * It contains methods to control the WHEP client and Picture-in-Picture mode.
 */
export type WhepClientViewRef = {
  /**
   * Creates a WHEP client with the given configuration.
   */
  createWhepClient: (
    configurationOptions: WhepConfigurationOptions,
    preferredVideoCodecs?: ReceiverVideoCodecName[],
    preferredAudioCodecs?: ReceiverAudioCodecName[],
  ) => Promise<void>;
  /**
   * Connects to the WHEP server.
   */
  connectWhep: (ConnectOptions) => Promise<void>;
  /**
   * Disconnects from the WHEP server.
   */
  disconnectWhep: () => Promise<void>;
  /**
   * Pauses the WHEP client stream.
   */
  pauseWhep: () => Promise<void>;
  /**
   * Unpauses the WHEP client stream.
   */
  unpauseWhep: () => Promise<void>;
  /**
   * Gets supported receiver video codec names.
   */
  getSupportedReceiverVideoCodecsNames: () => Promise<ReceiverVideoCodecName[]>;
  /**
   * Gets supported receiver audio codec names.
   */
  getSupportedReceiverAudioCodecsNames: () => Promise<ReceiverAudioCodecName[]>;
  /**
   * Sets preferred receiver video codecs.
   */
  setPreferredReceiverVideoCodecs: (preferredCodecs: ReceiverVideoCodecName[]) => Promise<void>;
  /**
   * Sets preferred receiver audio codecs.
   */
  setPreferredReceiverAudioCodecs: (preferredCodecs: ReceiverAudioCodecName[]) => Promise<void>;
  /**
   * Starts the Picture-in-Picture mode.
   * On android enters the Picture-in-Picture mode and background the app.
   */
  startPip: () => Promise<void>;
  /**
   * Stops the Picture-in-Picture mode.
   * Does nothing on Android as PiP is not supported in foreground.
   */
  stopPip: () => Promise<void>;
  /**
   * Toggles the Picture-in-Picture mode.
   * On android enters the Picture-in-Picture mode and background the app.
   */
  togglePip: () => Promise<void>;
};

/** Describes props that can be passed to the module view. */
export type ReactNativeMobileWhepClientViewProps = {
  /**
   * Used to apply custom styles to the component.
   * It should be a valid CSS object for style properties.
   */
  style: React.CSSProperties;

  /**
   * A variable deciding whether the Picture-in-Picture is enabled.
   * Defaults to true.
   */
  pipEnabled?: boolean;

  /**
   * A variable deciding whether the Picture-in-Picture mode should be started automatically after the app is backgrounded.
   * Defaults to false.
   */
  autoStartPip?: boolean;

  /**
   * A variable deciding whether the Picture-in-Picture mode should be stopped automatically on iOS after the app is foregrounded.
   * Always enabled on Android as PiP is not supported in foreground.
   * Defaults to false.
   */
  autoStopPip?: boolean;

  /**
   * A variable deciding the size of the Picture-in-Picture mode.
   */
  pipSize?: { width: number; height: number };
};

/** Describes props that can be passed to the module view. */
export type ReactNativeMobileWhipClientViewProps = {
  /**
   * Used to apply custom styles to the component.
   * It should be a valid CSS object for style properties.
   */
  style: React.CSSProperties;
};

export type WhipClientViewRef = {
  initializeCamera: (
    audioEnabled: boolean,
    videoEnabled: boolean,
    videoDeviceId?: string,
    videoParameters?: VideoParameters,
    stunServerUrl?: string,
    preferredVideoCodecs?: SenderVideoCodecName[],
    preferredAudioCodecs?: SenderAudioCodecName[],
  ) => Promise<void>;
  connect: (serverUrl: string, authToken?: string) => Promise<void>;
  disconnect: () => Promise<void>;
  switchCamera: (deviceId: string) => Promise<void>;
  flipCamera: () => Promise<void>;
  cleanup: () => void;
  setPreferredSenderVideoCodecs: (
    preferredCodecs?: SenderVideoCodecName[],
  ) => Promise<void>;
  setPreferredSenderAudioCodecs: (
    preferredCodecs?: SenderAudioCodecName[],
  ) => Promise<void>;
  getSupportedSenderVideoCodecsNames: () => Promise<SenderVideoCodecName[]>;
  getSupportedSenderAudioCodecsNames: () => Promise<SenderAudioCodecName[]>;
};

/** Internal enum telling native views whether the stream will come from the server or device camera*/
export enum PlayerType {
  /** An indicator that a WHEP client will be used, so the stream will come from the server */
  WHEP = "WHEP",
  /** An indicator that a WHIP client will be used, so device camera will generate the stream */
  WHIP = "WHIP",
}

/** Enum that defines video track dimensions and aspect ratio. */
export enum VideoParameters {
  /** QVGA with 4:3 aspect ratio - Dimensions: 240x180 */
  presetQVGA43 = "QVGA43",
  /** VGA with 4:3 aspect ratio - Dimensions: 480x360 */
  presetVGA43 = "VGA43",
  /** QHD with 4:3 aspect ratio - Dimensions: 720x540 */
  presetQHD43 = "QHD43",
  /** HD with 4:3 aspect ratio - Dimensions: 960x720 */
  presetHD43 = "HD43",
  /** Full HD with 4:3 aspect ratio - Dimensions: 1440x1080 */
  presetFHD43 = "FHD43",
  /** QVGA with 16:9 aspect ratio - Dimensions: 320x180 */
  presetQVGA169 = "QVGA169",
  /** VGA with 16:9 aspect ratio - Dimensions: 640x360 */
  presetVGA169 = "VGA169",
  /** QHD with 16:9 aspect ratio - Dimensions: 960x540 */
  presetQHD169 = "QHD169",
  /** HD with 16:9 aspect ratio - Dimensions: 1280x720 */
  presetHD169 = "HD169",
  /** Full HD with 16:9 aspect ratio - Dimensions: 1920x1080 */
  presetFHD169 = "FHD169",
}
