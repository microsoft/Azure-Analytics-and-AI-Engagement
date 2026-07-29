import React from 'react';

interface EnrollmentTimelineCardProps {
  enrollmentJourney: string[];
}

const EnrollmentTimelineCard: React.FC<EnrollmentTimelineCardProps> = ({ enrollmentJourney }) => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <h3 className="mb-3 text-sm font-semibold text-slate-900">Prescriber Enrollment Status Timeline</h3>
      <div className="grid grid-cols-3 gap-2 text-xs sm:grid-cols-6">
        {enrollmentJourney.map((step, index) => {
          const completed = index < 3;
          const active = index === 3;
          return (
            <div key={step} className="flex flex-col items-center gap-1 text-center">
              <span
                className={`inline-flex h-7 w-7 items-center justify-center rounded-full border text-[11px] font-semibold ${
                  active
                    ? 'border-cyan-600 bg-cyan-600 text-white'
                    : completed
                      ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
                      : 'border-slate-300 bg-white text-slate-500'
                }`}
              >
                {index + 1}
              </span>
              <span className="text-slate-600">{step}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default EnrollmentTimelineCard;
