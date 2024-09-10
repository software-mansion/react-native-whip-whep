export type ChangeEventPayload = {
  value: string;
};

export type ReactNativeClientViewProps = {
  client: any;
};

export type ConfigurationOptions = {
  authToken?: string;
  stunServerUrl?: string;
  audioEnabled?: boolean;
  videoEnabled?: boolean;
  videoParameters?: VideoParameters;
};

interface Dimensions {
  width: number;
  height: number;
}

type BandwidthLimit = number;

export class VideoParameters {
  // 4:3 aspect ratio
  public static readonly presetQVGA43 = new VideoParameters(
    { width: 240, height: 180 },
    90,
    10
  );
  public static readonly presetVGA43 = new VideoParameters(
    { width: 480, height: 360 },
    225,
    20
  );
  public static readonly presetQHD43 = new VideoParameters(
    { width: 720, height: 540 },
    450,
    25
  );
  public static readonly presetHD43 = new VideoParameters(
    { width: 960, height: 720 },
    1500,
    30
  );
  public static readonly presetFHD43 = new VideoParameters(
    { width: 1440, height: 1080 },
    2800,
    30
  );

  // 16:9 aspect ratio
  public static readonly presetQVGA169 = new VideoParameters(
    { width: 320, height: 180 },
    120,
    10
  );
  public static readonly presetVGA169 = new VideoParameters(
    { width: 640, height: 360 },
    300,
    20
  );
  public static readonly presetQHD169 = new VideoParameters(
    { width: 960, height: 540 },
    600,
    25
  );
  public static readonly presetHD169 = new VideoParameters(
    { width: 1280, height: 720 },
    2000,
    30
  );
  public static readonly presetFHD169 = new VideoParameters(
    { width: 1920, height: 1080 },
    3000,
    30
  );

  // Screen share
  public static readonly presetScreenShareVGA = new VideoParameters(
    { width: 640, height: 360 },
    200,
    3
  );
  public static readonly presetScreenShareHD5 = new VideoParameters(
    { width: 1280, height: 720 },
    400,
    5
  );
  public static readonly presetScreenShareHD15 = new VideoParameters(
    { width: 1280, height: 720 },
    1000,
    15
  );
  public static readonly presetScreenShareFHD15 = new VideoParameters(
    { width: 1920, height: 1080 },
    1500,
    15
  );
  public static readonly presetScreenShareFHD30 = new VideoParameters(
    { width: 1920, height: 1080 },
    3000,
    30
  );

  public static readonly presets43 = [
    VideoParameters.presetQVGA43,
    VideoParameters.presetVGA43,
    VideoParameters.presetQHD43,
    VideoParameters.presetHD43,
    VideoParameters.presetFHD43,
  ];

  public static readonly presets169 = [
    VideoParameters.presetQVGA169,
    VideoParameters.presetVGA169,
    VideoParameters.presetQHD169,
    VideoParameters.presetHD169,
    VideoParameters.presetFHD169,
  ];

  public static readonly presetsScreenShare = [
    VideoParameters.presetScreenShareVGA,
    VideoParameters.presetScreenShareHD5,
    VideoParameters.presetScreenShareHD15,
    VideoParameters.presetScreenShareFHD15,
    VideoParameters.presetScreenShareFHD30,
  ];

  public dimensions: Dimensions;
  public maxBandwidth: BandwidthLimit;
  public maxFps: number;

  constructor(
    dimensions: Dimensions,
    maxBandwidth: BandwidthLimit = 0,
    maxFps: number = 30
  ) {
    this.dimensions = dimensions;
    this.maxBandwidth = maxBandwidth;
    this.maxFps = maxFps;
  }
}
