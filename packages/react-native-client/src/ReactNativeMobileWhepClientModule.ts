import {
  EventEmitter,
  requireNativeModule,
  Subscription,
} from "expo-modules-core";
import { NativeModule } from "react-native";

import { ConfigurationOptions } from "./ReactNativeMobileWhepClient.types";

// branded types are useful for restricting where given value can be passed
declare const brand: unique symbol;
export type Brand<T, TBrand extends string> = T & { [brand]: TBrand };

export type CameraId = Brand<string, "CameraId">;

export type CameraFacingDirection = "front" | "back" | "unspecified";

export type Camera = {
  id: CameraId;
  name: string;
  facingDirection: CameraFacingDirection;
};

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
    videoDevice?: CameraId,
  ) => void;
  connectWhip: () => Promise<void>;
  disconnectWhip: () => void;
  cameras: readonly Camera[];
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
  videoDevice?: CameraId,
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

export const cameras = nativeModule.cameras;

export default nativeModule;
