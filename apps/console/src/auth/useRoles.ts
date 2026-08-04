import { useMemo } from 'react'
import { useAuth } from './AuthContext'

function rolesFromUser(accessToken?: string, profile?: Record<string, unknown>): string[] {
  if (profile?.realm_access && typeof profile.realm_access === 'object') {
    const ra = profile.realm_access as { roles?: string[] }
    if (ra.roles?.length) return ra.roles
  }
  if (!accessToken) return []
  try {
    const payload = JSON.parse(atob(accessToken.split('.')[1] ?? '')) as {
      realm_access?: { roles?: string[] }
    }
    return payload.realm_access?.roles ?? []
  } catch {
    return []
  }
}

/** Role Keycloak realm (SRS-19). UI chỉ ẩn/hiện — BE vẫn @PreAuthorize. */
export function useRoles() {
  const { user } = useAuth()
  return useMemo(() => {
    const roleList = rolesFromUser(
      user?.access_token,
      user?.profile as Record<string, unknown> | undefined,
    )
    const roles = new Set(roleList)
    const has = (...names: string[]) => names.some((n) => roles.has(n))
    return {
      roles,
      canDesign: has('INTEGRATION_DEVELOPER', 'INTEGRATION_ADMIN', 'PLATFORM_ADMIN'),
      canReview: has('INTEGRATION_REVIEWER', 'INTEGRATION_ADMIN', 'PLATFORM_ADMIN'),
      canSubmit: has('INTEGRATION_DEVELOPER', 'INTEGRATION_ADMIN', 'PLATFORM_ADMIN'),
      username:
        (user?.profile?.preferred_username as string | undefined) ??
        (user?.profile?.email as string | undefined) ??
        '—',
      subject: (user?.profile?.sub as string | undefined) ?? '',
    }
  }, [user])
}
