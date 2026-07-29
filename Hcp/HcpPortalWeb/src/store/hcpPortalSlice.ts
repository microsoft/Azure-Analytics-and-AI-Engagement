import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import { apiRoutes, hcpApi } from '../services/apiClient';

const sanitizeTechnicalMessage = (value?: string | null): string | null => {
  if (!value) {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  // Hide transport-level and backend status leakage from end users.
  if (/^request failed with status code\s+\d+$/i.test(trimmed)) {
    return null;
  }

  if (/status\s*=\s*\d+/i.test(trimmed) || /invalid[_\s-]?token/i.test(trimmed)) {
    return null;
  }

  return trimmed;
};

const getApiErrorMessage = (error: unknown, fallback: string): string => {
  const maybeError = error as {
    response?: {
      data?: {
        detail?: string;
        title?: string;
      };
    };
    message?: string;
  };

  const detail = sanitizeTechnicalMessage(maybeError.response?.data?.detail);
  const title = sanitizeTechnicalMessage(maybeError.response?.data?.title);
  const message = sanitizeTechnicalMessage(maybeError.message);

  return detail ?? title ?? message ?? fallback;
};

export interface PhysicianEnrollment {
  id: string;
  npi: string;
  firstName: string;
  lastName: string;
  email: string;
  specialty: string;
  organizationName: string;
  status: string | number;
  createdUtc: string;
  updatedUtc: string;
}

export interface ClinicianAnswerResponse {
  conversationId: string;
  groundedAnswer: string;
  sourceDocuments: Array<{ title: string; contentText: string }>;
  agentMemories: Array<{ summary: string }>;
  recentMessages: Array<{ role: string; content: string; createdUtc?: string }>;
}

export interface SandboxSession {
  sessionId: string;
  prescriberNpi: string;
  sandboxId: string;
  sandboxGroupName: string;
  managementEndpoint: string;
  status: string;
  createdAt: string;
  endedAt?: string | null;
}

interface HcpPortalState {
  recentEnrollments: PhysicianEnrollment[];
  lastCreatedEnrollment: PhysicianEnrollment | null;
  assistantResponse: ClinicianAnswerResponse | null;
  activeSandboxSessions: SandboxSession[];
  latestSandboxSession: SandboxSession | null;
  loading: {
    enrollments: boolean;
    assistant: boolean;
    sandbox: boolean;
  };
  error: {
    enrollments: string | null;
    assistant: string | null;
    sandbox: string | null;
  };
}

export const fetchRecentEnrollments = createAsyncThunk<
  PhysicianEnrollment[],
  number | undefined,
  { rejectValue: string }
>('hcpPortal/fetchRecentEnrollments', async (limit = 10, { rejectWithValue }) => {
  try {
    const res = await hcpApi.get<PhysicianEnrollment[]>(apiRoutes.hcp.physicianEnrollments, {
      params: { limit },
    });
    return res.data;
  } catch (error) {
    return rejectWithValue(getApiErrorMessage(error, 'Unable to fetch recent enrollments.'));
  }
});

export const createPhysicianEnrollment = createAsyncThunk<
  PhysicianEnrollment,
  Omit<PhysicianEnrollment, 'id' | 'status' | 'createdUtc' | 'updatedUtc'>,
  { rejectValue: string }
>('hcpPortal/createPhysicianEnrollment', async (payload, { rejectWithValue }) => {
  try {
    const res = await hcpApi.post<PhysicianEnrollment>(apiRoutes.hcp.physicianEnrollments, payload);
    return res.data;
  } catch (error) {
    return rejectWithValue(getApiErrorMessage(error, 'Unable to create physician enrollment.'));
  }
});

export const queryClinicianAssistant = createAsyncThunk<
  ClinicianAnswerResponse,
  { tenantId: string; prescriberNpi: string; question: string; conversationId?: string },
  { rejectValue: string }
>('hcpPortal/queryClinicianAssistant', async (payload, { rejectWithValue }) => {
  try {
    const res = await hcpApi.post<ClinicianAnswerResponse>(apiRoutes.hcp.clinicianAssistantQuery, payload);
    return res.data;
  } catch (error) {
    return rejectWithValue(getApiErrorMessage(error, 'Unable to get assistant response.'));
  }
});

export const listSandboxSessions = createAsyncThunk<SandboxSession[], void, { rejectValue: string }>(
  'hcpPortal/listSandboxSessions',
  async (_, { rejectWithValue }) => {
    try {
      const res = await hcpApi.get<SandboxSession[]>(apiRoutes.hcp.sandboxSessions);
      return res.data;
    } catch (error) {
      return rejectWithValue(getApiErrorMessage(error, 'Unable to load sandbox sessions.'));
    }
  }
);

export const createSandboxSession = createAsyncThunk<SandboxSession, { prescriberNpi: string }, { rejectValue: string }>(
  'hcpPortal/createSandboxSession',
  async (payload, { rejectWithValue }) => {
    try {
      const res = await hcpApi.post<SandboxSession>(apiRoutes.hcp.sandboxSessions, payload);
      return res.data;
    } catch (error) {
      return rejectWithValue(getApiErrorMessage(error, 'Unable to create sandbox session.'));
    }
  }
);

export const endSandboxSession = createAsyncThunk<string, string, { rejectValue: string }>(
  'hcpPortal/endSandboxSession',
  async (sessionId, { rejectWithValue }) => {
    try {
      await hcpApi.delete(`${apiRoutes.hcp.sandboxSessions}/${sessionId}`);
      return sessionId;
    } catch (error) {
      return rejectWithValue(getApiErrorMessage(error, 'Unable to end sandbox session.'));
    }
  }
);

const initialState: HcpPortalState = {
  recentEnrollments: [],
  lastCreatedEnrollment: null,
  assistantResponse: null,
  activeSandboxSessions: [],
  latestSandboxSession: null,
  loading: {
    enrollments: false,
    assistant: false,
    sandbox: false,
  },
  error: {
    enrollments: null,
    assistant: null,
    sandbox: null,
  },
};

const hcpPortalSlice = createSlice({
  name: 'hcpPortal',
  initialState,
  reducers: {},
  extraReducers: builder => {
    builder
      .addCase(fetchRecentEnrollments.pending, state => {
        state.loading.enrollments = true;
        state.error.enrollments = null;
      })
      .addCase(fetchRecentEnrollments.fulfilled, (state, action) => {
        state.loading.enrollments = false;
        state.recentEnrollments = action.payload;
      })
      .addCase(fetchRecentEnrollments.rejected, (state, action) => {
        state.loading.enrollments = false;
        state.error.enrollments = action.payload ?? 'Unable to fetch recent enrollments.';
      })
      .addCase(createPhysicianEnrollment.pending, state => {
        state.loading.enrollments = true;
        state.error.enrollments = null;
      })
      .addCase(createPhysicianEnrollment.fulfilled, (state, action) => {
        state.loading.enrollments = false;
        state.lastCreatedEnrollment = action.payload;
        state.recentEnrollments = [action.payload, ...state.recentEnrollments].slice(0, 25);
      })
      .addCase(createPhysicianEnrollment.rejected, (state, action) => {
        state.loading.enrollments = false;
        state.error.enrollments = action.payload ?? 'Unable to create physician enrollment.';
      })
      .addCase(queryClinicianAssistant.pending, state => {
        state.loading.assistant = true;
        state.error.assistant = null;
      })
      .addCase(queryClinicianAssistant.fulfilled, (state, action) => {
        state.loading.assistant = false;
        state.assistantResponse = action.payload;
      })
      .addCase(queryClinicianAssistant.rejected, (state, action) => {
        state.loading.assistant = false;
        state.error.assistant = action.payload ?? 'Unable to get assistant response.';
      })
      .addCase(listSandboxSessions.pending, state => {
        state.loading.sandbox = true;
        state.error.sandbox = null;
      })
      .addCase(listSandboxSessions.fulfilled, (state, action) => {
        state.loading.sandbox = false;
        state.activeSandboxSessions = action.payload;
      })
      .addCase(listSandboxSessions.rejected, (state, action) => {
        state.loading.sandbox = false;
        state.error.sandbox = action.payload ?? 'Unable to load sandbox sessions.';
      })
      .addCase(createSandboxSession.pending, state => {
        state.loading.sandbox = true;
        state.error.sandbox = null;
      })
      .addCase(createSandboxSession.fulfilled, (state, action) => {
        state.loading.sandbox = false;
        state.latestSandboxSession = action.payload;
        state.activeSandboxSessions = [action.payload, ...state.activeSandboxSessions].filter(
          (session, index, arr) => arr.findIndex(s => s.sessionId === session.sessionId) === index
        );
      })
      .addCase(createSandboxSession.rejected, (state, action) => {
        state.loading.sandbox = false;
        state.error.sandbox = action.payload ?? 'Unable to create sandbox session.';
      })
      .addCase(endSandboxSession.fulfilled, (state, action) => {
        state.activeSandboxSessions = state.activeSandboxSessions.filter(s => s.sessionId !== action.payload);
        if (state.latestSandboxSession?.sessionId === action.payload) {
          state.latestSandboxSession = null;
        }
      })
      .addCase(endSandboxSession.rejected, (state, action) => {
        state.error.sandbox = action.payload ?? 'Unable to end sandbox session.';
      });
  },
});

export default hcpPortalSlice.reducer;
