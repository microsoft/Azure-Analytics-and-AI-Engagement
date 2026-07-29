import React from 'react';
import { Pill } from 'lucide-react';

const FormularyCard: React.FC = () => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <h3 className="mb-3 inline-flex items-center gap-2 text-xs font-semibold text-slate-900">
        <Pill className="h-3.5 w-3.5 text-cyan-700" />
        Clinical Guidance Context
      </h3>
      <div className="space-y-2 text-xs text-slate-700">
        <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          <p className="text-[11px] text-slate-500">Drug Interaction Context</p>
          <p className="text-xs font-medium">Available for assistant responses</p>
        </div>
        <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
          <p className="text-[11px] text-slate-500">Dosing Guidance Context</p>
          <p className="text-xs font-medium">Available for assistant responses</p>
        </div>
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2">
          <p className="text-[11px] text-emerald-700">Formulary Status Context</p>
          <p className="text-xs font-medium text-emerald-800">Ready to answer prescriber-specific queries</p>
        </div>
      </div>
    </div>
  );
};

export default FormularyCard;
