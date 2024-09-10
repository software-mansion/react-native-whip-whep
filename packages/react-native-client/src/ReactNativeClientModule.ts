import {
  EventEmitter,
  requireNativeModule,
  Subscription,
} from "expo-modules-core";

// It loads the native module object from the JSI or falls back to
// the bridge module (from NativeModulesProxy) if the remote debugger is on.
const nativeModule = requireNativeModule("ReactNativeClient");
export const eventEmitter = new EventEmitter(nativeModule);

export function addTrackListener(listener: (event) => void): Subscription {
  return eventEmitter.addListener("trackAdded", listener);
}

export default nativeModule;
