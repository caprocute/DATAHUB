import { useCallback, useEffect, useState } from 'react';
import type { Mode } from './tokens';

/** Cùng khóa với `mockup/js/theme.js` để lựa chọn chế độ đi xuyên các trang mockup. */
const KEY = 'lgsp-theme';

function read(): Mode {
  try {
    const saved = localStorage.getItem(KEY);
    if (saved === 'light' || saved === 'dark') return saved;
  } catch {
    // Trình duyệt ở chế độ riêng tư có thể chặn localStorage.
  }
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

export function useTheme() {
  const [mode, setMode] = useState<Mode>(read);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', mode);
  }, [mode]);

  // Chỉ bám theo hệ điều hành khi người dùng chưa tự chọn.
  useEffect(() => {
    const mql = window.matchMedia?.('(prefers-color-scheme: dark)');
    if (!mql) return;
    const onChange = (e: MediaQueryListEvent) => {
      let saved: string | null = null;
      try {
        saved = localStorage.getItem(KEY);
      } catch {
        // bỏ qua
      }
      if (!saved) setMode(e.matches ? 'dark' : 'light');
    };
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, []);

  const toggle = useCallback(() => {
    setMode((prev) => {
      const next: Mode = prev === 'dark' ? 'light' : 'dark';
      try {
        localStorage.setItem(KEY, next);
      } catch {
        // bỏ qua
      }
      return next;
    });
  }, []);

  return { mode, toggle };
}
