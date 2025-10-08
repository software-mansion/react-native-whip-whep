import { z } from "zod";

import {
  ReceivableEventPayloads,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientViewModule";

const ReconnectionStatusChangedEventSchema = z.object({
  status: z.enum([
    "reconnectionStarted",
    "reconnected",
    "reconnectionRetriesLimitReached",
  ]),
});

const PeerConnectionStateChangedEventSchema = z.object({
  state: z.enum([
    "new",
    "connecting",
    "connected",
    "disconnected",
    "failed",
    "closed",
  ]),
});

export function validateNativeEventPayload<
  T extends keyof typeof ReceivableEvents,
>(eventName: T, payload: ReceivableEventPayloads[T]): void {
  switch (eventName) {
    case ReceivableEvents.ReconnectionStatusChanged:
      ReconnectionStatusChangedEventSchema.parse(payload);
      break;
    case ReceivableEvents.WhepPeerConnectionStateChanged:
      PeerConnectionStateChangedEventSchema.parse(payload);
      break;
    default:
      throw new Error(`Unknown event: ${eventName}`);
  }
}
