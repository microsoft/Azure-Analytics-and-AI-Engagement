import React from 'react';
import { AlertCircle, CheckCircle2, FileCheck2 } from 'lucide-react';

const DocumentValidationCard: React.FC = () => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <h3 className="mb-3 inline-flex items-center gap-2 text-xs font-semibold text-slate-900">
        <FileCheck2 className="h-3.5 w-3.5 text-cyan-700" />
        Document Validation
      </h3>
      <div className="space-y-2 text-xs">
        <div className="flex items-center justify-between rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2">
          <span>Enrollment Event Published</span>
          <span className="inline-flex items-center gap-1 text-emerald-700">
            <CheckCircle2 className="h-3.5 w-3.5" /> Completed
          </span>
        </div>
        <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          <span>Document Validation Queue</span>
          <span className="inline-flex items-center gap-1 text-slate-700">
            In Progress
          </span>
        </div>
        <div className="flex items-center justify-between rounded-lg border border-amber-200 bg-amber-50 px-3 py-2">
          <span>EHR Update</span>
          <span className="inline-flex items-center gap-1 text-amber-700">
            <AlertCircle className="h-3.5 w-3.5" /> Pending Partner Response
          </span>
        </div>
      </div>
    </div>
  );
};

export default DocumentValidationCard;
