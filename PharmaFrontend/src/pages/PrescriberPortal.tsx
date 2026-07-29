import React from 'react';
import { Search, FileText, Bell, MessageSquare, PlusSquare, RefreshCw } from 'lucide-react';

const PrescriberPortal: React.FC = () => {
  return (
    <div className="w-full min-h-screen p-6 bg-gray-50">
      <div className="max-w-7xl mx-auto">
        <header className="mb-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-semibold">HCP Prescriber Portal</h1>
            <div className="text-sm text-slate-500">Dr. Smith</div>
          </div>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4 items-center">
            <div className="md:col-span-2">
              <div className="flex gap-2">
                <div className="flex items-center bg-white border rounded-md px-3 py-2 w-full">
                  <Search className="h-5 w-5 text-slate-400 mr-2" />
                  <input placeholder="Ask a clinical question..." className="w-full outline-none text-sm" />
                </div>
                <button className="px-4 py-2 bg-slate-800 text-white rounded-md text-sm">Search</button>
              </div>

              <div className="mt-3 flex gap-3">
                <button className="px-3 py-1.5 bg-white border rounded text-sm">Guidelines?</button>
                <button className="px-3 py-1.5 bg-white border rounded text-sm">Dosing Info?</button>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3">
              <button className="flex items-center gap-2 bg-white border px-3 py-2 rounded-md text-sm">
                <Bell className="h-4 w-4" /> Notifications
              </button>
            </div>
          </div>
        </header>

        <section className="grid grid-cols-1 lg:grid-cols-12 gap-4">
          <aside className="lg:col-span-3 space-y-4">
            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Patient Overview</h3>
              <p className="text-sm text-slate-600">Patient Name</p>
              <p className="text-sm text-slate-600">Age / ID Info</p>
              <ul className="list-disc pl-5 mt-2 text-sm text-slate-600">
                <li>Current Medications</li>
                <li>Recent Visits</li>
              </ul>
            </div>

            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Quick Actions</h3>
              <div className="flex gap-2">
                <button className="flex-1 px-3 py-2 bg-teal-600 text-white rounded">New Rx</button>
                <button className="px-3 py-2 bg-white border rounded">Refill</button>
                <button className="px-3 py-2 bg-white border rounded">Add Note</button>
              </div>
            </div>

            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Clinical Resources</h3>
              <ul className="text-sm text-slate-600 space-y-1">
                <li>Treatment Guidelines</li>
                <li>Dosing Calculator</li>
                <li>Drug Interactions</li>
              </ul>
            </div>
          </aside>

          <div className="lg:col-span-6 space-y-4">
            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Notifications</h3>
              <ul className="list-disc pl-5 text-sm text-slate-600">
                <li>Lab Results Update</li>
                <li>New Message From Rep</li>
                <li>Formulary Change Alert</li>
              </ul>
            </div>

            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">AI Assistant Chat</h3>
              <div className="space-y-2">
                <div className="bg-slate-50 border rounded p-3 text-sm">What's the dosage for...?</div>
                <div className="bg-slate-50 border rounded p-3 text-sm">Any recent studies on...?</div>
              </div>

              <div className="mt-3 flex gap-2">
                <input className="flex-1 border rounded px-3 py-2" placeholder="Type a question..." />
                <button className="px-4 py-2 bg-slate-800 text-white rounded">Send</button>
              </div>
            </div>
          </div>

          <aside className="lg:col-span-3 space-y-4">
            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Announcements</h3>
              <ul className="list-disc pl-5 text-sm text-slate-600">
                <li>New Treatment Guidelines</li>
                <li>Webinar: Best Practices</li>
              </ul>
            </div>

            <div className="bg-white border rounded-md p-4">
              <h3 className="font-semibold mb-2">Data Insights</h3>
              <div className="space-y-3">
                <div className="h-20 bg-slate-100 rounded" />
                <div className="h-20 bg-slate-100 rounded" />
              </div>
            </div>
          </aside>
        </section>
      </div>
    </div>
  );
};

export default PrescriberPortal;
