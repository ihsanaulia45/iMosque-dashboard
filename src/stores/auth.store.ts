import { create } from 'zustand'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../app/supabase'

export type UserRole = 'user' | 'ustadz' | 'operator' | 'admin' | 'developer'

export interface Profile {
  id: string
  full_name: string | null
  phone: string | null
  role: UserRole
  avatar_url: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

function parseProfile(data: Record<string, unknown>): Profile {
  return {
    id: data.id as string,
    full_name: (data.full_name as string) ?? null,
    phone: (data.phone as string) ?? null,
    role: (data.role as UserRole) ?? 'user',
    avatar_url: (data.avatar_url as string) ?? null,
    is_active: (data.is_active as boolean) ?? true,
    created_at: data.created_at as string,
    updated_at: data.updated_at as string,
  }
}

async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !data) return null
  return parseProfile(data as Record<string, unknown>)
}

function hasDashboardRole(role?: UserRole): boolean {
  return role === 'admin' || role === 'developer'
}

interface AuthState {
  user: User | null
  profile: Profile | null
  isLoading: boolean
  error: string | null

  signIn: (email: string, password: string) => Promise<boolean>
  signOut: () => Promise<void>
  loadSession: () => Promise<void>
  clearError: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  profile: null,
  isLoading: true,
  error: null,

  signIn: async (email: string, password: string) => {
    set({ isLoading: true, error: null })

    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })

      if (error) {
        set({ isLoading: false, error: error.message })
        return false
      }

      if (!data.user) {
        set({ isLoading: false, error: 'Authentication failed' })
        return false
      }

      const profile = await fetchProfile(data.user.id)

      if (!profile) {
        await supabase.auth.signOut()
        set({ isLoading: false, error: 'Failed to load profile' })
        return false
      }

      if (!hasDashboardRole(profile.role)) {
        await supabase.auth.signOut()
        set({ isLoading: false, error: 'Access denied. Only admin and developer can access this dashboard.' })
        return false
      }

      set({ user: data.user, profile, isLoading: false, error: null })
      return true
    } catch (err) {
      set({ isLoading: false, error: `Login error: ${err}` })
      return false
    }
  },

  signOut: async () => {
    await supabase.auth.signOut()
    set({ user: null, profile: null, isLoading: false, error: null })
  },

  loadSession: async () => {
    set({ isLoading: true })

    try {
      const { data: { session } } = await supabase.auth.getSession()

      if (!session?.user) {
        set({ user: null, profile: null, isLoading: false })
        return
      }

      const profile = await fetchProfile(session.user.id)

      if (!profile || !hasDashboardRole(profile.role)) {
        await supabase.auth.signOut()
        set({ user: null, profile: null, isLoading: false })
        return
      }

      set({ user: session.user, profile, isLoading: false })
    } catch {
      set({ user: null, profile: null, isLoading: false })
    }
  },

  clearError: () => set({ error: null }),
}))

// Selectors — use these in components
export const selectHasDashboardAccess = (state: AuthState) =>
  hasDashboardRole(state.profile?.role)

export const selectIsAdmin = (state: AuthState) =>
  state.profile?.role === 'admin'

export const selectIsDeveloper = (state: AuthState) =>
  state.profile?.role === 'developer'
