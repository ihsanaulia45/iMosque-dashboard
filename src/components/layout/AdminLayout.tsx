import { useState, useEffect } from 'react'
import { NavLink, Link, Outlet, useNavigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../../stores/auth.store'

const navItems = [
  { to: '/', label: 'Dashboard', icon: '⊞' },
  { to: '/users', label: 'Users', icon: '⊡' },
  { to: '/mosques', label: 'Mosques', icon: '◩' },
  { to: '/logs', label: 'Audit Logs', icon: '◷' },
  { to: '/settings', label: 'Settings', icon: '⚙' },
]

export function AdminLayout() {
  const { profile, signOut } = useAuthStore()
  const navigate = useNavigate()
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  // Close sidebar on route change (mobile)
  useEffect(() => {
    setSidebarOpen(false)
  }, [location.pathname])

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      {/* Backdrop (mobile only) */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/40 z-30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed inset-y-0 left-0 z-40 w-64 bg-green-800 text-white flex flex-col
          transform transition-transform duration-300 ease-in-out
          lg:relative lg:translate-x-0 lg:shrink-0
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        `}
      >
        <div className="p-5 border-b border-green-700 flex items-center justify-between">
          <h1 className="text-lg font-bold tracking-wide">iMosque Admin</h1>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden text-green-300 hover:text-white text-xl"
          >
            &times;
          </button>
        </div>
        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-5 py-2.5 text-sm transition-colors ${
                  isActive
                    ? 'bg-green-700 font-medium'
                    : 'hover:bg-green-700/50'
                }`
              }
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      {/* Main content area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Header / Navbar */}
        <header className="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-6 shrink-0">
          {/* Left: Hamburger (mobile only) */}
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden p-2 -ml-2 text-gray-600 hover:text-gray-800"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>

          {/* Right: User info + logout */}
          <div className="flex items-center gap-3 ml-auto">
            <Link to="/profile" className="text-right hover:opacity-80 transition hidden sm:block">
              <p className="text-sm font-medium text-gray-800">
                {profile?.full_name || 'Admin'}
              </p>
              <p className="text-xs text-gray-500 capitalize">{profile?.role}</p>
            </Link>
            <Link to="/profile" className="w-9 h-9 rounded-full bg-green-700 text-white flex items-center justify-center text-sm font-bold hover:opacity-80 transition">
              {(profile?.full_name?.[0] || 'A').toUpperCase()}
            </Link>
            <button
              onClick={handleSignOut}
              className="ml-2 text-xs text-gray-500 hover:text-red-600 transition-colors"
            >
              Logout
            </button>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-auto p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
