export type QueuePriority = 'high' | 'medium' | 'low';

export interface QueueItem {
  id: string;
  name: string;
  npi?: string;
  status: string;
  priority: QueuePriority;
}

export interface EnrollmentForm {
  npi: string;
  firstName: string;
  lastName: string;
  email: string;
  specialty: string;
  organizationName: string;
}

export const PRESCRIBER_QUEUE: QueueItem[] = [
  { id: 'APP-82110-AI', name: 'Amanda Wilson', npi: '1234567890', status: 'In Progress', priority: 'high' },
  { id: 'APP-82910-LW', name: 'Joe Williamson', npi: '2234567890', status: 'Pending Documents', priority: 'medium' },
  { id: 'APP-82110-JD', name: 'John Doe', npi: '3234567890', status: 'Validation Pending', priority: 'high' },
  { id: 'APP-82110-SA', name: 'Sarah Ali', npi: '4234567890', status: 'EHR Update Pending', priority: 'low' },
];

export const ENROLLMENT_JOURNEY = [
  'Prescriber Enrollment',
  'Document Validation',
  'EHR Update',
  'Approval & Follow-up',
];

export const QUICK_PROMPTS = ['Drug Interactions', 'Dosing Guidance', 'Formulary Status'];

export const INITIAL_ENROLLMENT_FORM: EnrollmentForm = {
  npi: '',
  firstName: '',
  lastName: '',
  email: '',
  specialty: '',
  organizationName: '',
};

export const STARTER_PROMPTS = [
  'Ready to answer clinician questions using grounded customer-specific data.',
];
