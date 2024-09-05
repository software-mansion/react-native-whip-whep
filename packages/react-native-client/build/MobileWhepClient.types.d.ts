export type ChangeEventPayload = {
    value: string;
};
export type MobileWhepClientViewProps = {
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
export declare class VideoParameters {
    static readonly presetQVGA43: VideoParameters;
    static readonly presetVGA43: VideoParameters;
    static readonly presetQHD43: VideoParameters;
    static readonly presetHD43: VideoParameters;
    static readonly presetFHD43: VideoParameters;
    static readonly presetQVGA169: VideoParameters;
    static readonly presetVGA169: VideoParameters;
    static readonly presetQHD169: VideoParameters;
    static readonly presetHD169: VideoParameters;
    static readonly presetFHD169: VideoParameters;
    static readonly presetScreenShareVGA: VideoParameters;
    static readonly presetScreenShareHD5: VideoParameters;
    static readonly presetScreenShareHD15: VideoParameters;
    static readonly presetScreenShareFHD15: VideoParameters;
    static readonly presetScreenShareFHD30: VideoParameters;
    static readonly presets43: VideoParameters[];
    static readonly presets169: VideoParameters[];
    static readonly presetsScreenShare: VideoParameters[];
    dimensions: Dimensions;
    maxBandwidth: BandwidthLimit;
    maxFps: number;
    constructor(dimensions: Dimensions, maxBandwidth?: BandwidthLimit, maxFps?: number);
}
export {};
//# sourceMappingURL=MobileWhepClient.types.d.ts.map