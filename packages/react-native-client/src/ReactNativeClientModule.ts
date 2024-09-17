import {
  EventEmitter,
  requireNativeModule,
  Subscription,
} from "expo-modules-core";
import { ConfigurationOptions } from "./ReactNativeClient.types";
import { NativeModule } from "react-native";
import { useCallback, useEffect, useState } from "react";

type WhepClientReturnType = {
  connectWhepClient: () => Promise<void>;
  disconnectWhepClient: () => void;
};

type WhipClientReturnType = {
  connectWhipClient: () => Promise<void>;
  disconnectWhipClient: () => void;
};

type RNClientModule = {
  createWhepClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions
  ) => void;
  connectWhep: () => Promise<void>;
  disconnectWhep: () => void;
  createWhipClient: (
    serverUrl: string,
    configurationOptions?: ConfigurationOptions,
    videoDevice?: string
  ) => void;
  connectWhip: () => Promise<void>;
  disconnectWhip: () => void;
  captureDevices: ReadonlyArray<string>;
};

const nativeModule: RNClientModule & NativeModule =
  requireNativeModule("ReactNativeClient");
export const eventEmitter = new EventEmitter(nativeModule);

export function addTrackListener(listener: (event) => void): Subscription {
  return eventEmitter.addListener("trackAdded", listener);
}

export const useWhepClient = (
  serverUrl: string,
  configurationOptions?: ConfigurationOptions
) => {
  const [isClientCreated, setClientCreated] = useState(false);

  useEffect(() => {
    if (serverUrl) {
      nativeModule.createWhepClient(serverUrl, configurationOptions);
      setClientCreated(true);
    }

    return () => {
      if (isClientCreated) {
        nativeModule.disconnectWhep();
        setClientCreated(false);
      }
    };
  }, [serverUrl, configurationOptions]);

  const connectWhepClient = useCallback(async () => {
    if (isClientCreated) {
      console.log("got to client creation");
      return await nativeModule.connectWhep();
    }
    throw new Error("WHEP client has not been created properly.");
  }, [isClientCreated]);

  const disconnectWhepClient = useCallback(() => {
    if (isClientCreated) {
      return nativeModule.disconnectWhep();
    }
    throw new Error("WHEP client has not been created properly.");
  }, [isClientCreated]);

  return {
    connectWhepClient,
    disconnectWhepClient,
  };
};

export const useWhipClient = (
  serverUrl: string,
  configurationOptions?: ConfigurationOptions,
  videoDevice?: string
) => {
  const [isClientCreated, setClientCreated] = useState(false);

  useEffect(() => {
    if (serverUrl) {
      nativeModule.createWhipClient(
        serverUrl,
        configurationOptions,
        videoDevice
      );
      setClientCreated(true);
    }

    return () => {
      if (isClientCreated) {
        nativeModule.disconnectWhip();
      }
    };
  }, [serverUrl, configurationOptions, isClientCreated]);

  const connectWhipClient = useCallback(async () => {
    if (isClientCreated) {
      return await nativeModule.connectWhip();
    }
    throw new Error("WHIP client has not been created properly.");
  }, [isClientCreated]);

  const disconnectWhipClient = useCallback(() => {
    if (isClientCreated) {
      return nativeModule.disconnectWhip();
    }
    throw new Error("WHIP client has not been created properly.");
  }, [isClientCreated]);

  return {
    connectWhipClient,
    disconnectWhipClient,
  };
};

export const captureDevices = nativeModule.captureDevices;

export default nativeModule;
