import { useEffect, useState } from 'react';

/**
 * Returns a debounced value that updates after `ms` delay when the input stops changing.
 */
export function useDebounce<T>(value: T, ms: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const id = window.setTimeout(() => setDebounced(value), ms);
    return () => window.clearTimeout(id);
  }, [value, ms]);

  return debounced;
}
