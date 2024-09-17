export type ChangeEventPayload = {
  value: string;
};

export type ConfigurationOptions = {
  authToken?: string;
  stunServerUrl?: string;
  audioEnabled?: boolean;
  videoEnabled?: boolean;
  videoParameters?: VideoParameters;
};

export type WhipWhepClientViewProps = {
  playerType: PlayerType;
};

export enum PlayerType {
  WHEP = "WHEP",
  WHIP = "WHIP",
}

export enum VideoParameters {
  presetQVGA43 = "QVGA43",
  presetVGA43 = "VGA43",
  presetQHD43 = "QHD43",
  presetHD43 = "HD43",
  presetFHD43 = "FHD43",
  presetQVGA169 = "QVGA169",
  presetVGA169 = "VGA169",
  presetQHD169 = "QHD169",
  presetHD169 = "HD169",
  presetFHD169 = "FHD169",
}
