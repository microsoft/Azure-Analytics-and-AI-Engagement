import React from 'react';
import type { EnrollmentForm } from './constants';

interface EnrollmentFormCardProps {
  enrollmentForm: EnrollmentForm;
  setEnrollmentForm: React.Dispatch<React.SetStateAction<EnrollmentForm>>;
  onCreateEnrollment: () => void;
  enrollmentLoading: boolean;
  enrollmentError: string | null;
  enrollmentActionLabel?: string;
  enrollmentLoadingLabel?: string;
}

const EnrollmentFormCard: React.FC<EnrollmentFormCardProps> = ({
  enrollmentForm,
  setEnrollmentForm,
  onCreateEnrollment,
  enrollmentLoading,
  enrollmentError,
  enrollmentActionLabel = 'Create Enrollment',
  enrollmentLoadingLabel = 'Saving...',
}) => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="mb-3">
        <h3 className="text-sm font-semibold text-slate-900">Prescriber Enrollment Form</h3>
      </div>
      <div className="space-y-2">
        <input
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
          value={enrollmentForm.npi}
          onChange={e => setEnrollmentForm(prev => ({ ...prev, npi: e.target.value }))}
          placeholder="NPI"
        />
        <div className="grid grid-cols-2 gap-2">
          <input
            className="rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
            value={enrollmentForm.firstName}
            onChange={e => setEnrollmentForm(prev => ({ ...prev, firstName: e.target.value }))}
            placeholder="First name"
          />
          <input
            className="rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
            value={enrollmentForm.lastName}
            onChange={e => setEnrollmentForm(prev => ({ ...prev, lastName: e.target.value }))}
            placeholder="Last name"
          />
        </div>
        <input
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
          value={enrollmentForm.email}
          onChange={e => setEnrollmentForm(prev => ({ ...prev, email: e.target.value }))}
          placeholder="Email"
        />
        <input
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
          value={enrollmentForm.specialty}
          onChange={e => setEnrollmentForm(prev => ({ ...prev, specialty: e.target.value }))}
          placeholder="Specialty"
        />
        <input
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
          value={enrollmentForm.organizationName}
          onChange={e => setEnrollmentForm(prev => ({ ...prev, organizationName: e.target.value }))}
          placeholder="Organization"
        />
        <div className="mt-2">
          <button
            className="w-full cursor-pointer rounded-md bg-cyan-700 px-3 py-2 text-sm font-medium text-white transition hover:bg-cyan-600 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60"
            onClick={onCreateEnrollment}
            disabled={enrollmentLoading}
          >
            {enrollmentLoading ? enrollmentLoadingLabel : enrollmentActionLabel}
          </button>
        </div>
        {enrollmentError ? <p className="text-xs text-rose-600">{enrollmentError}</p> : null}
      </div>
    </div>
  );
};

export default EnrollmentFormCard;
