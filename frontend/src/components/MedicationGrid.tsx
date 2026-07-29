import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store/store';
import MedicationCard from './MedicationCard';
import { Loader2 } from 'lucide-react';
import { setPage } from '../store/medicationSlice';
import type { AppDispatch } from '../store/store';

interface MedicationGridProps {
  scrollContainerRef?: React.RefObject<HTMLDivElement>;
}

const MedicationGrid: React.FC<MedicationGridProps> = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { products, loading, page, hasMore } = useSelector((state: RootState) => state.medications);

  return (
    <div style={{ minHeight: '60vh' }}>
      {products.length === 0 && !loading ? (
        <div className="text-center py-12 text-gray-500">No medications found</div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
          {products.map(med => (
            <MedicationCard key={med.id} product={med} />
          ))}
        </div>
      )}
      <div className="flex flex-col items-center py-6 gap-2">
        {loading && <Loader2 className="animate-spin h-6 w-6 text-teal-500" />}
        {!loading && hasMore && (
          <button onClick={() => dispatch(setPage(page + 1))} className="px-6 py-2 bg-teal-600 text-white font-semibold rounded-lg hover:bg-teal-700 transition-colors">
            Show More
          </button>
        )}
      </div>
    </div>
  );
};

export default MedicationGrid;
