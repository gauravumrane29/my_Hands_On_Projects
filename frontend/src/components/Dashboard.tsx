import React, { useState, useEffect } from 'react';
import { User, AppInfo } from '../types/api';
import { userApi, appApi } from '../services/api';
import UserList from './UserList';
import UserForm from './UserForm';
import './Dashboard.css';

const Dashboard: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [appInfo, setAppInfo] = useState<AppInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [showForm, setShowForm] = useState<boolean>(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [searchTerm, setSearchTerm] = useState<string>('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [usersData, appInfoData] = await Promise.all([
        userApi.getAllUsers(),
        appApi.getAppInfo()
      ]);
      setUsers(usersData);
      setAppInfo(appInfoData);
      setError('');
    } catch (err) {
      setError('Failed to load data. Please check if the backend is running.');
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = () => {
    setEditingUser(null);
    setShowForm(true);
  };

  const handleEditUser = (user: User) => {
    setEditingUser(user);
    setShowForm(true);
  };

  const handleDeleteUser = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await userApi.deleteUser(id);
        await loadData();
      } catch (err) {
        setError('Failed to delete user');
      }
    }
  };

  const handleDeactivateUser = async (id: number) => {
    if (window.confirm('Are you sure you want to deactivate this user?')) {
      try {
        await userApi.deactivateUser(id);
        await loadData();
      } catch (err) {
        setError('Failed to deactivate user');
      }
    }
  };

  const handleUserSaved = () => {
    setShowForm(false);
    setEditingUser(null);
    loadData();
  };

  const handleSearch = async () => {
    if (searchTerm.trim()) {
      try {
        const searchResults = await userApi.searchUsers(searchTerm);
        setUsers(searchResults);
      } catch (err) {
        setError('Search failed');
      }
    } else {
      loadData();
    }
  };

  const handleClearSearch = () => {
    setSearchTerm('');
    loadData();
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>User Management Dashboard</h1>
        {appInfo && (
          <div className="app-info">
            <span>📱 {appInfo.application} v{appInfo.version}</span>
            <span>👥 Total Users: {appInfo.totalUsers}</span>
            <span>🟢 Status: {appInfo.status}</span>
          </div>
        )}
      </header>

      {error && (
        <div className="error-banner">
          ⚠️ {error}
          <button onClick={loadData} className="retry-btn">Retry</button>
        </div>
      )}

      <div className="dashboard-controls">
        <div className="search-section">
          <input
            type="text"
            placeholder="Search users by name..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          />
          <button onClick={handleSearch} className="search-btn">🔍 Search</button>
          {searchTerm && (
            <button onClick={handleClearSearch} className="clear-btn">✖️ Clear</button>
          )}
        </div>
        <button onClick={handleCreateUser} className="create-btn">➕ Add New User</button>
      </div>

      <UserList
        users={users}
        onEdit={handleEditUser}
        onDelete={handleDeleteUser}
        onDeactivate={handleDeactivateUser}
      />

      {showForm && (
        <UserForm
          user={editingUser}
          onSave={handleUserSaved}
          onCancel={() => setShowForm(false)}
        />
      )}
    </div>
  );
};

export default Dashboard;