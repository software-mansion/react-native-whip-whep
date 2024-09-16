import ReactNativeClientModule, { addTrackListener, } from "./ReactNativeClientModule";
import { ReactNativeClientView } from "./ReactNativeClientView";
export function createWhepClient(serverUrl, configurationOptions) {
    return ReactNativeClientModule.createWhepClient(serverUrl, configurationOptions);
}
export async function connectWhepClient() {
    return await ReactNativeClientModule.connectWhep();
}
export function disconnectWhepClient() {
    return ReactNativeClientModule.disconnectWhep();
}
export function createWhipClient(serverUrl, configurationOptions, videoDevice) {
    return ReactNativeClientModule.createWhipClient(serverUrl, configurationOptions, videoDevice);
}
export async function connectWhipClient() {
    return await ReactNativeClientModule.connectWhip();
}
export function disconnectWhipClient() {
    return ReactNativeClientModule.disconnectWhip();
}
export function getCaptureDevices() {
    return ReactNativeClientModule.getCaptureDevices();
}
export { ReactNativeClientView, addTrackListener };
export { PlayerType, VideoParameters, } from "./ReactNativeClient.types";
//# sourceMappingURL=index.js.map