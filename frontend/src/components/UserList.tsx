import React from 'react';
import { User } from '../types/api';
import './UserList.css';

interface UserListProps {
  users: User[];
  onEdit: (user: User) => void;
  onDelete: (id: number) => void;
  onDeactivate: (id: number) => void;
}

const UserList: React.FC<UserListProps> = ({ users, onEdit, onDelete, onDeactivate }) => {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (users.length === 0) {
    return <div className="no-users">No users found</div>;
  }

  return (
    <div className="user-list">
      <table className="users-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Username</th>
            <th>Name</th>
            <th>Email</th>
            <th>Status</th>
            <th>Created</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id} className={user.isActive ? 'active' : 'inactive'}>
              <td>{user.id}</td>
              <td>{user.username}</td>
              <td>{user.firstName} {user.lastName}</td>
              <td>{user.email}</td>
              <td>
                <span className={`status ${user.isActive ? 'active' : 'inactive'}`}>
                  {user.isActive ? '🟢 Active' : '🔴 Inactive'}
                </span>
              </td>
              <td>{formatDate(user.createdAt)}</td>
              <td className="actions">
                <button 
                  onClick={() => onEdit(user)}
                  className="edit-btn"
                  title="Edit user"
                >
                  ✏️
                </button>
                {user.isActive && (
                  <button
                    onClick={() => onDeactivate(user.id)}
                    className="deactivate-btn"
                    title="Deactivate user"
                  >
                    🚫
                  </button>
                )}
                <button
                  onClick={() => onDelete(user.id)}
                  className="delete-btn"
                  title="Delete user"
                >
                  🗑️
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default UserList;