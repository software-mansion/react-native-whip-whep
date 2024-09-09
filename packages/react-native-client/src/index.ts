import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ReactNativeClient.web.ts
// and on native platforms to ReactNativeClient.ts
import ReactNativeClientModule from './ReactNativeClientModule';
import ReactNativeClientView from './ReactNativeClientView';
import { ChangeEventPayload, ReactNativeClientViewProps } from './ReactNativeClient.types';

// Get the native constant value.
export const PI = ReactNativeClientModule.PI;

export function hello(): string {
  return ReactNativeClientModule.hello();
}

export async function setValueAsync(value: string) {
  return await ReactNativeClientModule.setValueAsync(value);
}

const emitter = new EventEmitter(ReactNativeClientModule ?? NativeModulesProxy.ReactNativeClient);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { ReactNativeClientView, ReactNativeClientViewProps, ChangeEventPayload };
