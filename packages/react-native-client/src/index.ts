import { WhepClientView } from "./ReactNativeMobileWhepClientView";
import { WhipClientView } from "./ReactNativeMobileWhipClientView";
import { initializeWarningListener } from "./utils/errorListener";

export { WhipClientView, WhepClientView };
export {
  VideoParameters,
  ReactNativeMobileWhepClientViewProps,
  ReactNativeMobileWhipClientViewProps,
  WhepClientViewRef,
  WhipClientViewRef,
  CameraId,
  ConnectOptions,
  WhipConfigurationOptions,
  WhepConfigurationOptions,
  SenderAudioCodecName,
  SenderVideoCodecName,
  ReceiverAudioCodecName,
  ReceiverVideoCodecName,
} from "./ReactNativeMobileWhepClient.types";

export {
  WhepClient,
  WhipClient,
} from "./ReactNativeMobileWhepClientModule";

export {
  cameras,
  getCurrentCameraDeviceId,
  Camera,
  CameraFacingDirection,
} from "./ReactNativeMobileWhipClientViewModule";

export { useEvent } from "./hooks/useEvent";
export { useEventState } from "./hooks/useEventState";
export {
  useWhepConnectionState,
  useWhipConnectionState,
} from "./hooks/useConnectionState";

initializeWarningListener();
