import { useEventState } from "./useEventState";
import ReactNativeMobileWhepClientModule, {
  PeerConnectionState,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientModule";
import ReactNativeMobileWhipClientViewModule, {
  ReceivableEvents as WhipReceivableEvents,
} from "../ReactNativeMobileWhipClientViewModule";

/**
 * Hook that returns the current state of the WHEP peer connection.
 * If WHEP client was not created, it will return "unknown".
 */
export const useWhepConnectionState = (): PeerConnectionState | null => {
  return useEventState(
    ReceivableEvents.WhepPeerConnectionStateChanged,
    (ReactNativeMobileWhepClientModule.whepPeerConnectionState ?? "unknown") as PeerConnectionState,
  );
};

/**
 * Hook that returns the current state of the WHIP peer connection.
 * If WHIP client was not created, it will return "unknown".
 */
export const useWhipConnectionState = (): PeerConnectionState | null => {
  return useEventState(
    WhipReceivableEvents.WhipPeerConnectionStateChanged,
    (ReactNativeMobileWhipClientViewModule.whipPeerConnectionState ?? "unknown") as PeerConnectionState,
  );
};
