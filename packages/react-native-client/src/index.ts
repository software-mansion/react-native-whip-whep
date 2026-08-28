import { WhepClientView } from "./ReactNativeMobileWhepClientView";
import { WhipClientView } from "./ReactNativeMobileWhipClientView";
import { initializeWarningListener } from "./utils/errorListener";

export { WhipClientView, WhepClientView };
export { VideoParameters } from "./ReactNativeMobileWhepClient.types";
export type {
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
  cameras,
  ReceivableEvents as WhipReceivableEvents,
} from "./ReactNativeMobileWhipClientViewModule";
export type {
  Camera,
  CameraFacingDirection,
} from "./ReactNativeMobileWhipClientViewModule";

export { ReceivableEvents as WhepReceivableEvents } from "./ReactNativeMobileWhepClientViewModule";

export { useEvent } from "./hooks/useEvent";
export { useEventState } from "./hooks/useEventState";
export {
  useWhepConnectionState,
  useWhipConnectionState,
} from "./hooks/useConnectionState";

initializeWarningListener();
