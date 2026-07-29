import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Search } from 'lucide-react';
import { RootState } from '../store/store';
import { setSearchTerm } from '../store/medicationSlice';

const MedicationsSearchBar: React.FC = () => {
  const dispatch = useDispatch();
  const searchTerm = useSelector((state: RootState) => state.medications.searchTerm);

  return (
    <div className="relative w-full">
      <input
        type="text"
        value={searchTerm}
        onChange={e => dispatch(setSearchTerm(e.target.value))}
        placeholder="Search medications by name, generic name..."
        className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent outline-none transition-all text-sm"
      />
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
    </div>
  );
};

export default MedicationsSearchBar;
