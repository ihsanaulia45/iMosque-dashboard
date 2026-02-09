import { Routes, Route } from 'react-router-dom'
import { AuthGuard } from './auth-guard'
import { AdminLayout } from '../components/layout/AdminLayout'
import Login from '../pages/Login'
import Dashboard from '../pages/Dashboard'
import Users from '../pages/Users'
import Mosques from '../pages/Mosques'
import Logs from '../pages/Logs'
import Settings from '../pages/Settings'
import Profile from '../pages/Profile'

export function AppRouter() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<AuthGuard />}>
        <Route element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          <Route path="mosques" element={<Mosques />} />
          <Route path="logs" element={<Logs />} />
          <Route path="settings" element={<Settings />} />
          <Route path="profile" element={<Profile />} />
        </Route>
      </Route>
    </Routes>
  )
}
