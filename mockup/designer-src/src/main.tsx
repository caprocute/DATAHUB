import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

// Hệ thiết kế dùng chung của mockup — cùng tệp mà các trang HTML tĩnh dùng, nên trang
// này và các trang kia luôn cùng một bộ token. Xem ADR-016.
import '../../css/app.css';
import '@xyflow/react/dist/style.css';
import './designer.css';

import { App } from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
