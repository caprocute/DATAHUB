import { createRdmClient, type RdmClient } from '@datahub/api-client';
import { createContext, useContext, useMemo, type ReactNode } from 'react';
import { tokenStore } from '../auth/token-store';

const ApiContext = createContext<RdmClient | undefined>(undefined);

export interface ApiProviderProps {
  children: ReactNode;
  /** Thay client (kiểm thử). */
  client?: RdmClient;
}

/** Cấp client API sinh từ OpenAPI, đã gắn middleware Bearer, traceparent, Idempotency-Key. */
export function ApiProvider({ children, client }: ApiProviderProps) {
  const value = useMemo(() => client ?? createRdmClient({ getToken: () => tokenStore.get() }), [client]);
  return <ApiContext.Provider value={value}>{children}</ApiContext.Provider>;
}

export function useRdmClient(): RdmClient {
  const client = useContext(ApiContext);
  if (client === undefined) {
    throw new Error('useRdmClient phải nằm trong ApiProvider');
  }
  return client;
}
