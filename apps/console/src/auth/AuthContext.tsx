import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import type { User } from 'oidc-client-ts'
import { handleOidcCallback, startLogin, userManager } from './oidc'

type AuthState = {
  user: User | null
  loading: boolean
  /** Đường dẫn cần tới sau khi vừa đăng nhập xong; `null` nếu không phải lượt callback. */
  redirectTo: string | null
  /** Xóa dấu điều hướng sau khi Router đã đi tới nơi. */
  clearRedirect: () => void
  login: (returnTo?: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [redirectTo, setRedirectTo] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const target = await handleOidcCallback()
        const current = await userManager.getUser()
        if (!cancelled) {
          setUser(current)
          if (target) setRedirectTo(target)
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()

    // Phiên có thể đổi ngoài lượt gắn kết này: gia hạn ngầm, đăng xuất ở thẻ khác,
    // hoặc callback hoàn tất sau khi component đã vẽ. Không lắng nghe thì giao diện
    // vẫn giữ trạng thái cũ và người dùng thấy trang đăng nhập dù đã có phiên.
    const onLoaded = (u: User) => {
      if (!cancelled) setUser(u)
    }
    const onUnloaded = () => {
      if (!cancelled) setUser(null)
    }
    userManager.events.addUserLoaded(onLoaded)
    userManager.events.addUserUnloaded(onUnloaded)

    return () => {
      cancelled = true
      userManager.events.removeUserLoaded(onLoaded)
      userManager.events.removeUserUnloaded(onUnloaded)
    }
  }, [])

  const value: AuthState = {
    user,
    loading,
    redirectTo,
    clearRedirect: () => setRedirectTo(null),
    login: (returnTo?: string) => startLogin(returnTo),
    logout: async () => {
      await userManager.signoutRedirect()
    },
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth outside AuthProvider')
  return ctx
}
