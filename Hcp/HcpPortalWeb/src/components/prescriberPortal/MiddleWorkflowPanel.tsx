import React from 'react';
import type { EnrollmentForm, QueueItem } from './constants';
import DocumentValidationCard from './DocumentValidationCard';
import EnrollmentFormCard from './EnrollmentFormCard';
import FormularyCard from './FormularyCard';
import NotificationsCard from './NotificationsCard';
import PortalHeroCard from './PortalHeroCard';

interface MiddleWorkflowPanelProps {
  activeQueueItem: QueueItem | null;
  enrollmentJourney: string[];
  enrollmentForm: EnrollmentForm;
  setEnrollmentForm: React.Dispatch<React.SetStateAction<EnrollmentForm>>;
  onCreateEnrollment: () => void;
  enrollmentLoading: boolean;
  enrollmentError: string | null;
  enrollmentActionLabel?: string;
  enrollmentLoadingLabel?: string;
}

const MiddleWorkflowPanel: React.FC<MiddleWorkflowPanelProps> = ({
  activeQueueItem,
  enrollmentJourney,
  enrollmentForm,
  setEnrollmentForm,
  onCreateEnrollment,
  enrollmentLoading,
  enrollmentError,
  enrollmentActionLabel,
  enrollmentLoadingLabel,
}) => {
  return (
    <main className="space-y-2 lg:col-span-5 lg:h-full lg:overflow-y-auto lg:pr-1">
      <PortalHeroCard enrollmentJourney={enrollmentJourney} />
      <EnrollmentFormCard
        enrollmentForm={enrollmentForm}
        setEnrollmentForm={setEnrollmentForm}
        onCreateEnrollment={onCreateEnrollment}
        enrollmentLoading={enrollmentLoading}
        enrollmentError={enrollmentError}
        enrollmentActionLabel={enrollmentActionLabel}
        enrollmentLoadingLabel={enrollmentLoadingLabel}
      />
      <div className="grid gap-2 md:grid-cols-2">
        <DocumentValidationCard />
        <FormularyCard />
      </div>
      <NotificationsCard activeQueueItem={activeQueueItem} />
    </main>
  );
};

export default MiddleWorkflowPanel;
