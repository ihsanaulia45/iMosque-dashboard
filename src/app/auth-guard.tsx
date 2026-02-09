import { useEffect } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore, selectHasDashboardAccess } from '../stores/auth.store'
import { useSessionStore } from '../stores/session.store'

export function AuthGuard() {
  const user = useAuthStore((s) => s.user)
  const profile = useAuthStore((s) => s.profile)
  const isLoading = useAuthStore((s) => s.isLoading)
  const loadSession = useAuthStore((s) => s.loadSession)
  const hasAccess = useAuthStore(selectHasDashboardAccess)

  const start = useSessionStore((s) => s.start)
  const stop = useSessionStore((s) => s.stop)
  const showWarning = useSessionStore((s) => s.showWarning)
  const touch = useSessionStore((s) => s.touch)

  useEffect(() => {
    loadSession()
  }, [loadSession])

  useEffect(() => {
    if (user && hasAccess) {
      start()
      return () => stop()
    }
  }, [user, hasAccess, start, stop])

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen bg-gray-50">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-green-700 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user || !profile || !hasAccess) {
    return <Navigate to="/login" replace />
  }

  return (
    <>
      {showWarning && (
        <div className="fixed top-0 left-0 right-0 z-50 bg-amber-500 text-white text-center py-2 text-sm">
          Session expires in 5 minutes due to inactivity.
          <button onClick={touch} className="ml-3 underline font-medium">
            Stay logged in
          </button>
        </div>
      )}
      <Outlet />
    </>
  )
}
