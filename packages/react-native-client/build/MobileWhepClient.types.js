export class VideoParameters {
    // 4:3 aspect ratio
    static presetQVGA43 = new VideoParameters({ width: 240, height: 180 }, 90, 10);
    static presetVGA43 = new VideoParameters({ width: 480, height: 360 }, 225, 20);
    static presetQHD43 = new VideoParameters({ width: 720, height: 540 }, 450, 25);
    static presetHD43 = new VideoParameters({ width: 960, height: 720 }, 1500, 30);
    static presetFHD43 = new VideoParameters({ width: 1440, height: 1080 }, 2800, 30);
    // 16:9 aspect ratio
    static presetQVGA169 = new VideoParameters({ width: 320, height: 180 }, 120, 10);
    static presetVGA169 = new VideoParameters({ width: 640, height: 360 }, 300, 20);
    static presetQHD169 = new VideoParameters({ width: 960, height: 540 }, 600, 25);
    static presetHD169 = new VideoParameters({ width: 1280, height: 720 }, 2000, 30);
    static presetFHD169 = new VideoParameters({ width: 1920, height: 1080 }, 3000, 30);
    // Screen share
    static presetScreenShareVGA = new VideoParameters({ width: 640, height: 360 }, 200, 3);
    static presetScreenShareHD5 = new VideoParameters({ width: 1280, height: 720 }, 400, 5);
    static presetScreenShareHD15 = new VideoParameters({ width: 1280, height: 720 }, 1000, 15);
    static presetScreenShareFHD15 = new VideoParameters({ width: 1920, height: 1080 }, 1500, 15);
    static presetScreenShareFHD30 = new VideoParameters({ width: 1920, height: 1080 }, 3000, 30);
    static presets43 = [
        VideoParameters.presetQVGA43,
        VideoParameters.presetVGA43,
        VideoParameters.presetQHD43,
        VideoParameters.presetHD43,
        VideoParameters.presetFHD43,
    ];
    static presets169 = [
        VideoParameters.presetQVGA169,
        VideoParameters.presetVGA169,
        VideoParameters.presetQHD169,
        VideoParameters.presetHD169,
        VideoParameters.presetFHD169,
    ];
    static presetsScreenShare = [
        VideoParameters.presetScreenShareVGA,
        VideoParameters.presetScreenShareHD5,
        VideoParameters.presetScreenShareHD15,
        VideoParameters.presetScreenShareFHD15,
        VideoParameters.presetScreenShareFHD30,
    ];
    dimensions;
    maxBandwidth;
    maxFps;
    constructor(dimensions, maxBandwidth = 0, maxFps = 30) {
        this.dimensions = dimensions;
        this.maxBandwidth = maxBandwidth;
        this.maxFps = maxFps;
    }
}
//# sourceMappingURL=MobileWhepClient.types.js.map