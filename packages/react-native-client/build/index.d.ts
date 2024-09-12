import { Subscription } from "expo-modules-core";
import { ChangeEventPayload, ConfigurationOptions } from "./ReactNativeClient.types";
import { addTrackListener } from "./ReactNativeClientModule";
import { ReactNativeClientView } from "./ReactNativeClientView";
export declare const PI: any;
export declare const whepClient: any;
export declare function hello(): string;
export declare function createWhepClient(serverUrl: string, configurationOptions?: ConfigurationOptions): Promise<any>;
export declare function connectWhipClient(): Promise<any>;
export declare function disconnectWhipClient(): any;
export declare function createWhipClient(serverUrl: string, configurationOptions?: ConfigurationOptions, videoDevice?: string): Promise<any>;
export declare function connectWhepClient(): Promise<any>;
export declare function disconnectWhepClient(): any;
export declare function getCaptureDevices(): any;
export declare function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription;
export { ReactNativeClientView, ChangeEventPayload, addTrackListener };
//# sourceMappingURL=index.d.ts.map