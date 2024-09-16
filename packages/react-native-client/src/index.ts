import {
  ChangeEventPayload,
  ConfigurationOptions,
} from "./ReactNativeClient.types";
import ReactNativeClientModule, {
  addTrackListener,
} from "./ReactNativeClientModule";
import { ReactNativeClientView } from "./ReactNativeClientView";

export async function createWhepClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions
) {
  return await ReactNativeClientModule.createWhepClient(
    serverUrl,
    configurationOptions
  );
}

export async function connectWhepClient() {
  return await ReactNativeClientModule.connectWhep();
}

export function disconnectWhepClient() {
  return ReactNativeClientModule.disconnectWhep();
}

export async function createWhipClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions,
  videoDevice?: string
) {
  return await ReactNativeClientModule.createWhipClient(
    serverUrl,
    configurationOptions,
    videoDevice
  );
}

export async function connectWhipClient() {
  return await ReactNativeClientModule.connectWhip();
}

export function disconnectWhipClient() {
  return ReactNativeClientModule.disconnectWhip();
}

export function getCaptureDevices() {
  return ReactNativeClientModule.getCaptureDevices();
}

export { ReactNativeClientView, ChangeEventPayload, addTrackListener };
export {
  PlayerType,
  VideoParameters,
  ConfigurationOptions,
} from "./ReactNativeClient.types";
