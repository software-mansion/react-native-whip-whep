export type WhipWhepPluginOptions =
  | {
      android?: {
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

