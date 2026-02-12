import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../app/supabase'
import { useAuthStore, selectIsDeveloper } from '../stores/auth.store'
import type { UserRole } from '../stores/auth.store'

interface UserRow {
  id: string
  full_name: string | null
  phone: string | null
  role: UserRole
  avatar_url: string | null
  is_active?: boolean
  created_at: string
  updated_at: string
}

const ROLES: UserRole[] = ['user', 'ustadz', 'operator', 'admin', 'developer']
const PAGE_SIZE = 15

export default function Users() {
  const isDeveloper = useAuthStore(selectIsDeveloper)
  const { profile: myProfile } = useAuthStore()

  const [users, setUsers] = useState<UserRow[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState<string>('all')
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  // Detail modal
  const [selected, setSelected] = useState<UserRow | null>(null)

  const fetchUsers = useCallback(async () => {
    setLoading(true)
    let query = supabase
      .from('profiles')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)

    if (search.trim()) {
      query = query.or(`full_name.ilike.%${search.trim()}%,phone.ilike.%${search.trim()}%`)
    }
    if (roleFilter !== 'all') {
      query = query.eq('role', roleFilter)
    }

    const { data, count, error } = await query
    if (!error) {
      setUsers((data ?? []) as UserRow[])
      setTotal(count ?? 0)
    }
    setLoading(false)
  }, [page, search, roleFilter])

  useEffect(() => {
    fetchUsers()
  }, [fetchUsers])

  // Reset page when filters change
  useEffect(() => {
    setPage(0)
  }, [search, roleFilter])

  const totalPages = Math.ceil(total / PAGE_SIZE)

  const handleBlock = async (user: UserRow) => {
    const newStatus = user.is_active === false ? true : false
    setActionLoading(user.id)
    const { error } = await supabase
      .from('profiles')
      .update({ is_active: newStatus, updated_at: new Date().toISOString() })
      .eq('id', user.id)

    if (!error) {
      await fetchUsers()
      if (selected?.id === user.id) {
        setSelected({ ...user, is_active: newStatus })
      }
    }
    setActionLoading(null)
  }

  const handleRoleChange = async (user: UserRow, newRole: UserRole) => {
    setActionLoading(user.id)
    const { error } = await supabase
      .from('profiles')
      .update({ role: newRole, updated_at: new Date().toISOString() })
      .eq('id', user.id)

    if (!error) {
      await fetchUsers()
      if (selected?.id === user.id) {
        setSelected({ ...user, role: newRole })
      }
    }
    setActionLoading(null)
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-800 mb-1">Users</h1>
      <p className="text-gray-500 mb-6">Manage all registered users.</p>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-4">
        <input
          type="text"
          placeholder="Search by name or phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm w-64 focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        />
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        >
          <option value="all">All Roles</option>
          {ROLES.map((r) => (
            <option key={r} value={r}>{r}</option>
          ))}
        </select>
        <span className="text-sm text-gray-500 self-center ml-auto">{total} users</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-x-auto">
        <table className="min-w-[700px] w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Name</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Phone</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Role</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Status</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Joined</th>
              <th className="text-right px-4 py-3 font-medium text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400">Loading...</td></tr>
            ) : users.length === 0 ? (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400">No users found.</td></tr>
            ) : (
              users.map((u) => (
                <tr key={u.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <button onClick={() => setSelected(u)} className="text-left hover:text-green-700">
                      <p className="font-medium text-gray-800">{u.full_name || 'Unnamed'}</p>
                      <p className="text-xs text-gray-400 font-mono">{u.id.slice(0, 8)}...</p>
                    </button>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{u.phone || '-'}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                      u.role === 'admin' ? 'bg-purple-100 text-purple-700' :
                      u.role === 'developer' ? 'bg-blue-100 text-blue-700' :
                      u.role === 'operator' ? 'bg-green-100 text-green-700' :
                      u.role === 'ustadz' ? 'bg-amber-100 text-amber-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {u.role}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                      u.is_active === false ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
                    }`}>
                      {u.is_active === false ? 'Blocked' : 'Active'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500">{new Date(u.created_at).toLocaleDateString()}</td>
                  <td className="px-4 py-3 text-right space-x-2">
                    <button
                      onClick={() => setSelected(u)}
                      className="text-xs text-green-700 hover:underline"
                    >
                      Detail
                    </button>
                    {u.id !== myProfile?.id && (
                      <button
                        onClick={() => handleBlock(u)}
                        disabled={actionLoading === u.id}
                        className={`text-xs hover:underline ${u.is_active === false ? 'text-blue-600' : 'text-red-600'}`}
                      >
                        {actionLoading === u.id ? '...' : u.is_active === false ? 'Unblock' : 'Block'}
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">
            Page {page + 1} of {totalPages}
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0}
              className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50"
            >
              Previous
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1}
              className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-800">User Detail</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-full bg-green-700 text-white flex items-center justify-center text-xl font-bold">
                  {(selected.full_name?.[0] || '?').toUpperCase()}
                </div>
                <div>
                  <p className="text-lg font-medium text-gray-800">{selected.full_name || 'Unnamed'}</p>
                  <p className="text-sm text-gray-500">{selected.phone || 'No phone'}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500 mb-1">ID</p>
                  <p className="font-mono text-xs text-gray-700 break-all">{selected.id}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Status</p>
                  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                    selected.is_active === false ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
                  }`}>
                    {selected.is_active === false ? 'Blocked' : 'Active'}
                  </span>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Joined</p>
                  <p className="text-gray-700">{new Date(selected.created_at).toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Updated</p>
                  <p className="text-gray-700">{new Date(selected.updated_at).toLocaleString()}</p>
                </div>
              </div>

              {/* Role change - developer only */}
              <div>
                <p className="text-gray-500 text-sm mb-1">Role</p>
                {isDeveloper && selected.id !== myProfile?.id ? (
                  <select
                    value={selected.role}
                    onChange={(e) => handleRoleChange(selected, e.target.value as UserRole)}
                    disabled={actionLoading === selected.id}
                    className="px-3 py-2 border border-gray-300 rounded-lg text-sm w-full focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
                  >
                    {ROLES.map((r) => (
                      <option key={r} value={r}>{r}</option>
                    ))}
                  </select>
                ) : (
                  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                    selected.role === 'admin' ? 'bg-purple-100 text-purple-700' :
                    selected.role === 'developer' ? 'bg-blue-100 text-blue-700' :
                    'bg-gray-100 text-gray-600'
                  }`}>
                    {selected.role}
                    {!isDeveloper && <span className="ml-1 text-gray-400">(only developer can change roles)</span>}
                  </span>
                )}
              </div>

              {/* Block/Unblock */}
              {selected.id !== myProfile?.id && (
                <div className="pt-2 flex gap-2">
                  <button
                    onClick={() => handleBlock(selected)}
                    disabled={actionLoading === selected.id}
                    className={`px-4 py-2 text-sm rounded-lg font-medium text-white ${
                      selected.is_active === false
                        ? 'bg-blue-600 hover:bg-blue-700'
                        : 'bg-red-600 hover:bg-red-700'
                    } disabled:opacity-50`}
                  >
                    {actionLoading === selected.id ? 'Processing...' : selected.is_active === false ? 'Unblock User' : 'Block User'}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
