import { NavLink, Link, Outlet, useNavigate } from 'react-router-dom'
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

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-56 bg-green-800 text-white flex flex-col shrink-0">
        <div className="p-5 border-b border-green-700">
          <h1 className="text-lg font-bold tracking-wide">iMosque Admin</h1>
        </div>
        <nav className="flex-1 py-4">
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

      {/* Main */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-14 bg-white border-b border-gray-200 flex items-center justify-end px-6 shrink-0">
          <div className="flex items-center gap-3">
            <Link to="/profile" className="text-right hover:opacity-80 transition">
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

        {/* Content */}
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
