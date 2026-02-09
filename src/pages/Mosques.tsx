import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../app/supabase'
import { useAuthStore, selectIsDeveloper } from '../stores/auth.store'

interface Mosque {
  id: string
  name: string
  address: string | null
  city: string | null
  province: string | null
  latitude: number | null
  longitude: number | null
  phone: string | null
  description: string | null
  is_verified: boolean
  is_active: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

const EMPTY_FORM: Partial<Mosque> = {
  name: '',
  address: '',
  city: '',
  province: '',
  phone: '',
  description: '',
  latitude: null,
  longitude: null,
}

const PAGE_SIZE = 15

export default function Mosques() {
  const isDeveloper = useAuthStore(selectIsDeveloper)
  const { profile } = useAuthStore()

  const [mosques, setMosques] = useState<Mosque[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<'all' | 'verified' | 'pending' | 'inactive'>('all')
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  // Modals
  const [selected, setSelected] = useState<Mosque | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editTarget, setEditTarget] = useState<Mosque | null>(null)
  const [form, setForm] = useState<Partial<Mosque>>(EMPTY_FORM)
  const [formError, setFormError] = useState('')
  const [formSaving, setFormSaving] = useState(false)

  const fetchMosques = useCallback(async () => {
    setLoading(true)
    let query = supabase
      .from('mosques')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)

    if (search.trim()) {
      query = query.or(`name.ilike.%${search.trim()}%,address.ilike.%${search.trim()}%,city.ilike.%${search.trim()}%`)
    }
    if (filter === 'verified') query = query.eq('is_verified', true)
    if (filter === 'pending') query = query.eq('is_verified', false)
    if (filter === 'inactive') query = query.eq('is_active', false)

    const { data, count, error } = await query
    if (!error) {
      setMosques((data ?? []) as Mosque[])
      setTotal(count ?? 0)
    }
    setLoading(false)
  }, [page, search, filter])

  useEffect(() => { fetchMosques() }, [fetchMosques])
  useEffect(() => { setPage(0) }, [search, filter])

  const totalPages = Math.ceil(total / PAGE_SIZE)

  const handleVerify = async (mosque: Mosque, verified: boolean) => {
    setActionLoading(mosque.id)
    await supabase
      .from('mosques')
      .update({ is_verified: verified, updated_at: new Date().toISOString() })
      .eq('id', mosque.id)
    await fetchMosques()
    if (selected?.id === mosque.id) setSelected({ ...mosque, is_verified: verified })
    setActionLoading(null)
  }

  const handleActivate = async (mosque: Mosque, active: boolean) => {
    setActionLoading(mosque.id)
    await supabase
      .from('mosques')
      .update({ is_active: active, updated_at: new Date().toISOString() })
      .eq('id', mosque.id)
    await fetchMosques()
    if (selected?.id === mosque.id) setSelected({ ...mosque, is_active: active })
    setActionLoading(null)
  }

  const handleDelete = async (mosque: Mosque) => {
    if (!confirm(`Delete "${mosque.name}"? This cannot be undone.`)) return
    setActionLoading(mosque.id)
    await supabase.from('mosques').delete().eq('id', mosque.id)
    setSelected(null)
    await fetchMosques()
    setActionLoading(null)
  }

  const openAdd = () => {
    setEditTarget(null)
    setForm(EMPTY_FORM)
    setFormError('')
    setShowForm(true)
  }

  const openEdit = (m: Mosque) => {
    setEditTarget(m)
    setForm({
      name: m.name,
      address: m.address ?? '',
      city: m.city ?? '',
      province: m.province ?? '',
      phone: m.phone ?? '',
      description: m.description ?? '',
      latitude: m.latitude,
      longitude: m.longitude,
    })
    setFormError('')
    setShowForm(true)
  }

  const handleFormSave = async () => {
    if (!form.name?.trim()) {
      setFormError('Name is required')
      return
    }
    setFormSaving(true)
    setFormError('')

    const payload = {
      name: form.name!.trim(),
      address: form.address?.trim() || null,
      city: form.city?.trim() || null,
      province: form.province?.trim() || null,
      phone: form.phone?.trim() || null,
      description: form.description?.trim() || null,
      latitude: form.latitude ?? null,
      longitude: form.longitude ?? null,
      updated_at: new Date().toISOString(),
    }

    let error
    if (editTarget) {
      ({ error } = await supabase.from('mosques').update(payload).eq('id', editTarget.id))
    } else {
      ({ error } = await supabase.from('mosques').insert({
        ...payload,
        is_verified: false,
        is_active: true,
        created_by: profile?.id ?? null,
      }))
    }

    if (error) {
      setFormError(error.message)
    } else {
      setShowForm(false)
      await fetchMosques()
    }
    setFormSaving(false)
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-semibold text-gray-800">Mosques</h1>
        <button
          onClick={openAdd}
          className="px-4 py-2 bg-green-700 hover:bg-green-800 text-white text-sm rounded-lg font-medium"
        >
          + Add Mosque
        </button>
      </div>
      <p className="text-gray-500 mb-6">Manage all mosques in the system.</p>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-4">
        <input
          type="text"
          placeholder="Search name, address, city..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm w-64 focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        />
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as typeof filter)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
        >
          <option value="all">All</option>
          <option value="verified">Verified</option>
          <option value="pending">Pending</option>
          <option value="inactive">Inactive</option>
        </select>
        <span className="text-sm text-gray-500 self-center ml-auto">{total} mosques</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Name</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">City</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Status</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Active</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Created</th>
              <th className="text-right px-4 py-3 font-medium text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400">Loading...</td></tr>
            ) : mosques.length === 0 ? (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400">No mosques found.</td></tr>
            ) : (
              mosques.map((m) => (
                <tr key={m.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <button onClick={() => setSelected(m)} className="text-left hover:text-green-700">
                      <p className="font-medium text-gray-800">{m.name}</p>
                      <p className="text-xs text-gray-400">{m.address || '-'}</p>
                    </button>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{m.city || '-'}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                      m.is_verified ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                    }`}>
                      {m.is_verified ? 'Verified' : 'Pending'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                      m.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                    }`}>
                      {m.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500">{new Date(m.created_at).toLocaleDateString()}</td>
                  <td className="px-4 py-3 text-right space-x-2">
                    <button onClick={() => setSelected(m)} className="text-xs text-green-700 hover:underline">Detail</button>
                    <button onClick={() => openEdit(m)} className="text-xs text-blue-600 hover:underline">Edit</button>
                    {!m.is_verified && (
                      <button
                        onClick={() => handleVerify(m, true)}
                        disabled={actionLoading === m.id}
                        className="text-xs text-emerald-600 hover:underline"
                      >
                        Verify
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
          <p className="text-sm text-gray-500">Page {page + 1} of {totalPages}</p>
          <div className="flex gap-2">
            <button onClick={() => setPage((p) => Math.max(0, p - 1))} disabled={page === 0} className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50">Previous</button>
            <button onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))} disabled={page >= totalPages - 1} className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50">Next</button>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selected && !showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl mx-4 p-6 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-800">Mosque Detail</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            </div>

            <div className="space-y-4">
              <h3 className="text-xl font-bold text-gray-800">{selected.name}</h3>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500 mb-1">Address</p>
                  <p className="text-gray-700">{selected.address || '-'}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">City</p>
                  <p className="text-gray-700">{selected.city || '-'}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Province</p>
                  <p className="text-gray-700">{selected.province || '-'}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Phone</p>
                  <p className="text-gray-700">{selected.phone || '-'}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Coordinates</p>
                  <p className="text-gray-700">
                    {selected.latitude && selected.longitude
                      ? `${selected.latitude}, ${selected.longitude}`
                      : '-'}
                  </p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Created</p>
                  <p className="text-gray-700">{new Date(selected.created_at).toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Verification</p>
                  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                    selected.is_verified ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                  }`}>
                    {selected.is_verified ? 'Verified' : 'Pending'}
                  </span>
                </div>
                <div>
                  <p className="text-gray-500 mb-1">Active</p>
                  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${
                    selected.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {selected.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>
              </div>

              {selected.description && (
                <div>
                  <p className="text-gray-500 text-sm mb-1">Description</p>
                  <p className="text-gray-700 text-sm">{selected.description}</p>
                </div>
              )}

              <div className="flex flex-wrap gap-2 pt-2">
                <button
                  onClick={() => handleVerify(selected, !selected.is_verified)}
                  disabled={actionLoading === selected.id}
                  className={`px-4 py-2 text-sm rounded-lg font-medium text-white ${
                    selected.is_verified ? 'bg-amber-500 hover:bg-amber-600' : 'bg-green-600 hover:bg-green-700'
                  } disabled:opacity-50`}
                >
                  {selected.is_verified ? 'Unverify' : 'Verify'}
                </button>
                <button
                  onClick={() => handleActivate(selected, !selected.is_active)}
                  disabled={actionLoading === selected.id}
                  className={`px-4 py-2 text-sm rounded-lg font-medium text-white ${
                    selected.is_active ? 'bg-red-500 hover:bg-red-600' : 'bg-blue-600 hover:bg-blue-700'
                  } disabled:opacity-50`}
                >
                  {selected.is_active ? 'Deactivate' : 'Activate'}
                </button>
                <button
                  onClick={() => { setSelected(null); openEdit(selected) }}
                  className="px-4 py-2 text-sm rounded-lg font-medium border border-gray-300 hover:bg-gray-50"
                >
                  Edit
                </button>
                {isDeveloper && (
                  <button
                    onClick={() => handleDelete(selected)}
                    disabled={actionLoading === selected.id}
                    className="px-4 py-2 text-sm rounded-lg font-medium text-white bg-red-700 hover:bg-red-800 disabled:opacity-50"
                  >
                    Delete
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add / Edit Form Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30" onClick={() => setShowForm(false)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 p-6 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-800">{editTarget ? 'Edit Mosque' : 'Add Mosque'}</h2>
              <button onClick={() => setShowForm(false)} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            </div>

            {formError && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{formError}</div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
                <input type="text" value={form.name ?? ''} onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                <input type="text" value={form.address ?? ''} onChange={(e) => setForm({ ...form, address: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                  <input type="text" value={form.city ?? ''} onChange={(e) => setForm({ ...form, city: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Province</label>
                  <input type="text" value={form.province ?? ''} onChange={(e) => setForm({ ...form, province: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input type="text" value={form.phone ?? ''} onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Latitude</label>
                  <input type="number" step="any" value={form.latitude ?? ''} onChange={(e) => setForm({ ...form, latitude: e.target.value ? parseFloat(e.target.value) : null })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Longitude</label>
                  <input type="number" step="any" value={form.longitude ?? ''} onChange={(e) => setForm({ ...form, longitude: e.target.value ? parseFloat(e.target.value) : null })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea rows={3} value={form.description ?? ''} onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none resize-none" />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  onClick={handleFormSave}
                  disabled={formSaving}
                  className="px-4 py-2 bg-green-700 hover:bg-green-800 disabled:bg-green-400 text-white text-sm rounded-lg font-medium"
                >
                  {formSaving ? 'Saving...' : editTarget ? 'Update' : 'Create'}
                </button>
                <button onClick={() => setShowForm(false)} className="px-4 py-2 border border-gray-300 text-sm rounded-lg hover:bg-gray-50">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
