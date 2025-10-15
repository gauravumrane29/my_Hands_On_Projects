export interface User {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateUserRequest {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  isActive?: boolean;
}

export interface UpdateUserRequest extends CreateUserRequest {
  id: number;
}

export interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

export interface AppInfo {
  application: string;
  version: string;
  timestamp: string;
  status: string;
  totalUsers: number;
}