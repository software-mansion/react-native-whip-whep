import { Subscription } from 'expo-modules-core';
import MobileWhepClientView from './MobileWhepClientView';
import { ChangeEventPayload, ConfigurationOptions, MobileWhepClientViewProps } from './MobileWhepClient.types';
export declare const PI: any;
export declare function hello(): string;
export declare function createWhepClient(serverUrl: string, configurationOptions?: ConfigurationOptions): Promise<any>;
export declare function connect(): Promise<any>;
export declare function disconnect(): any;
export declare function setValueAsync(value: string): Promise<any>;
export declare function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription;
export { MobileWhepClientView, MobileWhepClientViewProps, ChangeEventPayload };
//# sourceMappingURL=index.d.ts.map