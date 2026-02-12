import { useState } from 'react'
import { supabase } from '../../app/supabase'

interface Props {
  mosqueId: string
  onDone: () => void
  onSkip: () => void
}

export function StepContacts({ mosqueId, onDone, onSkip }: Props) {
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [website, setWebsite] = useState('')
  const [officeHours, setOfficeHours] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const hasAnyData = phone.trim() || email.trim() || website.trim() || officeHours.trim()

  const handleFinish = async () => {
    if (!hasAnyData) {
      onSkip()
      return
    }

    setSaving(true)
    setError('')

    const { error: err } = await supabase
      .from('mosque_contacts')
      .insert({
        mosque_id: mosqueId,
        phone: phone.trim() || null,
        email: email.trim() || null,
        website: website.trim() || null,
        office_hours: officeHours.trim() || null,
      })

    if (err) {
      setError(err.message)
      setSaving(false)
      return
    }

    onDone()
  }

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
      )}

      <p className="text-sm text-gray-500">Add contact information for this mosque.</p>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
        <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)}
          placeholder="+62 21 xxxxxxx"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
          placeholder="info@mosque.org"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Website</label>
        <input type="url" value={website} onChange={(e) => setWebsite(e.target.value)}
          placeholder="https://mosque.org"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Office Hours</label>
        <input type="text" value={officeHours} onChange={(e) => setOfficeHours(e.target.value)}
          placeholder="Mon-Fri 08:00-17:00"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div className="flex gap-3 pt-2">
        <button
          onClick={handleFinish}
          disabled={saving}
          className="px-4 py-2 bg-green-700 hover:bg-green-800 disabled:bg-green-400 text-white text-sm rounded-lg font-medium"
        >
          {saving ? 'Saving...' : hasAnyData ? 'Finish' : 'Skip & Finish'}
        </button>
        <button onClick={onSkip} disabled={saving} className="px-4 py-2 border border-gray-300 text-sm rounded-lg hover:bg-gray-50">
          Skip
        </button>
      </div>
    </div>
  )
}
