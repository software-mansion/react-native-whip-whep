import {
  NativeModulesProxy,
  EventEmitter,
  Subscription,
} from "expo-modules-core";

// Import the native module. On web, it will be resolved to ReactNativeClient.web.ts
// and on native platforms to ReactNativeClient.ts
import {
  ChangeEventPayload,
  ConfigurationOptions,
  ReactNativeClientViewProps,
} from "./ReactNativeClient.types";
import ReactNativeClientModule, {
  addTrackListener,
} from "./ReactNativeClientModule";
import { ReactNativeClientView } from "./ReactNativeClientView";

// Get the native constant value.
export const PI = ReactNativeClientModule.PI;

export const whepClient = ReactNativeClientModule.whepClient;

export function hello(): string {
  return ReactNativeClientModule.hello();
}

export async function createWhepClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions
) {
  return await ReactNativeClientModule.createClient(
    serverUrl,
    configurationOptions
  );
}

export async function connectWhipClient() {
  return await ReactNativeClientModule.connectWhip();
}

export function disconnectWhipClient() {
  return ReactNativeClientModule.disconnectWhip();
}

export async function createWhipClient(
  serverUrl: string,
  configurationOptions?: ConfigurationOptions
) {
  return await ReactNativeClientModule.createWhipClient(
    serverUrl,
    configurationOptions
  );
}

export async function connectWhepClient() {
  return await ReactNativeClientModule.connect();
}

export function disconnectWhepClient() {
  return ReactNativeClientModule.disconnect();
}

const emitter = new EventEmitter(
  ReactNativeClientModule ?? NativeModulesProxy.ReactNativeClient
);

export function addChangeListener(
  listener: (event: ChangeEventPayload) => void
): Subscription {
  return emitter.addListener<ChangeEventPayload>("onChange", listener);
}

export {
  ReactNativeClientView,
  ReactNativeClientViewProps,
  ChangeEventPayload,
  addTrackListener,
};
