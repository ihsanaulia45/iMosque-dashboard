import { create } from 'zustand'
import { useAuthStore } from './auth.store'

const SESSION_TIMEOUT = 30 * 60 * 1000 // 30 minutes
const WARNING_BEFORE = 5 * 60 * 1000   // 5 minutes before timeout

interface SessionState {
  lastActivity: number
  showWarning: boolean
  timerId: ReturnType<typeof setInterval> | null

  start: () => void
  stop: () => void
  touch: () => void
}

export const useSessionStore = create<SessionState>((set, get) => ({
  lastActivity: Date.now(),
  showWarning: false,
  timerId: null,

  start: () => {
    get().stop()

    const id = setInterval(() => {
      const elapsed = Date.now() - get().lastActivity
      if (elapsed >= SESSION_TIMEOUT) {
        get().stop()
        useAuthStore.getState().signOut()
      } else if (elapsed >= SESSION_TIMEOUT - WARNING_BEFORE) {
        set({ showWarning: true })
      }
    }, 10_000) // check every 10s

    set({ timerId: id, lastActivity: Date.now(), showWarning: false })

    // Track user activity
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart']
    const handler = () => get().touch()
    events.forEach(e => window.addEventListener(e, handler, { passive: true }))
  },

  stop: () => {
    const { timerId } = get()
    if (timerId) clearInterval(timerId)
    set({ timerId: null, showWarning: false })
  },

  touch: () => {
    set({ lastActivity: Date.now(), showWarning: false })
  },
}))
