import React from 'react';
import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { RootState } from '../store/store';
import MedicationCard from './MedicationCard';

const FeaturedMedications: React.FC = () => {
  const products = useSelector((state: RootState) => state.medications.products);
  const featured = products.filter(p => p.featured).slice(0, 4);

  if (featured.length === 0) return null;

  return (
    <section className="py-10 sm:py-14 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-8">
          <h2 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-3">New Arrivals</h2>
          <p className="text-gray-600 max-w-2xl mx-auto">
            Freshly stocked medications and health products from trusted manufacturers.
          </p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
          {featured.map(med => (
            <div key={med.id} className="h-full flex">
              <MedicationCard product={med} />
            </div>
          ))}
        </div>
        <div className="text-center">
          <Link to="/medications" className="inline-flex items-center bg-teal-600 hover:bg-teal-700 text-white px-6 py-2.5 rounded-lg font-semibold transition-colors">
            View All Medications <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </div>
      </div>
    </section>
  );
};

export default FeaturedMedications;
