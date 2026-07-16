export type DebouncedFunction<T extends (...args: any[]) => any> = ((
  ...args: Parameters<T>
) => void) & {
  cancel(): void;
};

type DebounceOptions = {
  leading?: boolean;
  maxWait?: number;
};

export function debounce<T extends (...args: any[]) => any>(
  fn: T,
  ms: number,
  options: DebounceOptions = {}
): DebouncedFunction<T> {
  const { leading = false, maxWait } = options;
  let waitTimer: ReturnType<typeof setTimeout> | undefined;
  let maxTimer: ReturnType<typeof setTimeout> | undefined;
  let lastArgs: Parameters<T> | undefined;
  let lastThis: unknown;
  let lastInvokeTime = 0;

  const clearWaitTimer = () => {
    if (waitTimer) {
      clearTimeout(waitTimer);
      waitTimer = undefined;
    }
  };

  const clearMaxTimer = () => {
    if (maxTimer) {
      clearTimeout(maxTimer);
      maxTimer = undefined;
    }
  };

  const clearPendingCall = () => {
    lastArgs = undefined;
    lastThis = undefined;
  };

  const invoke = () => {
    if (!lastArgs) {
      return;
    }

    const args = lastArgs;
    const thisArg = lastThis;

    clearPendingCall();
    clearMaxTimer();
    lastInvokeTime = Date.now();
    fn.apply(thisArg, args);
  };

  const startWaitTimer = () => {
    clearWaitTimer();

    waitTimer = setTimeout(() => {
      waitTimer = undefined;

      if (leading) {
        clearPendingCall();
        clearMaxTimer();
        return;
      }

      invoke();
    }, ms);
  };

  const ensureMaxTimer = (now: number) => {
    if (maxWait == null || maxTimer || !lastArgs) {
      return;
    }

    const baseTime = lastInvokeTime || now;
    const remaining = Math.max(maxWait - (now - baseTime), 0);

    if (remaining === 0) {
      invoke();
      return;
    }

    maxTimer = setTimeout(() => {
      maxTimer = undefined;
      invoke();
    }, remaining);
  };

  const debounced = function (this: unknown, ...args: Parameters<T>) {
    const now = Date.now();

    lastArgs = args;
    lastThis = this;

    if (leading && !waitTimer) {
      invoke();
      startWaitTimer();
      return;
    }

    startWaitTimer();
    ensureMaxTimer(now);
  } as DebouncedFunction<T>;

  debounced.cancel = () => {
    clearWaitTimer();
    clearMaxTimer();
    clearPendingCall();
    lastInvokeTime = 0;
  };

  return debounced;
}
