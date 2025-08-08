import { useCallback, useState } from "react";

import {
  ReceivableEventPayloads,
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientModule";
import { useEvent } from "./useEvent";

export function useEventState<
  EventName extends keyof typeof ReceivableEvents,
  StateType = ReceivableEventPayloads[EventName],
>(
  eventName: EventName,
  defaultValue: ReceivableEventPayloads[EventName],
  transform?: (eventValue: ReceivableEventPayloads[EventName]) => StateType,
) {
  const [value, setValue] = useState<StateType>(
    transform
      ? transform(defaultValue)
      : (defaultValue as unknown as StateType),
  );

  const onEvent = useCallback(
    (newValue: ReceivableEventPayloads[EventName]) => {
      if (transform) {
        setValue(transform(newValue));
      } else {
        setValue(newValue as unknown as StateType);
      }
    },
    [transform],
  );

  useEvent<EventName>(eventName, onEvent);

  return value;
}
