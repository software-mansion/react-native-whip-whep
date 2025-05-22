import { useEffect } from "react";

import nativeModule, {
  ReceivableEventPayloads,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientModule";

export function useEvent<T extends keyof typeof ReceivableEvents>(
  eventName: T,
  callback: (event: ReceivableEventPayloads[T]) => void,
) {
  useEffect(() => {
    const eventListener = nativeModule.addListener(eventName, (payload) => {
      callback(payload);
    });
    return () => eventListener.remove();
  }, [callback, eventName]);
}
