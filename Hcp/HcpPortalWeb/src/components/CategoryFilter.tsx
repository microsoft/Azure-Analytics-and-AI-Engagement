import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store/store';
import { setSelectedCategory } from '../store/medicationSlice';

const CategoryFilter: React.FC = () => {
  const dispatch = useDispatch();
  const { categories, selectedCategory } = useSelector((state: RootState) => state.medications);

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm border">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Categories</h3>
      <div className="space-y-2">
        {categories.map(category => (
          <button
            key={category}
            onClick={() => dispatch(setSelectedCategory(category))}
            className={`w-full text-left px-3 py-2 rounded-lg transition-colors ${
              selectedCategory === category
                ? 'bg-teal-100 text-teal-700 font-medium'
                : 'text-gray-700 hover:bg-gray-100'
            }`}
          >
            {category}
          </button>
        ))}
      </div>
    </div>
  );
};

export default CategoryFilter;
