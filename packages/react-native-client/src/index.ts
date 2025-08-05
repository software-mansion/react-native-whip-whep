import {
  WhipClientView,
  WhepClientView,
} from "./ReactNativeMobileWhepClientView";
import { initializeWarningListener } from "./utils/errorListener";

export { WhipClientView, WhepClientView };
export {
  VideoParameters,
  ReactNativeMobileWhepClientViewProps,
  WhepClientViewRef,
  CameraId,
  ConnectOptions,
  WhipConfigurationOptions,
  WhepConfigurationOptions,
} from "./ReactNativeMobileWhepClient.types";

export {
  createWhepClient,
  connectWhepClient,
  disconnectWhepClient,
  pauseWhepClient,
  unpauseWhepClient,
  createWhipClient,
  connectWhipClient,
  disconnectWhipClient,
  cameras,
  Camera,
  CameraFacingDirection,
} from "./ReactNativeMobileWhepClientModule";

export { useEvent } from "./hooks/useEvent";
export { useEventState } from "./hooks/useEventState";
export {
  useWhepConnectionState,
  useWhipConnectionState,
} from "./hooks/useConnectionState";

initializeWarningListener();
