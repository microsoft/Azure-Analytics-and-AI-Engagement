import React from 'react';
import { ShieldCheck } from 'lucide-react';
import type { QueueItem } from './constants';

interface NotificationsCardProps {
  activeQueueItem: QueueItem | null;
}

const NotificationsCard: React.FC<NotificationsCardProps> = ({ activeQueueItem }) => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <h3 className="mb-3 inline-flex items-center gap-2 text-sm font-semibold text-slate-900">
        <ShieldCheck className="h-4 w-4 text-cyan-700" />
        Notifications and Actions
      </h3>
      <ul className="space-y-2 text-sm text-slate-700">
        <li className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          {activeQueueItem
            ? `Enrollment event published to queue for ${activeQueueItem.id}.`
            : 'Select a prescriber from the queue to view enrollment activity.'}
        </li>
        <li className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          Document validation is processing asynchronously in background worker.
        </li>
        <li className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          EHR update callback is pending for the current enrollment.
        </li>
      </ul>
    </div>
  );
};

export default NotificationsCard;
