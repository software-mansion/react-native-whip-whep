import { NativeModulesProxy, EventEmitter, } from "expo-modules-core";
import ReactNativeClientModule from "./ReactNativeClientModule";
import ReactNativeClientView from "./ReactNativeClientView";
// Get the native constant value.
export const PI = ReactNativeClientModule.PI;
export function hello() {
    return ReactNativeClientModule.hello();
}
export async function setValueAsync(value) {
    return await ReactNativeClientModule.setValueAsync(value);
}
const emitter = new EventEmitter(ReactNativeClientModule ?? NativeModulesProxy.ReactNativeClient);
export function addChangeListener(listener) {
    return emitter.addListener("onChange", listener);
}
export { ReactNativeClientView, };
//# sourceMappingURL=index.js.map