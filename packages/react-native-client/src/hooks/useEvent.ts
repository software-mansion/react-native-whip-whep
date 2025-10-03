import { useEffect } from "react";
import { ZodError } from "zod";

import nativeModule, {
  ReceivableEventPayloads,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientViewModule";
import { validateNativeEventPayload } from "./eventPayloadValidator";

export function useEvent<T extends keyof typeof ReceivableEvents>(
  eventName: T,
  callback: (event: ReceivableEventPayloads[T]) => void,
) {
  useEffect(() => {
    const eventListener = nativeModule.addListener(eventName, (event) => {
      const payload = event[eventName];

      callback(payload);
    });
    return () => eventListener.remove();
  }, [callback, eventName]);
}

export function validateAndLogEventPayload<
  T extends keyof typeof ReceivableEvents,
>(eventName: T, payload: ReceivableEventPayloads[T]): void {
  // Double check just to make sure
  if (!__DEV__) return;

  try {
    validateNativeEventPayload(eventName, payload);
  } catch (error) {
    if (error instanceof ZodError) {
      console.error(
        `Invalid payload received for event ${eventName}:\n`,
        error.errors
          .map((err) => `- ${err.path.join(".")}: ${err.message}`)
          .join("\n"),
        `\n Received:\n${JSON.stringify(payload, null, 2)}\n\n`,
      );
    } else {
      console.error(
        `Unexpected error validating payload for event ${eventName}:`,
        error,
      );
    }
  }
}
