import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Search } from 'lucide-react';
import { RootState } from '../store/store';
import { setSearchTerm } from '../store/productSlice';

const ProductsPageSearchBar: React.FC = () => {
  const dispatch = useDispatch();
  const searchTerm = useSelector((state: RootState) => state.products.searchTerm);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    dispatch(setSearchTerm(e.target.value));
  };

  return (
    <div className="relative w-full">
      <input
        type="text"
        value={searchTerm}
        onChange={handleInputChange}
        placeholder="Search for motor parts..."
        className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all"
      />
      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
    </div>
  );
};

export default ProductsPageSearchBar; 