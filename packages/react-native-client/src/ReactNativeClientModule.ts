import {
  EventEmitter,
  requireNativeModule,
  Subscription,
} from "expo-modules-core";
import { ConfigurationOptions } from "./ReactNativeClient.types";
import { NativeModule } from "react-native";

type RNClientModule = {
  createWhepClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions
  ) => void;
  connectWhep: () => Promise<void>;
  disconnectWhep: () => void;
  createWhipClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
    videoDevice?: string
  ) => void;
  connectWhip: () => Promise<void>;
  disconnectWhip: () => void;
  getCaptureDevices: () => string[];
};

const nativeModule: RNClientModule & NativeModule =
  requireNativeModule("ReactNativeClient");
export const eventEmitter = new EventEmitter(nativeModule);

export function addTrackListener(listener: (event) => void): Subscription {
  return eventEmitter.addListener("trackAdded", listener);
}

export function createWhepClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions
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
  videoDevice?: string
) {
  return nativeModule.createWhipClient(
    serverUrl,
    configurationOptions,
    videoDevice
  );
}

export async function connectWhipClient() {
  return await nativeModule.connectWhip();
}

export function disconnectWhipClient() {
  return nativeModule.disconnectWhip();
}

export function getCaptureDevices() {
  return nativeModule.getCaptureDevices();
}

export default nativeModule;
