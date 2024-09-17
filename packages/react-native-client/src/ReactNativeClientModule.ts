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

export default nativeModule;
