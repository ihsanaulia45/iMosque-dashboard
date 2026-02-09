import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../app/supabase'
import { useAuthStore } from '../stores/auth.store'

interface MosqueSummary {
  id: string
  name: string
  address: string | null
  is_verified: boolean
  created_at: string
}

interface RecentUser {
  id: string
  full_name: string | null
  role: string
  created_at: string
}

export default function Dashboard() {
  const { profile } = useAuthStore()
  const [stats, setStats] = useState({ users: 0, mosques: 0, unverified: 0, verified: 0 })
  const [pendingMosques, setPendingMosques] = useState<MosqueSummary[]>([])
  const [recentUsers, setRecentUsers] = useState<RecentUser[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const [users, mosques, unverified, verified, pending, recent] = await Promise.all([
        supabase.from('profiles').select('id', { count: 'exact', head: true }),
        supabase.from('mosques').select('id', { count: 'exact', head: true }),
        supabase.from('mosques').select('id', { count: 'exact', head: true }).eq('is_verified', false),
        supabase.from('mosques').select('id', { count: 'exact', head: true }).eq('is_verified', true),
        supabase.from('mosques').select('id, name, address, is_verified, created_at').eq('is_verified', false).order('created_at', { ascending: false }).limit(5),
        supabase.from('profiles').select('id, full_name, role, created_at').order('created_at', { ascending: false }).limit(5),
      ])

      setStats({
        users: users.count ?? 0,
        mosques: mosques.count ?? 0,
        unverified: unverified.count ?? 0,
        verified: verified.count ?? 0,
      })
      setPendingMosques((pending.data ?? []) as MosqueSummary[])
      setRecentUsers((recent.data ?? []) as RecentUser[])
      setLoading(false)
    }
    load()
  }, [])

  const cards = [
    { label: 'Total Users', value: stats.users, color: 'bg-blue-50 text-blue-700', link: '/users' },
    { label: 'Total Mosques', value: stats.mosques, color: 'bg-green-50 text-green-700', link: '/mosques' },
    { label: 'Pending Verification', value: stats.unverified, color: 'bg-amber-50 text-amber-700', link: '/mosques' },
    { label: 'Verified Mosques', value: stats.verified, color: 'bg-emerald-50 text-emerald-700', link: '/mosques' },
  ]

  if (loading) {
    return <div className="text-gray-400 p-4">Loading dashboard...</div>
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-800 mb-1">
        Welcome back, {profile?.full_name || 'Admin'}
      </h1>
      <p className="text-gray-500 mb-6">Here's what's happening with your mosques today.</p>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {cards.map((card) => (
          <Link key={card.label} to={card.link} className={`rounded-xl p-5 ${card.color} hover:opacity-80 transition`}>
            <p className="text-3xl font-bold">{card.value}</p>
            <p className="text-sm mt-1 opacity-80">{card.label}</p>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-800">Pending Verification</h2>
            <Link to="/mosques" className="text-sm text-green-700 hover:underline">View all</Link>
          </div>
          {pendingMosques.length === 0 ? (
            <p className="text-gray-400 text-sm">No pending mosques.</p>
          ) : (
            <div className="space-y-3">
              {pendingMosques.map((m) => (
                <div key={m.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-800">{m.name}</p>
                    <p className="text-xs text-gray-500">{m.address || 'No address'}</p>
                  </div>
                  <span className="text-xs text-gray-400">{new Date(m.created_at).toLocaleDateString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-800">Recent Users</h2>
            <Link to="/users" className="text-sm text-green-700 hover:underline">View all</Link>
          </div>
          {recentUsers.length === 0 ? (
            <p className="text-gray-400 text-sm">No users found.</p>
          ) : (
            <div className="space-y-3">
              {recentUsers.map((u) => (
                <div key={u.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-800">{u.full_name || 'Unnamed'}</p>
                    <p className="text-xs text-gray-500 capitalize">{u.role}</p>
                  </div>
                  <span className="text-xs text-gray-400">{new Date(u.created_at).toLocaleDateString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
