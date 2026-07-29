import React, { useEffect, useRef } from 'react';
import { Bot, Loader2, Send } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { ClinicianAnswerResponse, SandboxSession } from '../../store/hcpPortalSlice';

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
}

interface AssistantPanelProps {
  assistantResponse: ClinicianAnswerResponse | null;
  assistantError: string | null;
  assistantLoading: boolean;
  currentSandboxSession: SandboxSession | null;
  sandboxLoading: boolean;
  sandboxError: string | null;
  activeSandboxCount: number;
  starterPrompts: string[];
  quickPrompts: string[];
  chatMessages: ChatMessage[];
  assistantQuestion: string;
  setAssistantQuestion: React.Dispatch<React.SetStateAction<string>>;
  onStartSandboxSession: () => void;
  onEndSandboxSession: () => void;
  onSend: (question: string) => void;
  onQuickPrompt: (type: string) => void;
}

const AssistantPanel: React.FC<AssistantPanelProps> = ({
  assistantResponse,
  assistantError,
  assistantLoading,
  currentSandboxSession,
  sandboxLoading,
  sandboxError,
  activeSandboxCount,
  starterPrompts,
  quickPrompts,
  chatMessages,
  assistantQuestion,
  setAssistantQuestion,
  onStartSandboxSession,
  onEndSandboxSession,
  onSend,
  onQuickPrompt,
}) => {
  const messagesEndRef = useRef<HTMLDivElement | null>(null);

  const sandboxPreviewUnavailable = Boolean(sandboxError);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [chatMessages, assistantLoading]);

  return (
    <aside className="min-h-0 lg:col-span-4 lg:h-full">
      <div className="flex h-full min-h-0 max-h-full flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex w-full items-center border-b border-slate-200 bg-gradient-to-r from-sky-50 to-cyan-50 px-5 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-cyan-100 text-sm font-semibold text-cyan-800">
              <Bot className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-base font-semibold text-slate-900">Clinical Assistant</h3>
              <p className="text-xs text-slate-600">Drug interactions, dosing, and formulary Q&A</p>
            </div>
          </div>
        </div>

        <div className="border-b border-slate-200 bg-slate-50 px-4 py-2 text-slate-800">
          <div className="flex items-center justify-between gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
            <div className="min-w-0">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Isolated Session</p>
              <p className="truncate text-[12px] text-slate-700">
                {currentSandboxSession ? `Status: ${currentSandboxSession.status}` : 'Not active'}
                <span className="text-slate-400"> • {activeSandboxCount} active</span>
                {sandboxPreviewUnavailable ? <span className="text-amber-600"> • Preview unavailable</span> : null}
              </p>
            </div>

            {currentSandboxSession ? (
              <button
                className="shrink-0 cursor-pointer rounded-full border border-slate-300 px-2.5 py-1 text-[11px] font-medium text-slate-700 transition hover:bg-slate-50 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60"
                onClick={onEndSandboxSession}
                disabled={sandboxLoading || sandboxPreviewUnavailable}
              >
                {sandboxLoading ? 'Ending...' : 'End'}
              </button>
            ) : (
              <button
                className="shrink-0 cursor-pointer rounded-full border border-cyan-300 bg-cyan-50 px-2.5 py-1 text-[11px] font-medium text-cyan-800 transition hover:bg-cyan-100 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60"
                onClick={onStartSandboxSession}
                disabled={sandboxLoading || sandboxPreviewUnavailable}
              >
                {sandboxLoading ? 'Starting...' : 'Start'}
              </button>
            )}
          </div>
        </div>

        <div
          className="flex-1 min-h-0 overflow-y-auto overscroll-contain bg-slate-50 px-4 py-3 text-slate-800 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
        >
          <div className="space-y-3">
            {chatMessages.map(message => (
              <div key={message.id} className={message.role === 'user' ? 'flex justify-end' : 'flex justify-start'}>
                <div className="max-w-[92%] space-y-2">
                  <div
                    className={`rounded-2xl px-4 py-3 text-[13px] leading-relaxed ${
                      message.role === 'user'
                        ? 'border border-cyan-300 bg-cyan-100 text-cyan-900'
                        : 'border border-slate-200 bg-white text-slate-800'
                    }`}
                  >
                    <ReactMarkdown
                      remarkPlugins={[remarkGfm]}
                      components={{
                        p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
                        ul: ({ children }) => <ul className="mb-2 list-disc pl-5 last:mb-0">{children}</ul>,
                        ol: ({ children }) => <ol className="mb-2 list-decimal pl-5 last:mb-0">{children}</ol>,
                        li: ({ children }) => <li className="mb-1">{children}</li>,
                        strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
                      }}
                    >
                      {message.content}
                    </ReactMarkdown>
                  </div>

                  {message.id === 'assistant-welcome' ? (
                    <div className="flex flex-wrap gap-2 pl-1">
                      {quickPrompts.map(prompt => (
                        <button
                          key={`welcome-${prompt}`}
                          className="cursor-pointer rounded-full border border-cyan-200 bg-cyan-50 px-3 py-1 text-[11px] text-cyan-800 transition hover:border-cyan-300 hover:bg-cyan-100 active:scale-[0.99]"
                          onClick={() => onQuickPrompt(prompt)}
                        >
                          {prompt}
                        </button>
                      ))}
                    </div>
                  ) : null}
                </div>
              </div>
            ))}

            {assistantLoading ? (
              <div className="flex justify-start">
                <div className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-[13px] text-slate-500">
                  Assistant is thinking...
                </div>
              </div>
            ) : null}

            {chatMessages.length === 0 ? (
              <div className="rounded-xl border border-dashed border-slate-300 bg-white px-4 py-3 text-sm text-slate-600">
                {starterPrompts[0]}
              </div>
            ) : null}

            <div ref={messagesEndRef} />
          </div>
        </div>

        <div className="shrink-0 border-t border-slate-200 bg-white px-4 py-3">
          <div className="flex gap-2">
            <div className="flex flex-1 items-center rounded-full border border-slate-300 bg-white px-4 py-2">
              <input
                className="w-full bg-transparent text-[13px] text-slate-900 outline-none placeholder:text-slate-400"
                placeholder="Ask about drug interactions, dosing, or formulary status..."
                value={assistantQuestion}
                onChange={e => setAssistantQuestion(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    onSend(assistantQuestion);
                  }
                }}
              />
            </div>
            <button
              aria-label="Send message"
              className="inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-full border border-cyan-600 bg-cyan-600 text-white transition hover:bg-cyan-500 active:scale-[0.97] disabled:cursor-not-allowed disabled:opacity-60"
              onClick={() => onSend(assistantQuestion)}
              disabled={assistantLoading || !assistantQuestion.trim()}
            >
              {assistantLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
            </button>
          </div>
        </div>
      </div>
    </aside>
  );
};

export default AssistantPanel;
