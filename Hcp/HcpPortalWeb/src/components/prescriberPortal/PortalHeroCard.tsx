import React from 'react';

interface PortalHeroCardProps {
  enrollmentJourney: string[];
}

const PortalHeroCard: React.FC<PortalHeroCardProps> = ({ enrollmentJourney }) => {
  const activeStepIndex = Math.max(0, enrollmentJourney.length - 1);

  return (
    <div className="rounded-2xl border border-slate-200 bg-gradient-to-r from-white via-sky-50 to-cyan-50 p-6 shadow-sm">
      <div>
        <p className="text-xs uppercase tracking-[0.22em] text-cyan-700">Caldova Care Flow</p>
        <h1 className="mt-1 text-3xl font-semibold text-slate-900">HCP Prescriber Portal</h1>
        <p className="mt-2 text-sm text-slate-600">
          Enroll prescribers faster, ask contextual clinical questions, and run guided therapy workflow sessions in one place.
        </p>
      </div>

      <div className="mt-4">
        <h3 className="mb-3 text-sm font-semibold text-slate-900">Prescriber Enrollment Status Timeline</h3>
        <div className="flex items-start text-xs">
          {enrollmentJourney.map((step, index) => {
            const completed = index < activeStepIndex;
            const active = index === activeStepIndex;
            const connectorComplete = index < activeStepIndex;

            return (
              <div key={step} className="flex min-w-0 flex-1 items-start">
                <div className="flex w-full flex-col items-center gap-1 text-center">
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
                  <span className="line-clamp-2 text-slate-600">{step}</span>
                </div>
                {index < enrollmentJourney.length - 1 && (
                  <span
                    className={`mt-3 block h-[2px] flex-1 rounded-full ${
                      connectorComplete ? 'bg-emerald-300' : 'bg-slate-200'
                    }`}
                    aria-hidden
                  />
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default PortalHeroCard;
