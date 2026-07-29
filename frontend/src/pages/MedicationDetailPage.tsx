import React from 'react';
import { useParams, Navigate, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { ArrowLeft, ShieldCheck, Pill, Building2, Beaker, Package, AlertCircle } from 'lucide-react';
import { RootState } from '../store/store';

const MedicationDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const medication = useSelector((state: RootState) =>
    state.medications.products.find(m => m.id === id)
  );

  if (!medication) return <Navigate to="/medications" replace />;

  const details = [
    { icon: <Pill className="h-4 w-4 text-teal-600" />, label: 'Generic Name', value: medication.genericName },
    { icon: <Building2 className="h-4 w-4 text-teal-600" />, label: 'Manufacturer', value: medication.manufacturer },
    { icon: <Beaker className="h-4 w-4 text-teal-600" />, label: 'Dosage Form', value: medication.dosageForm },
    { icon: <Package className="h-4 w-4 text-teal-600" />, label: 'Strength', value: medication.strength },
  ].filter(d => d.value);

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-gray-600 hover:text-teal-700 mb-6 transition-colors font-medium">
          <ArrowLeft className="h-5 w-5" /> Back to Medications
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
          {/* Image */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm border aspect-square relative">
            <img
              src={medication.imageUrl}
              alt={medication.name}
              className="w-full h-full object-cover"
              onError={(e) => { (e.target as HTMLImageElement).src = 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=600'; }}
            />
            {medication.requiresPrescription && (
              <div className="absolute top-3 left-3 bg-blue-600 text-white text-xs px-2 py-1 rounded-full flex items-center gap-1 shadow">
                <ShieldCheck className="h-3 w-3" /> Prescription Required
              </div>
            )}
            {!medication.inStock && (
              <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                <span className="text-white font-semibold flex items-center gap-2">
                  <AlertCircle className="h-5 w-5" /> Out of Stock
                </span>
              </div>
            )}
          </div>

          {/* Details */}
          <div className="space-y-5">
            <div>
              <span className="text-sm font-medium text-teal-600">{medication.category}</span>
              <h1 className="text-3xl font-bold text-gray-900 mt-1">{medication.name}</h1>
              {medication.genericName && (
                <p className="text-gray-500 italic mt-1">{medication.genericName}</p>
              )}
            </div>

            <div className="flex items-center gap-4 flex-wrap">
              <span className="text-3xl font-bold text-gray-900">${medication.price.toFixed(2)}</span>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${medication.inStock ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                {medication.inStock ? `In Stock (${medication.stock})` : 'Out of Stock'}
              </span>
            </div>

            <p className="text-gray-700 leading-relaxed">{medication.description}</p>

            {details.length > 0 && (
              <div className="bg-white rounded-xl border p-4 grid grid-cols-2 gap-3">
                {details.map(d => (
                  <div key={d.label} className="flex items-start gap-2">
                    <div className="mt-0.5 flex-shrink-0">{d.icon}</div>
                    <div>
                      <p className="text-xs text-gray-500">{d.label}</p>
                      <p className="text-sm font-medium text-gray-800">{d.value}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {medication.requiresPrescription && (
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 flex items-start gap-3">
                <ShieldCheck className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-semibold text-blue-800">Prescription Required</p>
                  <p className="text-xs text-blue-700 mt-0.5">A valid prescription is needed to dispense this medication. Please upload your prescription at checkout.</p>
                </div>
              </div>
            )}

            <button onClick={() => navigate('/medications')} className="w-full border border-gray-300 rounded-xl py-3 text-gray-700 hover:bg-gray-50 font-medium transition-colors">
              Back to Medications
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MedicationDetailPage;
