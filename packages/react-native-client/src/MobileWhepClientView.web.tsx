import * as React from 'react';

import { MobileWhepClientViewProps } from './MobileWhepClient.types';

export default function MobileWhepClientView(props: MobileWhepClientViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
