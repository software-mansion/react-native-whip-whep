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

/** Describes props that can be passed to the module view. */
export type ReactNativeMobileWhepClientViewProps = {
  /**
   * Used to apply custom styles to the component.
   * It should be a valid CSS object for style properties.
   */
  style: React.CSSProperties;
  /**
   * Used to get a reference to the React component instance.
   * It is useful for accessing the component methods and properties directly.
   */
  ref: React.ForwardedRef<
    React.ComponentType<ReactNativeMobileWhepClientViewProps>
  >;
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
