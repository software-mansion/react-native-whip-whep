import { NativeModulesProxy, EventEmitter, } from "expo-modules-core";
import ReactNativeClientModule, { addTrackListener, } from "./ReactNativeClientModule";
import { ReactNativeClientView } from "./ReactNativeClientView";
// Get the native constant value.
export const PI = ReactNativeClientModule.PI;
export const whepClient = ReactNativeClientModule.whepClient;
export function hello() {
    return ReactNativeClientModule.hello();
}
export async function createWhepClient(serverUrl, configurationOptions) {
    return await ReactNativeClientModule.createClient(serverUrl, configurationOptions);
}
export async function connectWhipClient() {
    return await ReactNativeClientModule.connectWhip();
}
export function disconnectWhipClient() {
    return ReactNativeClientModule.disconnectWhip();
}
export async function createWhipClient(serverUrl, configurationOptions) {
    return await ReactNativeClientModule.createWhipClient(serverUrl, configurationOptions);
}
export async function connectWhepClient() {
    return await ReactNativeClientModule.connect();
}
export function disconnectWhepClient() {
    return ReactNativeClientModule.disconnect();
}
const emitter = new EventEmitter(ReactNativeClientModule ?? NativeModulesProxy.ReactNativeClient);
export function addChangeListener(listener) {
    return emitter.addListener("onChange", listener);
}
export { ReactNativeClientView, addTrackListener, };
//# sourceMappingURL=index.js.map