import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import type { AppDispatch, RootState } from '../store/store';
import {
  createSandboxSession,
  endSandboxSession,
  fetchRecentEnrollments,
  listSandboxSessions,
  queryClinicianAssistant,
} from '../store/hcpPortalSlice';
import AssistantPanel from '../components/prescriberPortal/AssistantPanel';
import type { ChatMessage } from '../components/prescriberPortal/AssistantPanel';
import LeftQueuePanel from '../components/prescriberPortal/LeftQueuePanel';
import MiddleWorkflowPanel from '../components/prescriberPortal/MiddleWorkflowPanel';
import {
  ENROLLMENT_JOURNEY,
  INITIAL_ENROLLMENT_FORM,
  PRESCRIBER_QUEUE,
  QUICK_PROMPTS,
  STARTER_PROMPTS,
  type EnrollmentForm,
  type QueueItem,
} from '../components/prescriberPortal/constants';

const DEFAULT_TENANT_ID = (import.meta.env.VITE_HCP_TENANT_ID as string | undefined)?.trim() || 'caldova-hcp';
const ASSISTANT_WELCOME_MESSAGE =
  'Hi, I am your clinician assistant. I can help with drug interactions, dosing guidance, and formulary status for the selected prescriber.';

const getEnrollmentStatusLabel = (status: string | number) => {
  if (status === 1 || status === 'Approved') {
    return 'Approved';
  }

  if (status === 2 || status === 'Rejected') {
    return 'Rejected';
  }

  return 'Pending';
};

const getEnrollmentPriority = (status: string | number): QueueItem['priority'] => {
  if (status === 0 || status === 'Pending') {
    return 'high';
  }

  if (status === 1 || status === 'Approved') {
    return 'low';
  }

  return 'medium';
};

interface ToastNotification {
  id: string;
  message: string;
}

const mockEnrollmentProfiles: Record<string, Pick<EnrollmentForm, 'email' | 'specialty' | 'organizationName'>> = {
  '1234567890': {
    email: 'amanda.wilson@northvalemed.org',
    specialty: 'Cardiology',
    organizationName: 'Northvale Medical Group',
  },
  '2234567890': {
    email: 'joe.williamson@sunrisecare.org',
    specialty: 'Family Medicine',
    organizationName: 'Sunrise Care Partners',
  },
  '3234567890': {
    email: 'john.doe@ridgeviewhealth.com',
    specialty: 'Internal Medicine',
    organizationName: 'Ridgeview Health System',
  },
  '4234567890': {
    email: 'sarah.ali@greenfieldclinic.net',
    specialty: 'Endocrinology',
    organizationName: 'Greenfield Specialty Clinic',
  },
};

const toEnrollmentFormFromQueueItem = (item: QueueItem): EnrollmentForm => {
  const [firstName, ...lastNameParts] = item.name.trim().split(/\s+/);
  const lastName = lastNameParts.join(' ');
  const profile = item.npi ? mockEnrollmentProfiles[item.npi] : undefined;

  return {
    npi: item.npi ?? '',
    firstName: firstName ?? '',
    lastName: lastName ?? '',
    email: profile?.email ?? `${(firstName ?? 'prescriber').toLowerCase()}@caldovahealth.org`,
    specialty: profile?.specialty ?? 'General Practice',
    organizationName: profile?.organizationName ?? 'Caldova Provider Network',
  };
};

const PrescriberPortal: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();

  const {
    recentEnrollments,
    lastCreatedEnrollment,
    assistantResponse,
    activeSandboxSessions,
    latestSandboxSession,
    loading,
    error,
  } = useSelector((state: RootState) => state.hcpPortal);

  const [assistantQuestion, setAssistantQuestion] = useState('');
  const [enrollmentForm, setEnrollmentForm] = useState(INITIAL_ENROLLMENT_FORM);
  const [mockEnrollmentSaving, setMockEnrollmentSaving] = useState(false);
  const [activeQueueId, setActiveQueueId] = useState('');
  const [toast, setToast] = useState<ToastNotification | null>(null);
  const toastTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastErrorRef = useRef<{ enrollments: string | null; assistant: string | null; sandbox: string | null }>({
    enrollments: null,
    assistant: null,
    sandbox: null,
  });
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      id: 'assistant-welcome',
      role: 'assistant',
      content: ASSISTANT_WELCOME_MESSAGE,
    },
  ]);

  useEffect(() => {
    void dispatch(fetchRecentEnrollments(10));
    void dispatch(listSandboxSessions());
  }, [dispatch]);

  const queue = useMemo<QueueItem[]>(() => {
    if (recentEnrollments.length === 0) {
      return PRESCRIBER_QUEUE;
    }

    return recentEnrollments.map(enrollment => ({
      id: enrollment.id,
      name: `${enrollment.firstName} ${enrollment.lastName}`,
      npi: enrollment.npi,
      status: getEnrollmentStatusLabel(enrollment.status),
      priority: getEnrollmentPriority(enrollment.status),
    }));
  }, [recentEnrollments]);

  useEffect(() => {
    if (activeQueueId && !queue.some(item => item.id === activeQueueId)) {
      setActiveQueueId('');
    }
  }, [activeQueueId, queue]);

  useEffect(() => {
    const hasWelcomeMessage = chatMessages.some(message => message.id === 'assistant-welcome');
    if (hasWelcomeMessage) {
      return;
    }

    setChatMessages(prev => [
      {
        id: 'assistant-welcome',
        role: 'assistant',
        content: ASSISTANT_WELCOME_MESSAGE,
      },
      ...prev,
    ]);
  }, [chatMessages]);

  const activeQueueItem = useMemo(() => queue.find(item => item.id === activeQueueId) ?? null, [activeQueueId, queue]);

  useEffect(() => {
    if (!activeQueueItem) {
      setEnrollmentForm(INITIAL_ENROLLMENT_FORM);
      return;
    }

    setEnrollmentForm(toEnrollmentFormFromQueueItem(activeQueueItem));
  }, [activeQueueItem]);

  const activeQueueNpi = activeQueueItem?.npi ?? '';

  const effectiveNpi = useMemo(
    () => lastCreatedEnrollment?.npi ?? activeQueueNpi ?? enrollmentForm.npi,
    [activeQueueNpi, lastCreatedEnrollment?.npi, enrollmentForm.npi]
  );

  const enrollmentErrorForUi = useMemo(() => {
    const message = error.enrollments;
    if (!message) {
      return null;
    }

    if (message.toLowerCase().includes('unable to fetch recent enrollments')) {
      return null;
    }

    return message;
  }, [error.enrollments]);

  const pushToast = useCallback((message: string) => {
    const id = `toast-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    setToast({ id, message });

    if (toastTimerRef.current) {
      clearTimeout(toastTimerRef.current);
    }

    toastTimerRef.current = setTimeout(() => {
      setToast(current => (current?.id === id ? null : current));
      toastTimerRef.current = null;
    }, 5000);
  }, []);

  const dismissToast = useCallback((id: string) => {
    setToast(current => (current?.id === id ? null : current));
  }, []);

  useEffect(() => {
    return () => {
      if (toastTimerRef.current) {
        clearTimeout(toastTimerRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (error.enrollments !== lastErrorRef.current.enrollments) {
      if (error.enrollments && error.enrollments.toLowerCase().includes('unable to fetch recent enrollments')) {
        pushToast('Recent enrollments are temporarily unavailable. Please refresh and try again.');
      }

      lastErrorRef.current.enrollments = error.enrollments;
    }
  }, [error.enrollments, pushToast]);

  useEffect(() => {
    if (error.assistant !== lastErrorRef.current.assistant) {
      if (error.assistant) {
        pushToast('Clinical Assistant is temporarily unavailable. Please try again.');
      }

      lastErrorRef.current.assistant = error.assistant;
    }
  }, [error.assistant, pushToast]);

  useEffect(() => {
    if (error.sandbox !== lastErrorRef.current.sandbox) {
      if (error.sandbox) {
        pushToast('Isolated session preview is currently unavailable.');
      }

      lastErrorRef.current.sandbox = error.sandbox;
    }
  }, [error.sandbox, pushToast]);

  const currentSandboxSession = useMemo(
    () => activeSandboxSessions.find(session => session.prescriberNpi === effectiveNpi) ?? latestSandboxSession,
    [activeSandboxSessions, effectiveNpi, latestSandboxSession]
  );

  const ensureSandboxSession = async () => {
    if (!effectiveNpi.trim()) {
      return null;
    }

    if (currentSandboxSession && !currentSandboxSession.endedAt) {
      return currentSandboxSession;
    }

    const action = await dispatch(createSandboxSession({ prescriberNpi: effectiveNpi }));
    if (createSandboxSession.fulfilled.match(action)) {
      return action.payload;
    }

    return null;
  };

  const handleAssistantQuery = async (question: string) => {
    const trimmed = question.trim();
    if (!trimmed) {
      return;
    }

    const userMessage: ChatMessage = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: trimmed,
    };
    setChatMessages(prev => [...prev, userMessage]);
    setAssistantQuestion('');

    await ensureSandboxSession();

    const action = await dispatch(
      queryClinicianAssistant({
        tenantId: DEFAULT_TENANT_ID,
        prescriberNpi: effectiveNpi,
        question: trimmed,
        conversationId: assistantResponse?.conversationId,
      })
    );

    if (queryClinicianAssistant.fulfilled.match(action)) {
      setChatMessages(prev => [
        ...prev,
        {
          id: `assistant-${Date.now()}`,
          role: 'assistant',
          content: action.payload.groundedAnswer,
        },
      ]);
      return;
    }

    setChatMessages(prev => [
      ...prev,
      {
        id: `assistant-error-${Date.now()}`,
        role: 'assistant',
        content: 'I could not process that request right now. Please try again.',
      },
    ]);
  };

  const handleCreateEnrollment = async () => {
    if (mockEnrollmentSaving) {
      return;
    }

    setMockEnrollmentSaving(true);
    await new Promise(resolve => setTimeout(resolve, 700));
    setMockEnrollmentSaving(false);

    const fallbackName = `${enrollmentForm.firstName} ${enrollmentForm.lastName}`.trim();
    const displayName = (activeQueueItem?.name ?? fallbackName) || 'Prescriber';
    pushToast(`${displayName} enrollment updated successfully.`);
  };

  const handleStartSandboxSession = async () => {
    await ensureSandboxSession();
  };

  const handleEndSandboxSession = async () => {
    if (!currentSandboxSession) {
      return;
    }

    await dispatch(endSandboxSession(currentSandboxSession.sessionId));
  };

  const handleQuickPrompt = (type: string) => {
    const mappedPrompt =
      type === 'Drug Interactions'
        ? 'What drug interaction risks should the clinician review for this therapy?'
        : type === 'Dosing Guidance'
          ? 'What dosing guidance or cautions are relevant for this therapy?'
          : 'What formulary status details are available for this therapy?';

    setAssistantQuestion(mappedPrompt);
    void handleAssistantQuery(mappedPrompt);
  };

  return (
    <div className="h-[100dvh] overflow-hidden bg-slate-50 text-slate-900">
      {toast ? (
        <div className="pointer-events-none fixed right-4 top-4 z-50 flex w-[min(360px,calc(100vw-2rem))] flex-col gap-2">
          <div
            key={toast.id}
            className="pointer-events-auto flex items-start justify-between gap-3 rounded-xl border border-amber-200 bg-white px-3 py-2 shadow-lg"
          >
            <p className="text-xs text-slate-700">{toast.message}</p>
            <button
              className="shrink-0 rounded-full px-2 py-0.5 text-xs text-slate-500 transition hover:bg-slate-100 hover:text-slate-700"
              onClick={() => dismissToast(toast.id)}
              aria-label="Dismiss notification"
            >
              x
            </button>
          </div>
        </div>
      ) : null}

      <div className="mx-auto h-full min-h-0 max-w-[1500px] px-2 lg:px-3">
        <section className="grid h-full min-h-0 grid-cols-1 items-start gap-1.5 py-2 lg:grid-cols-12 lg:grid-rows-[minmax(0,1fr)] lg:items-stretch">
          <LeftQueuePanel queue={queue} activeQueueId={activeQueueId} onSelectQueue={setActiveQueueId} />
          <MiddleWorkflowPanel
            activeQueueItem={activeQueueItem}
            enrollmentJourney={ENROLLMENT_JOURNEY}
            enrollmentForm={enrollmentForm}
            setEnrollmentForm={setEnrollmentForm}
            onCreateEnrollment={handleCreateEnrollment}
            enrollmentLoading={mockEnrollmentSaving}
            enrollmentError={enrollmentErrorForUi}
            enrollmentActionLabel="Update Enrollment"
            enrollmentLoadingLabel="Updating..."
          />
          <AssistantPanel
            assistantResponse={assistantResponse}
            assistantError={error.assistant}
            assistantLoading={loading.assistant}
            starterPrompts={STARTER_PROMPTS}
            quickPrompts={QUICK_PROMPTS}
            chatMessages={chatMessages}
            assistantQuestion={assistantQuestion}
            setAssistantQuestion={setAssistantQuestion}
            currentSandboxSession={currentSandboxSession}
            sandboxLoading={loading.sandbox}
            sandboxError={error.sandbox}
            activeSandboxCount={activeSandboxSessions.length}
            onStartSandboxSession={handleStartSandboxSession}
            onEndSandboxSession={handleEndSandboxSession}
            onSend={handleAssistantQuery}
            onQuickPrompt={handleQuickPrompt}
          />
        </section>
      </div>
    </div>
  );
};

export default PrescriberPortal;
