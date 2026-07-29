import React from 'react';
import { ClipboardList } from 'lucide-react';
import type { QueueItem } from './constants';

interface LeftQueuePanelProps {
  queue: QueueItem[];
  activeQueueId: string;
  onSelectQueue: (id: string) => void;
}

const LeftQueuePanel: React.FC<LeftQueuePanelProps> = ({ queue, activeQueueId, onSelectQueue }) => {
  return (
    <aside className="lg:col-span-3 lg:h-full">
      <div className="flex h-full min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white p-3 shadow-sm">
        <h3 className="mb-3 inline-flex items-center gap-2 text-sm font-semibold text-slate-900">
          <ClipboardList className="h-4 w-4 text-cyan-700" />
          Prescriber Work Queue
        </h3>
        <div className="space-y-2 overflow-y-auto pr-1 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
          {queue.map(item => (
            <button
              key={item.id}
              className={`w-full cursor-pointer rounded-xl border px-3 py-2 text-left transition active:scale-[0.99] ${
                item.id === activeQueueId ? 'border-cyan-300 bg-cyan-50' : 'border-slate-200 bg-white hover:bg-slate-50'
              }`}
              onClick={() => onSelectQueue(item.id)}
            >
              <div className="flex items-center justify-between gap-3">
                <p className="text-sm font-medium text-slate-800">{item.name}</p>
                <span
                  className={`rounded-full px-2 py-0.5 text-[11px] ${
                    item.priority === 'high'
                      ? 'bg-rose-100 text-rose-700'
                      : item.priority === 'medium'
                        ? 'bg-amber-100 text-amber-700'
                        : 'bg-emerald-100 text-emerald-700'
                  }`}
                >
                  {item.priority}
                </span>
              </div>
              <p className="mt-1 text-xs text-slate-500">{item.id}</p>
              <div className="mt-1">
                <span
                  className={`inline-flex rounded-full px-2 py-0.5 text-[11px] font-medium ${
                    item.status.toLowerCase().includes('in progress')
                      ? 'bg-cyan-100 text-cyan-700'
                      : item.status.toLowerCase().includes('pending')
                        ? 'bg-amber-100 text-amber-700'
                        : item.status.toLowerCase().includes('follow-up')
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-slate-100 text-slate-700'
                  }`}
                >
                  {item.status}
                </span>
              </div>
            </button>
          ))}
        </div>
      </div>
    </aside>
  );
};

export default LeftQueuePanel;
