import { EventEmitter } from "expo-modules-core";

import nativeModule from "./ReactNativeClientModule";

export const eventEmitter = new EventEmitter(nativeModule);
