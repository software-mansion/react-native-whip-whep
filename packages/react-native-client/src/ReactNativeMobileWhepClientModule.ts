import { EventSubscription, requireNativeModule } from "expo-modules-core";
import type { NativeModule } from "expo-modules-core/types";

import { ConfigurationOptions } from "./ReactNativeMobileWhepClient.types";

// branded types are useful for restricting where given value can be passed
declare const brand: unique symbol;
export type Brand<T, TBrand extends string> = T & { [brand]: TBrand };

/** A unique ID of the camera.  */
export type CameraId = Brand<string, "CameraId">;

/** Describes whether the camera is front-facing or back-facing. */
export type CameraFacingDirection = "front" | "back" | "unspecified";

/** Contains information about the camera available on the device. */
export type Camera = {
  /** A unique ID of the camera.  */
  id: CameraId;
  /** A string describing camera name. */
  name: string;
  /** Information about the camera being a front one or back one. */
  facingDirection: CameraFacingDirection;
};

type RNMobileWhepClientModule = {
  createWhepClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
  ) => void;
  connectWhep: () => Promise<void>;
  disconnectWhep: () => void;
  pauseWhep: () => void;
  unpauseWhep: () => void;
  createWhipClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
    videoDevice?: CameraId,
  ) => void;
  connectWhip: () => Promise<void>;
  disconnectWhip: () => void;
  cameras: readonly Camera[];
};

const nativeModule: RNMobileWhepClientModule &
  NativeModule<Record<string, <T>(...args: T[]) => void>> = requireNativeModule(
  "ReactNativeMobileWhepClient",
);

export function addTrackListener(listener: (event) => void): EventSubscription {
  return nativeModule.addListener("trackAdded", listener);
}

/** Creates a WHEP client based on the provided server URL and optional additional `configurationOptions`.
 *  It is a first step before connecting to the server.
 */
export function createWhepClient(
  /** URL of the WHEP server from which the stream should be received. */
  serverUrl: string,
  /** Additional configuration options. */
  configurationOptions?: ConfigurationOptions,
) {
  return nativeModule.createWhepClient(serverUrl, configurationOptions);
}

/** Connects to the WHEP server defined while creating WHEP client.
 * Allows user to receive video and audio stream.
 */
export async function connectWhepClient() {
  return await nativeModule.connectWhep();
}

/** Disconnects from the WHEP server defined while creating WHEP client.
 * Frees the resources.
 */
export function disconnectWhepClient() {
  return nativeModule.disconnectWhep();
}

/** Pauses the WHEP stream, making the view black and disabling the sound. */
export function pauseWhepClient() {
  return nativeModule.pauseWhep();
}

/** Restarts the WHEP stream. Makes the view reappear along with sound. */
export function unpauseWhepClient() {
  return nativeModule.unpauseWhep();
}

/** Creates a WHIP client based on the provided server URL and optional additional `configurationOptions`.
 * Allows user to choose a streaming device from all available cameras.
 *  It is a first step before connecting to the server.
 */
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

/** Connects to the WHIP server defined while creating WHIP client.
 * Allows user to stream video and audio.
 */
export async function connectWhipClient() {
  return await nativeModule.connectWhip();
}

/** Disconnects from the WHIP server defined while creating WHIP client.
 * Frees the resources.
 */
export function disconnectWhipClient() {
  return nativeModule.disconnectWhip();
}

/** Gives access to the cameras available on the device.*/
export const cameras = nativeModule.cameras;

export default nativeModule;
