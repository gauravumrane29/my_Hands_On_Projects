import axios from 'axios';
import { User, CreateUserRequest, UpdateUserRequest, AppInfo } from '../types/api';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export const userApi = {
  // Get all users
  getAllUsers: async (): Promise<User[]> => {
    const response = await apiClient.get<User[]>('/api/users');
    return response.data;
  },

  // Get active users
  getActiveUsers: async (): Promise<User[]> => {
    const response = await apiClient.get<User[]>('/api/users/active');
    return response.data;
  },

  // Get user by ID
  getUserById: async (id: number): Promise<User> => {
    const response = await apiClient.get<User>(`/api/users/${id}`);
    return response.data;
  },

  // Get user by username
  getUserByUsername: async (username: string): Promise<User> => {
    const response = await apiClient.get<User>(`/api/users/username/${username}`);
    return response.data;
  },

  // Search users by name
  searchUsers: async (name: string): Promise<User[]> => {
    const response = await apiClient.get<User[]>(`/api/users/search`, {
      params: { name }
    });
    return response.data;
  },

  // Get active user count
  getActiveUserCount: async (): Promise<number> => {
    const response = await apiClient.get<number>('/api/users/count/active');
    return response.data;
  },

  // Create new user
  createUser: async (user: CreateUserRequest): Promise<User> => {
    const response = await apiClient.post<User>('/api/users', user);
    return response.data;
  },

  // Update user
  updateUser: async (id: number, user: UpdateUserRequest): Promise<User> => {
    const response = await apiClient.put<User>(`/api/users/${id}`, user);
    return response.data;
  },

  // Delete user
  deleteUser: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/users/${id}`);
  },

  // Deactivate user
  deactivateUser: async (id: number): Promise<void> => {
    await apiClient.put(`/api/users/${id}/deactivate`);
  },
};

export const appApi = {
  // Get application info
  getAppInfo: async (): Promise<AppInfo> => {
    const response = await apiClient.get<AppInfo>('/api/v1/info');
    return response.data;
  },

  // Health check
  healthCheck: async (): Promise<{ status: string; service: string; timestamp: string }> => {
    const response = await apiClient.get('/api/v1/health');
    return response.data;
  },
};

export default apiClient;