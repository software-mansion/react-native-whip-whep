import { useState, useEffect } from "react";

import { useEventState } from "./useEventState";
import ReactNativeMobileWhepClientViewModule, {
  PeerConnectionState,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientViewModule";
import ReactNativeMobileWhipClientViewModule, {
  ReceivableEvents as WhipReceivableEvents,
  PeerConnectionState as WhipPeerConnectionState,
} from "../ReactNativeMobileWhipClientViewModule";

/**
 * Hook that returns the current state of the WHEP peer connection.
 * If WHEP client was not created, it will return "unknown".
 */
export const useWhepConnectionState = (): PeerConnectionState | null => {
  const [peerConnectionState, setPeerConnectionState] =
    useState<PeerConnectionState>(
      (ReactNativeMobileWhepClientViewModule.whepPeerConnectionState ??
        "unknown") as PeerConnectionState,
    );

  useEffect(() => {
    const eventListener = ReactNativeMobileWhepClientViewModule.addListener(
      ReceivableEvents.WhepPeerConnectionStateChanged,
      (event) => {
        const payload =
          event[ReceivableEvents.WhepPeerConnectionStateChanged];
        setPeerConnectionState(payload);
      },
    );

    return () => eventListener.remove();
  }, []);

  return peerConnectionState;
};

/**
 * Hook that returns the current state of the WHIP peer connection.
 * If WHIP client was not created, it will return "unknown".
 */
export const useWhipConnectionState = (): WhipPeerConnectionState => {
  const [peerConnectionState, setPeerConnectionState] =
    useState<WhipPeerConnectionState>(
      (ReactNativeMobileWhipClientViewModule.whipPeerConnectionState ??
        "unknown") as WhipPeerConnectionState,
    );

  useEffect(() => {
    const eventListener = ReactNativeMobileWhipClientViewModule.addListener(
      WhipReceivableEvents.WhipPeerConnectionStateChanged,
      (event) => {
        const payload =
          event[WhipReceivableEvents.WhipPeerConnectionStateChanged];
        setPeerConnectionState(payload);
      },
    );

    return () => eventListener.remove();
  }, []);

  return peerConnectionState;
};
