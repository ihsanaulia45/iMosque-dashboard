import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../app/supabase'
import { useAuthStore, selectIsDeveloper } from '../stores/auth.store'

interface AuditLog {
  id: string
  actor_id: string | null
  action: string
  target_type: string | null
  target_id: string | null
  details: Record<string, unknown> | null
  ip_address: string | null
  user_agent: string | null
  created_at: string
}

const PAGE_SIZE = 20

export default function Logs() {
  const isDeveloper = useAuthStore(selectIsDeveloper)
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [actionFilter, setActionFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [tableExists, setTableExists] = useState(true)
  const [selected, setSelected] = useState<AuditLog | null>(null)

  const fetchLogs = useCallback(async () => {
    setLoading(true)
    const { data, count, error } = await (async () => {
      let query = supabase
        .from('audit_logs')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)

      if (search.trim()) {
        query = query.or(`action.ilike.%${search.trim()}%,target_type.ilike.%${search.trim()}%`)
      }
      if (actionFilter !== 'all') {
        query = query.eq('action', actionFilter)
      }
      return query
    })()

    if (error) {
      // Table might not exist yet
      const msg = error.message || ''
      const code = (error as { code?: string }).code || ''
      if (msg.includes('does not exist') || msg.includes('Could not find') || msg.includes('schema cache') || code === 'PGRST205' || code === '42P01') {
        setTableExists(false)
      }
      setLogs([])
      setTotal(0)
    } else {
      setLogs((data ?? []) as AuditLog[])
      setTotal(count ?? 0)
    }
    setLoading(false)
  }, [page, search, actionFilter])

  useEffect(() => { fetchLogs() }, [fetchLogs])
  useEffect(() => { setPage(0) }, [search, actionFilter])

  const totalPages = Math.ceil(total / PAGE_SIZE)

  if (!tableExists) {
    return (
      <div>
        <h1 className="text-2xl font-semibold text-gray-800 mb-1">Audit Logs</h1>
        <div className="mt-6 bg-amber-50 border border-amber-200 rounded-xl p-6">
          <h3 className="font-medium text-amber-800 mb-2">Table Not Found</h3>
          <p className="text-sm text-amber-700">
            The <code className="bg-amber-100 px-1 rounded">audit_logs</code> table does not exist yet.
            Please run the SQL migration <code className="bg-amber-100 px-1 rounded">002_admin_dashboard_tables.sql</code> in the Supabase SQL Editor.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-800 mb-1">Audit Logs</h1>
      <p className="text-gray-500 mb-6">
        {isDeveloper ? 'Full system audit trail.' : 'Your admin activity log.'}
      </p>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-4">
        <input
          type="text"
          placeholder="Search action or target..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm w-64 focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        />
        <select
          value={actionFilter}
          onChange={(e) => setActionFilter(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        >
          <option value="all">All Actions</option>
          <option value="login">Login</option>
          <option value="logout">Logout</option>
          <option value="create">Create</option>
          <option value="update">Update</option>
          <option value="delete">Delete</option>
          <option value="verify">Verify</option>
          <option value="block">Block</option>
          <option value="unblock">Unblock</option>
        </select>
        <span className="text-sm text-gray-500 self-center ml-auto">{total} entries</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Time</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Action</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Target</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Actor</th>
              {isDeveloper && <th className="text-left px-4 py-3 font-medium text-gray-600">IP</th>}
              <th className="text-right px-4 py-3 font-medium text-gray-600"></th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={isDeveloper ? 6 : 5} className="text-center py-8 text-gray-400">Loading...</td></tr>
            ) : logs.length === 0 ? (
              <tr><td colSpan={isDeveloper ? 6 : 5} className="text-center py-8 text-gray-400">No logs found.</td></tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{new Date(log.created_at).toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <span className="inline-block px-2 py-0.5 text-xs rounded-full font-medium bg-gray-100 text-gray-700">
                      {log.action}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {log.target_type && <span className="text-gray-500">{log.target_type}: </span>}
                    <span className="font-mono text-xs">{log.target_id?.slice(0, 8) ?? '-'}</span>
                  </td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">{log.actor_id?.slice(0, 8) ?? '-'}</td>
                  {isDeveloper && (
                    <td className="px-4 py-3 text-xs text-gray-400">{log.ip_address ?? '-'}</td>
                  )}
                  <td className="px-4 py-3 text-right">
                    <button onClick={() => setSelected(log)} className="text-xs text-green-700 hover:underline">Detail</button>
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
          <p className="text-sm text-gray-500">Page {page + 1} of {totalPages}</p>
          <div className="flex gap-2">
            <button onClick={() => setPage((p) => Math.max(0, p - 1))} disabled={page === 0} className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50">Previous</button>
            <button onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))} disabled={page >= totalPages - 1} className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50">Next</button>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-800">Log Detail</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            </div>
            <div className="space-y-3 text-sm">
              <div><span className="text-gray-500">ID:</span> <span className="font-mono text-xs">{selected.id}</span></div>
              <div><span className="text-gray-500">Action:</span> <span className="font-medium">{selected.action}</span></div>
              <div><span className="text-gray-500">Actor:</span> <span className="font-mono text-xs">{selected.actor_id ?? '-'}</span></div>
              <div><span className="text-gray-500">Target:</span> {selected.target_type} / <span className="font-mono text-xs">{selected.target_id ?? '-'}</span></div>
              <div><span className="text-gray-500">Time:</span> {new Date(selected.created_at).toLocaleString()}</div>
              {isDeveloper && (
                <>
                  <div><span className="text-gray-500">IP:</span> {selected.ip_address ?? '-'}</div>
                  <div><span className="text-gray-500">User Agent:</span> <span className="text-xs break-all">{selected.user_agent ?? '-'}</span></div>
                </>
              )}
              {selected.details && (
                <div>
                  <span className="text-gray-500">Details:</span>
                  <pre className="mt-1 bg-gray-50 rounded-lg p-3 text-xs overflow-auto max-h-48">
                    {JSON.stringify(selected.details, null, 2)}
                  </pre>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
