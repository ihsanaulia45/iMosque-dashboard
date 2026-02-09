import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../app/supabase'
import { useAuthStore, selectIsAdmin, selectIsDeveloper } from '../stores/auth.store'

interface SystemSetting {
  id: string
  key: string
  value: string
  value_type: string
  category: string | null
  description: string | null
  is_public: boolean
  admin_editable: boolean
  updated_by: string | null
  updated_at: string
  created_at: string
}

export default function Settings() {
  const isAdmin = useAuthStore(selectIsAdmin)
  const isDeveloper = useAuthStore(selectIsDeveloper)
  const { profile } = useAuthStore()

  const [settings, setSettings] = useState<SystemSetting[]>([])
  const [loading, setLoading] = useState(true)
  const [tableExists, setTableExists] = useState(true)
  const [saving, setSaving] = useState<string | null>(null)
  const [editValues, setEditValues] = useState<Record<string, string>>({})

  const fetchSettings = useCallback(async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from('system_settings')
      .select('*')
      .order('category')
      .order('key')

    if (error) {
      const msg = error.message || ''
      const code = (error as { code?: string }).code || ''
      if (msg.includes('does not exist') || msg.includes('Could not find') || msg.includes('schema cache') || code === 'PGRST205' || code === '42P01') {
        setTableExists(false)
      }
      setSettings([])
    } else {
      const s = (data ?? []) as SystemSetting[]
      setSettings(s)
      const vals: Record<string, string> = {}
      s.forEach((item) => { vals[item.id] = item.value })
      setEditValues(vals)
    }
    setLoading(false)
  }, [])

  useEffect(() => { fetchSettings() }, [fetchSettings])

  const canEdit = (setting: SystemSetting) => {
    if (isDeveloper) return true
    if (isAdmin && setting.admin_editable) return true
    return false
  }

  const handleSave = async (setting: SystemSetting) => {
    const newValue = editValues[setting.id]
    if (newValue === setting.value) return

    // Validate by type
    if (setting.value_type === 'boolean' && !['true', 'false'].includes(newValue)) {
      alert('Value must be "true" or "false"')
      return
    }
    if (setting.value_type === 'number' && isNaN(Number(newValue))) {
      alert('Value must be a number')
      return
    }

    setSaving(setting.id)
    const { error } = await supabase
      .from('system_settings')
      .update({
        value: newValue,
        updated_by: profile?.id ?? null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', setting.id)

    if (error) {
      alert('Failed to save: ' + error.message)
    } else {
      await fetchSettings()
    }
    setSaving(null)
  }

  if (!tableExists) {
    return (
      <div>
        <h1 className="text-2xl font-semibold text-gray-800 mb-1">Settings</h1>
        <div className="mt-6 bg-amber-50 border border-amber-200 rounded-xl p-6">
          <h3 className="font-medium text-amber-800 mb-2">Table Not Found</h3>
          <p className="text-sm text-amber-700">
            The <code className="bg-amber-100 px-1 rounded">system_settings</code> table does not exist yet.
            Please run the SQL migration <code className="bg-amber-100 px-1 rounded">002_admin_dashboard_tables.sql</code> in the Supabase SQL Editor.
          </p>
        </div>
      </div>
    )
  }

  // Group by category
  const grouped = settings.reduce<Record<string, SystemSetting[]>>((acc, s) => {
    const cat = s.category || 'general'
    if (!acc[cat]) acc[cat] = []
    acc[cat].push(s)
    return acc
  }, {})

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-800 mb-1">Settings</h1>
      <p className="text-gray-500 mb-6">
        {isDeveloper ? 'Full system settings access.' : 'Admin-editable settings only.'}
      </p>

      {loading ? (
        <div className="text-gray-400">Loading settings...</div>
      ) : settings.length === 0 ? (
        <div className="bg-gray-50 rounded-xl p-6 text-center text-gray-500">No settings found.</div>
      ) : (
        <div className="space-y-6">
          {Object.entries(grouped).map(([category, items]) => (
            <div key={category} className="bg-white rounded-xl border border-gray-200">
              <div className="px-5 py-3 border-b border-gray-100">
                <h2 className="font-semibold text-gray-700 capitalize">{category}</h2>
              </div>
              <div className="divide-y divide-gray-100">
                {items.map((setting) => {
                  const editable = canEdit(setting)
                  const changed = editValues[setting.id] !== setting.value
                  return (
                    <div key={setting.id} className="px-5 py-4 flex items-start gap-4">
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-800">{setting.key}</p>
                        {setting.description && (
                          <p className="text-xs text-gray-500 mt-0.5">{setting.description}</p>
                        )}
                        <div className="flex gap-2 mt-1">
                          <span className="text-xs text-gray-400">Type: {setting.value_type}</span>
                          {!setting.admin_editable && (
                            <span className="text-xs text-amber-500">Developer only</span>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        {setting.value_type === 'boolean' ? (
                          <select
                            value={editValues[setting.id] ?? setting.value}
                            onChange={(e) => setEditValues({ ...editValues, [setting.id]: e.target.value })}
                            disabled={!editable}
                            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm disabled:opacity-50 disabled:bg-gray-50 focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
                          >
                            <option value="true">true</option>
                            <option value="false">false</option>
                          </select>
                        ) : (
                          <input
                            type={setting.value_type === 'number' ? 'number' : 'text'}
                            value={editValues[setting.id] ?? setting.value}
                            onChange={(e) => setEditValues({ ...editValues, [setting.id]: e.target.value })}
                            disabled={!editable}
                            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm w-48 disabled:opacity-50 disabled:bg-gray-50 focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
                          />
                        )}
                        {editable && changed && (
                          <button
                            onClick={() => handleSave(setting)}
                            disabled={saving === setting.id}
                            className="px-3 py-1.5 bg-green-700 hover:bg-green-800 text-white text-xs rounded-lg font-medium disabled:opacity-50"
                          >
                            {saving === setting.id ? '...' : 'Save'}
                          </button>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
