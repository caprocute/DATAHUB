export type { paths, components } from './generated/rdm';
export { createRdmClient, requestHeaders, ifMatch, newIdempotencyKey } from './client';
export type { RdmClient, RdmClientOptions } from './client';
export { ApiProblemError, ApiNetworkError, unwrap } from './problem';
export type { ProblemDetails, ProblemError } from './problem';

import type { components } from './generated/rdm';
export type CatalogGroup = components['schemas']['CatalogGroup'];
export type CatalogGroupCreateRequest = components['schemas']['CatalogGroupCreateRequest'];
export type CatalogGroupUpdateRequest = components['schemas']['CatalogGroupUpdateRequest'];
