import axios from 'axios';

const trimTrailingSlash = (value: string) => value.replace(/\/+$/, '');

const resolveBaseUrl = (specific?: string, fallback?: string) => {
  if (specific && specific.trim().length > 0) {
    return trimTrailingSlash(specific);
  }

  if (fallback && fallback.trim().length > 0) {
    return trimTrailingSlash(fallback);
  }

  // Default to Vite dev proxy (/api -> backend target) and relative path in production.
  return '/api';
};

const sharedBase = resolveBaseUrl(import.meta.env.VITE_API_BASE_URL);

export const pharmaApi = axios.create({
  baseURL: resolveBaseUrl(import.meta.env.VITE_PHARMA_API_BASE_URL, sharedBase),
});

export const hcpApi = axios.create({
  baseURL: resolveBaseUrl(import.meta.env.VITE_HCP_API_BASE_URL, sharedBase),
});

export const apiRoutes = {
  pharma: {
    medications: '/medications',
  },
  hcp: {
    physicianEnrollments: '/PhysicianEnrollments',
    clinicianAssistantQuery: '/ClinicianAssistant/query',
    sandboxSessions: '/SandboxSessions',
  },
} as const;
