import { useState } from 'react'
import { supabase } from '../../app/supabase'

// From mosque_facilities CHECK constraint in database
const FACILITY_TYPES = [
  { key: 'ac', label: 'AC / Air Conditioning' },
  { key: 'parking', label: 'Parking Area' },
  { key: 'wudu_area', label: 'Wudu Area' },
  { key: 'wheelchair', label: 'Wheelchair Access' },
  { key: 'library', label: 'Library' },
  { key: 'canteen', label: 'Canteen' },
  { key: 'childcare', label: 'Childcare' },
  { key: 'wifi', label: 'Wi-Fi' },
  { key: 'women_area', label: "Women's Area" },
  { key: 'sound_system', label: 'Sound System' },
] as const

interface Props {
  mosqueId: string
  onDone: () => void
  onSkip: () => void
}

export function StepFacilities({ mosqueId, onDone, onSkip }: Props) {
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const toggle = (key: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  const handleNext = async () => {
    if (selected.size === 0) {
      onSkip()
      return
    }

    setSaving(true)
    setError('')

    const rows = Array.from(selected).map((facility_type) => ({
      mosque_id: mosqueId,
      facility_type,
      is_available: true,
    }))

    const { error: err } = await supabase
      .from('mosque_facilities')
      .insert(rows)

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

      <p className="text-sm text-gray-500">Select the facilities available at this mosque.</p>

      <div className="grid grid-cols-2 gap-2">
        {FACILITY_TYPES.map(({ key, label }) => {
          const isOn = selected.has(key)
          return (
            <button
              key={key}
              type="button"
              onClick={() => toggle(key)}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-lg border text-sm text-left transition ${
                isOn
                  ? 'border-green-600 bg-green-50 text-green-800'
                  : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'
              }`}
            >
              <div className={`w-4 h-4 rounded border flex items-center justify-center shrink-0 ${
                isOn ? 'bg-green-600 border-green-600' : 'border-gray-300'
              }`}>
                {isOn && <span className="text-white text-xs">✓</span>}
              </div>
              {label}
            </button>
          )
        })}
      </div>

      <p className="text-xs text-gray-400">{selected.size} facilities selected</p>

      <div className="flex gap-3 pt-2">
        <button
          onClick={handleNext}
          disabled={saving}
          className="px-4 py-2 bg-green-700 hover:bg-green-800 disabled:bg-green-400 text-white text-sm rounded-lg font-medium"
        >
          {saving ? 'Saving...' : selected.size === 0 ? 'Skip: Contacts →' : 'Next: Contacts →'}
        </button>
        <button onClick={onSkip} disabled={saving} className="px-4 py-2 border border-gray-300 text-sm rounded-lg hover:bg-gray-50">
          Skip
        </button>
      </div>
    </div>
  )
}
