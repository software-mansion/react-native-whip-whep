import {
  EventEmitter,
  requireNativeModule,
  Subscription,
} from "expo-modules-core";
import { NativeModule } from "react-native";

import { ConfigurationOptions } from "./ReactNativeMobileWhepClient.types";

type RNMobileWhepClientModule = {
  createWhepClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
  ) => void;
  connectWhep: () => Promise<void>;
  disconnectWhep: () => void;
  createWhipClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
    videoDevice?: string,
  ) => void;
  connectWhip: () => Promise<void>;
  disconnectWhip: () => void;
  captureDevices: readonly string[];
};

const nativeModule: RNMobileWhepClientModule & NativeModule =
  requireNativeModule("ReactNativeMobileWhepClient");
export const eventEmitter = new EventEmitter(nativeModule);

export function addTrackListener(listener: (event) => void): Subscription {
  return eventEmitter.addListener("trackAdded", listener);
}

export function createWhepClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions,
) {
  return nativeModule.createWhepClient(serverUrl, configurationOptions);
}

export async function connectWhepClient() {
  return await nativeModule.connectWhep();
}

export function disconnectWhepClient() {
  return nativeModule.disconnectWhep();
}

export function createWhipClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions,
  videoDevice?: string,
) {
  return nativeModule.createWhipClient(
    serverUrl,
    configurationOptions,
    videoDevice,
  );
}

export async function connectWhipClient() {
  return await nativeModule.connectWhip();
}

export function disconnectWhipClient() {
  return nativeModule.disconnectWhip();
}

export const captureDevices = nativeModule.captureDevices;

export default nativeModule;
