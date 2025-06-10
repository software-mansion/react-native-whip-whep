/** Defines initial connection and stream options. */
export type ConfigurationOptions = {
  /** Authorization token that might be required to access the server. */
  authToken?: string;
  /** URL address of the STUN server. The default one is `stun.l.google.com`. */
  stunServerUrl?: string;
  /** A variable deciding whether the audio should be streamed or not. Defaults to true. */
  audioEnabled?: boolean;
  /** A variable deciding whether the video should be streamed or not. Defaults to true. */
  videoEnabled?: boolean;
  /** Defines the parameters of the video. Defaults to HD43. */
  videoParameters?: VideoParameters;
};

/**
 * A type that represents the ref to the WhepClientView component.
 * It contains methods to start, stop, and toggle Picture-in-Picture mode.
 */
export type WhepClientViewRef = {
  /**
   * Starts the Picture-in-Picture mode.
   * On android enters the Picture-in-Picture mode and background the app.
   */
  startPip: () => void;
  /**
   * Stops the Picture-in-Picture mode.
   * Does nothing on Android as PiP is not supported in foreground.
   */
  stopPip: () => void;
  /**
   * Toggles the Picture-in-Picture mode.
   * On android enters the Picture-in-Picture mode and background the app.
   */
  togglePip: () => void;
};

/** Describes props that can be passed to the module view. */
export type ReactNativeMobileWhepClientViewProps = {
  /**
   * Used to apply custom styles to the component.
   * It should be a valid CSS object for style properties.
   */
  style: React.CSSProperties;
  /**
   * Used to set the orientation of the video.
   * Defaults to "portrait".
   */
  orientation?: "landscape" | "portrait";

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
