export type WhipWhepPluginOptions =
  | {
      android?: {
        enableScreensharing?: boolean;
        supportsPictureInPicture?: boolean;
      };
      ios?: {
        iphoneDeploymentTarget?: string;
        enableScreensharing?: boolean;
        supportsPictureInPicture?: boolean;
        appGroupContainerId?: string;
        mainTargetName?: string;
        broadcastExtensionTargetName?: string;
      };
    }
  | undefined;

