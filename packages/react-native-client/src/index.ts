import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to MobileWhepClient.web.ts
// and on native platforms to MobileWhepClient.ts
import MobileWhepClientModule from './MobileWhepClientModule';
import MobileWhepClientView from './MobileWhepClientView';
import { ChangeEventPayload, MobileWhepClientViewProps } from './MobileWhepClient.types';

// Get the native constant value.
export const PI = MobileWhepClientModule.PI;

export function hello(): string {
  return MobileWhepClientModule.hello();
}

export async function setValueAsync(value: string) {
  return await MobileWhepClientModule.setValueAsync(value);
}

const emitter = new EventEmitter(MobileWhepClientModule ?? NativeModulesProxy.MobileWhepClient);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { MobileWhepClientView, MobileWhepClientViewProps, ChangeEventPayload };
