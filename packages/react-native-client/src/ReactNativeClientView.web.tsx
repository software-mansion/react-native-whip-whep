import * as React from 'react';

import { ReactNativeClientViewProps } from './ReactNativeClient.types';

export default function ReactNativeClientView(props: ReactNativeClientViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
