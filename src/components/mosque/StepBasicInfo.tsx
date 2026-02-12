import { useState } from 'react'
import { supabase } from '../../app/supabase'
import { useAuthStore } from '../../stores/auth.store'

interface Props {
  onDone: (mosqueId: string, mosqueName: string) => void
  onCancel: () => void
}

export function StepBasicInfo({ onDone, onCancel }: Props) {
  const { profile } = useAuthStore()

  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [province, setProvince] = useState('')
  const [postalCode, setPostalCode] = useState('')
  const [latitude, setLatitude] = useState('')
  const [longitude, setLongitude] = useState('')
  const [description, setDescription] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const canSubmit = name.trim() && latitude.trim() && longitude.trim()

  const handleNext = async () => {
    if (!canSubmit) return
    setSaving(true)
    setError('')

    const lat = parseFloat(latitude)
    const lng = parseFloat(longitude)
    if (isNaN(lat) || isNaN(lng)) {
      setError('Latitude and Longitude must be valid numbers')
      setSaving(false)
      return
    }

    const { data, error: err } = await supabase
      .from('mosques')
      .insert({
        name: name.trim(),
        address: address.trim() || null,
        city: city.trim() || null,
        province: province.trim() || null,
        postal_code: postalCode.trim() || null,
        latitude: lat,
        longitude: lng,
        description: description.trim() || null,
        is_verified: false,
        created_by: profile?.id ?? null,
      })
      .select('id')
      .single()

    if (err) {
      setError(err.message)
      setSaving(false)
      return
    }

    onDone(data.id, name.trim())
  }

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Mosque Name *</label>
        <input type="text" value={name} onChange={(e) => setName(e.target.value)}
          placeholder="e.g. Masjid Al-Ikhlas"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
        <input type="text" value={address} onChange={(e) => setAddress(e.target.value)}
          placeholder="Full street address"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
          <input type="text" value={city} onChange={(e) => setCity(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Province</label>
          <input type="text" value={province} onChange={(e) => setProvince(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Postal Code</label>
        <input type="text" value={postalCode} onChange={(e) => setPostalCode(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Latitude *</label>
          <input type="text" inputMode="decimal" value={latitude} onChange={(e) => setLatitude(e.target.value)}
            placeholder="-6.2088"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Longitude *</label>
          <input type="text" inputMode="decimal" value={longitude} onChange={(e) => setLongitude(e.target.value)}
            placeholder="106.8456"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none" />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
        <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)}
          placeholder="Brief description of the mosque"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-600 focus:border-transparent outline-none resize-none" />
      </div>

      <div className="flex gap-3 pt-2">
        <button
          onClick={handleNext}
          disabled={saving || !canSubmit}
          className="px-4 py-2 bg-green-700 hover:bg-green-800 disabled:bg-green-400 text-white text-sm rounded-lg font-medium"
        >
          {saving ? 'Creating...' : 'Next: Facilities →'}
        </button>
        <button onClick={onCancel} className="px-4 py-2 border border-gray-300 text-sm rounded-lg hover:bg-gray-50">
          Cancel
        </button>
      </div>
    </div>
  )
}
