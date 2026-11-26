import { ifMatch, newIdempotencyKey, unwrap, type CatalogGroup, type CatalogGroupCreateRequest, type CatalogGroupUpdateRequest } from '@datahub/api-client';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRdmClient } from '../../../shared/api/ApiProvider';

export const groupKeys = { tree: ['rdm', 'catalog-groups'] as const };

/** Cây nhóm (API-07-007): nhóm gốc của tenant và COMMON ở cấp 1, kèm catalogCount. */
export function useCatalogGroups() {
  const client = useRdmClient();
  return useQuery({
    queryKey: groupKeys.tree,
    queryFn: async (): Promise<CatalogGroup[]> => {
      const { data } = await unwrap(client.GET('/catalog-groups', { params: { query: { flat: false } } }));
      return data?.items ?? [];
    },
  });
}

export interface CreateGroupVariables {
  body: CatalogGroupCreateRequest;
  /** Khóa chống trùng giữ nguyên khi thử lại cùng một thao tác của người dùng. */
  idempotencyKey?: string;
}

/** Tạo nhóm (API-07-008): 201 + ETag; làm mới cây khi xong. */
export function useCreateGroup() {
  const client = useRdmClient();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ body, idempotencyKey = newIdempotencyKey() }: CreateGroupVariables): Promise<CatalogGroup> => {
      const { data } = await unwrap(
        client.POST('/catalog-groups', { body, params: { header: { 'Idempotency-Key': idempotencyKey } } }),
      );
      if (data === undefined) {
        throw new Error('Máy chủ không trả nhóm vừa tạo');
      }
      return data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: groupKeys.tree }),
  });
}

export interface UpdateGroupVariables {
  id: string;
  /** `version` của nhóm lúc đọc: gửi thành If-Match W/"{version}". */
  version: number;
  body: CatalogGroupUpdateRequest;
}

/** Sửa nhóm (API-07-009) với If-Match. */
export function useUpdateGroup() {
  const client = useRdmClient();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, version, body }: UpdateGroupVariables): Promise<CatalogGroup> => {
      const { data } = await unwrap(
        client.PATCH('/catalog-groups/{groupId}', {
          params: { path: { groupId: id }, header: { 'If-Match': ifMatch(version) } },
          body,
        }),
      );
      if (data === undefined) {
        throw new Error('Máy chủ không trả nhóm sau khi sửa');
      }
      return data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: groupKeys.tree }),
  });
}

export interface DeleteGroupVariables {
  id: string;
  version: number;
}

/** Xóa nhóm rỗng (API-07-010) với If-Match; còn danh mục hoặc nhóm con thì ERR-07-037. */
export function useDeleteGroup() {
  const client = useRdmClient();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, version }: DeleteGroupVariables): Promise<void> => {
      await unwrap(
        client.DELETE('/catalog-groups/{groupId}', {
          params: { path: { groupId: id }, header: { 'If-Match': ifMatch(version) } },
        }),
      );
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: groupKeys.tree }),
  });
}
