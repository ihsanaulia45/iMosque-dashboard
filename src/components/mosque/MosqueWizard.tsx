import { useState } from 'react'
import { StepBasicInfo } from './StepBasicInfo'
import { StepFacilities } from './StepFacilities'
import { StepContacts } from './StepContacts'

interface Props {
  onClose: () => void
  onComplete: () => void
}

const STEPS = ['Basic Info', 'Facilities', 'Contacts']

export function MosqueWizard({ onClose, onComplete }: Props) {
  const [step, setStep] = useState(1)
  const [mosqueId, setMosqueId] = useState<string | null>(null)
  const [mosqueName, setMosqueName] = useState('')

  const handleStep1Done = (id: string, name: string) => {
    setMosqueId(id)
    setMosqueName(name)
    setStep(2)
  }

  const handleStep2Done = () => {
    setStep(3)
  }

  const handleStep3Done = () => {
    onComplete()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30" onClick={onClose}>
      <div
        className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 pt-6 pb-4 border-b border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-800">Add Mosque</h2>
            <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
          </div>

          {/* Step Indicator */}
          <div className="flex items-center gap-2">
            {STEPS.map((label, i) => {
              const stepNum = i + 1
              const isActive = step === stepNum
              const isDone = step > stepNum
              return (
                <div key={label} className="flex items-center gap-2 flex-1">
                  <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${
                    isDone ? 'bg-green-600 text-white' :
                    isActive ? 'bg-green-700 text-white' :
                    'bg-gray-200 text-gray-500'
                  }`}>
                    {isDone ? '✓' : stepNum}
                  </div>
                  <span className={`text-xs whitespace-nowrap ${isActive ? 'font-medium text-gray-800' : 'text-gray-400'}`}>
                    {label}
                  </span>
                  {i < STEPS.length - 1 && (
                    <div className={`flex-1 h-px ${isDone ? 'bg-green-400' : 'bg-gray-200'}`} />
                  )}
                </div>
              )
            })}
          </div>

          {/* Show mosque name after step 1 */}
          {mosqueId && (
            <p className="mt-2 text-xs text-gray-500">
              Mosque: <span className="font-medium text-gray-700">{mosqueName}</span>
            </p>
          )}
        </div>

        {/* Step Content */}
        <div className="p-6">
          {step === 1 && (
            <StepBasicInfo onDone={handleStep1Done} onCancel={onClose} />
          )}
          {step === 2 && mosqueId && (
            <StepFacilities mosqueId={mosqueId} onDone={handleStep2Done} onSkip={handleStep2Done} />
          )}
          {step === 3 && mosqueId && (
            <StepContacts mosqueId={mosqueId} onDone={handleStep3Done} onSkip={handleStep3Done} />
          )}
        </div>
      </div>
    </div>
  )
}
