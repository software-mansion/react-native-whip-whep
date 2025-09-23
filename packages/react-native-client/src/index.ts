import { WhepClientView } from "./ReactNativeMobileWhepClientView";
import { WhipClientView } from "./ReactNativeMobileWhipClientView";
import { initializeWarningListener } from "./utils/errorListener";

export { WhipClientView, WhepClientView };
export {
  VideoParameters,
  ReactNativeMobileWhepClientViewProps,
  ReactNativeMobileWhipClientViewProps,
  WhepClientViewRef,
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
