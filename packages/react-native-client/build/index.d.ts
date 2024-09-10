import { Subscription } from "expo-modules-core";
import { ChangeEventPayload, ConfigurationOptions, ReactNativeClientViewProps } from "./ReactNativeClient.types";
import ReactNativeClientView from "./ReactNativeClientView";
export declare const PI: any;
export declare function hello(): string;
export declare function createWhepClient(serverUrl: string, configurationOptions?: ConfigurationOptions): Promise<any>;
export declare function connectWhipClient(): Promise<any>;
export declare function disconnectWhipClient(): any;
export declare function createWhipClient(serverUrl: string, configurationOptions?: ConfigurationOptions): Promise<any>;
export declare function connectWhepClient(): Promise<any>;
export declare function disconnectWhepClient(): any;
export declare function setValueAsync(value: string): Promise<any>;
export declare function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription;
export { ReactNativeClientView, ReactNativeClientViewProps, ChangeEventPayload, };
//# sourceMappingURL=index.d.ts.map