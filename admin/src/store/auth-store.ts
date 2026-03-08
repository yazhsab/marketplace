import { create } from 'zustand';
import { apiPost } from '@/lib/api-client';
import type { User } from '@/types';

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  hydrate: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  user: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,

  login: async (email: string, password: string) => {
    set({ isLoading: true, error: null });
    try {
      const response = await apiPost<{ token: string; user: User }>('/auth/login', {
        email,
        password,
      });
      const { token, user } = response.data;

      if (user.role !== 'admin') {
        set({ isLoading: false, error: 'Access denied. Admin privileges required.' });
        return;
      }

      localStorage.setItem('admin_token', token);
      localStorage.setItem('admin_user', JSON.stringify(user));

      set({
        token,
        user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
    } catch (err: unknown) {
      const message =
        err instanceof Error
          ? err.message
          : (err as { response?: { data?: { message?: string } } })?.response?.data?.message ||
            'Login failed. Please check your credentials.';
      set({ isLoading: false, error: message });
      throw new Error(message);
    }
  },

  logout: () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    set({
      token: null,
      user: null,
      isAuthenticated: false,
      error: null,
    });
    window.location.href = '/login';
  },

  hydrate: () => {
    if (typeof window === 'undefined') return;

    const token = localStorage.getItem('admin_token');
    const userStr = localStorage.getItem('admin_user');

    if (token && userStr) {
      try {
        const user = JSON.parse(userStr) as User;
        set({ token, user, isAuthenticated: true });
      } catch {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
      }
    }
  },
}));
