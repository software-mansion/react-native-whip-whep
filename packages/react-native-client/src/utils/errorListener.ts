import ReactNativeMobileWhepClientModule, {
  ReceivableEvents,
} from "../ReactNativeMobileWhepClientModule";

export const initializeWarningListener = () => {
  if (!__DEV__) {
    return;
  }
  try {
    ReactNativeMobileWhepClientModule.addListener(
      ReceivableEvents.Warning,
      (event) => {
        console.warn(event[ReceivableEvents.Warning]);
      },
    );
  } catch (error: unknown) {
    console.error(
      `Failed to start warning listener: ${error instanceof Error ? error.message : ""}`,
    );
  }
};
