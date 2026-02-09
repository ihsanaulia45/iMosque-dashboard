import { useState } from 'react'
import { supabase } from '../app/supabase'
import { useAuthStore } from '../stores/auth.store'

export default function Profile() {
  const { profile, user, loadSession } = useAuthStore()
  const [editing, setEditing] = useState(false)
  const [fullName, setFullName] = useState(profile?.full_name ?? '')
  const [phone, setPhone] = useState(profile?.phone ?? '')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  const handleSave = async () => {
    if (!profile) return
    setSaving(true)
    setMessage('')

    const { error } = await supabase
      .from('profiles')
      .update({
        full_name: fullName.trim() || null,
        phone: phone.trim() || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', profile.id)

    if (error) {
      setMessage('Failed to update: ' + error.message)
    } else {
      setMessage('Profile updated successfully.')
      setEditing(false)
      // Refresh profile in store
      await loadSession()
    }
    setSaving(false)
  }

  if (!profile || !user) {
    return <div className="text-gray-400">Loading...</div>
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-800 mb-1">My Profile</h1>
      <p className="text-gray-500 mb-6">View and edit your profile information.</p>

      <div className="bg-white rounded-xl border border-gray-200 p-6 max-w-xl">
        {message && (
          <div className={`mb-4 p-3 rounded-lg text-sm ${
            message.includes('Failed') ? 'bg-red-50 border border-red-200 text-red-700' : 'bg-green-50 border border-green-200 text-green-700'
          }`}>
            {message}
          </div>
        )}

        <div className="flex items-center gap-4 mb-6">
          <div className="w-16 h-16 rounded-full bg-green-700 text-white flex items-center justify-center text-2xl font-bold">
            {(profile.full_name?.[0] || '?').toUpperCase()}
          </div>
          <div>
            <p className="text-lg font-medium text-gray-800">{profile.full_name || 'Unnamed'}</p>
            <p className="text-sm text-gray-500">{user.email}</p>
            <span className={`inline-block mt-1 px-2 py-0.5 text-xs rounded-full font-medium ${
              profile.role === 'admin' ? 'bg-purple-100 text-purple-700' :
              profile.role === 'developer' ? 'bg-blue-100 text-blue-700' :
              'bg-gray-100 text-gray-600'
            }`}>
              {profile.role}
            </span>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
            {editing ? (
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
              />
            ) : (
              <p className="text-gray-800 text-sm py-2">{profile.full_name || '-'}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            {editing ? (
              <input
                type="text"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none"
              />
            ) : (
              <p className="text-gray-800 text-sm py-2">{profile.phone || '-'}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <p className="text-gray-800 text-sm py-2">{user.email}</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">User ID</label>
            <p className="font-mono text-xs text-gray-500 py-2 break-all">{profile.id}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Joined</label>
              <p className="text-gray-800 text-sm py-2">{new Date(profile.created_at).toLocaleDateString()}</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Last Updated</label>
              <p className="text-gray-800 text-sm py-2">{new Date(profile.updated_at).toLocaleDateString()}</p>
            </div>
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          {editing ? (
            <>
              <button
                onClick={handleSave}
                disabled={saving}
                className="px-4 py-2 bg-green-700 hover:bg-green-800 disabled:bg-green-400 text-white text-sm rounded-lg font-medium"
              >
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
              <button
                onClick={() => { setEditing(false); setFullName(profile.full_name ?? ''); setPhone(profile.phone ?? '') }}
                className="px-4 py-2 border border-gray-300 text-sm rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
            </>
          ) : (
            <button
              onClick={() => setEditing(true)}
              className="px-4 py-2 bg-green-700 hover:bg-green-800 text-white text-sm rounded-lg font-medium"
            >
              Edit Profile
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
