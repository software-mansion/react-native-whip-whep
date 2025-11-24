import ReactNativeMobileWhepClientViewModule, {
  ReceivableEvents as WhepReceivableEvents,
} from "../ReactNativeMobileWhepClientViewModule";
import ReactNativeMobileWhipClientViewModule, {
  ReceivableEvents as WhipReceivableEvents,
} from "../ReactNativeMobileWhipClientViewModule";

export const initializeWarningListener = () => {
  if (!__DEV__) {
    return;
  }

  try {
    // Listen for WHEP warnings
    ReactNativeMobileWhepClientViewModule.addListener(
      WhepReceivableEvents.Warning,
      (event) => {
        console.warn("[WHEP]", event[WhepReceivableEvents.Warning]);
      },
    );
  } catch (error: unknown) {
    console.error(
      `Failed to start WHEP warning listener: ${error instanceof Error ? error.message : ""}`,
    );
  }

  try {
    // Listen for WHIP warnings
    ReactNativeMobileWhipClientViewModule.addListener(
      WhipReceivableEvents.Warning,
      (event) => {
        console.warn("[WHIP]", event[WhipReceivableEvents.Warning]);
      },
    );
  } catch (error: unknown) {
    console.error(
      `Failed to start WHIP warning listener: ${error instanceof Error ? error.message : ""}`,
    );
  }

  try {
    // Listen for screen sharing permission denied
    ReactNativeMobileWhipClientViewModule.addListener(
      WhipReceivableEvents.ScreenSharingPermissionDenied,
      (event) => {
        console.warn("[WHIP]", event[WhipReceivableEvents.ScreenSharingPermissionDenied]);
      },
    );
  } catch (error: unknown) {
    console.error(
      `Failed to start WHIP screen sharing permission listener: ${error instanceof Error ? error.message : ""}`,
    );
  }
};
