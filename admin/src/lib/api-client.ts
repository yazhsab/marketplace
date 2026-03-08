import axios, { AxiosRequestConfig } from 'axios';
import type { ApiResponse } from '@/types';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

apiClient.interceptors.request.use(
  (config) => {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('admin_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export async function apiGet<T>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
  const response = await apiClient.get<ApiResponse<T>>(url, config);
  return response.data;
}

export async function apiPost<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
  const response = await apiClient.post<ApiResponse<T>>(url, data, config);
  return response.data;
}

export async function apiPut<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
  const response = await apiClient.put<ApiResponse<T>>(url, data, config);
  return response.data;
}

export async function apiDelete<T>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
  const response = await apiClient.delete<ApiResponse<T>>(url, config);
  return response.data;
}

export default apiClient;
