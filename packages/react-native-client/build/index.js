import { NativeModulesProxy, EventEmitter, } from 'expo-modules-core';
// Import the native module. On web, it will be resolved to MobileWhepClient.web.ts
// and on native platforms to MobileWhepClient.ts
import MobileWhepClientModule from './MobileWhepClientModule';
import MobileWhepClientView from './MobileWhepClientView';
// Get the native constant value.
export const PI = MobileWhepClientModule.PI;
export function hello() {
    return MobileWhepClientModule.hello();
}
export async function createWhepClient(serverUrl, configurationOptions) {
    return MobileWhepClientModule.createClient(serverUrl, configurationOptions);
}
export async function connectWhipClient() {
    return MobileWhepClientModule.connectWhip();
}
export function disconnectWhipClient() {
    return MobileWhepClientModule.disconnectWhip();
}
export async function createWhipClient(serverUrl, configurationOptions) {
    return MobileWhepClientModule.createWhipClient(serverUrl, configurationOptions);
}
export async function connectWhepClient() {
    return MobileWhepClientModule.connect();
}
export function disconnectWhepClient() {
    return MobileWhepClientModule.disconnect();
}
export async function setValueAsync(value) {
    return await MobileWhepClientModule.setValueAsync(value);
}
const emitter = new EventEmitter(MobileWhepClientModule ?? NativeModulesProxy.MobileWhepClient);
export function addChangeListener(listener) {
    return emitter.addListener('onChange', listener);
}
export { MobileWhepClientView };
//# sourceMappingURL=index.js.map