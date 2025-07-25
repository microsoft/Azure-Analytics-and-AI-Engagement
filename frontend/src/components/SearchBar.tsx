import React, { useState, useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Link, useNavigate } from 'react-router-dom';
import { Search, X } from 'lucide-react';
import { RootState } from '../store/store';
import { setSearchTerm } from '../store/productSlice';

const SearchBar: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const searchTerm = useSelector((state: RootState) => state.products.searchTerm);
  const products = useSelector((state: RootState) => state.products.products);
  const [showResults, setShowResults] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  // Filter products based on search term
  const filteredProducts = products.filter(product =>
    product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.description.toLowerCase().includes(searchTerm.toLowerCase())
  ).slice(0, 6); // Limit to 6 results

  // Handle click outside to close dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setShowResults(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Show results when search term changes and input is focused
  useEffect(() => {
    if (searchTerm.trim() && isFocused) {
      setShowResults(true);
    } else {
      setShowResults(false);
    }
  }, [searchTerm, isFocused]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchTerm.trim()) {
      setShowResults(false);
      navigate('/products');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    dispatch(setSearchTerm(e.target.value));
  };

  const handleProductClick = () => {
    setShowResults(false);
    dispatch(setSearchTerm(''));
  };

  const clearSearch = () => {
    dispatch(setSearchTerm(''));
    setShowResults(false);
  };

  return (
    <div ref={searchRef} className="relative w-full">
      <form onSubmit={handleSearch} className="relative">
        <div className="relative">
          <input
            type="text"
            value={searchTerm}
            onChange={handleInputChange}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            placeholder="Search for motor parts..."
            className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all"
          />
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          {searchTerm && (
            <button
              type="button"
              onClick={clearSearch}
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </form>

      {/* Search Results Dropdown */}
      {showResults && searchTerm.trim() && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-xl z-50 max-h-96 overflow-y-auto">
          {filteredProducts.length > 0 ? (
            <div className="py-2">
              {filteredProducts.map((product) => (
                <Link
                  key={product.id}
                  to={`/product/${product.id}`}
                  onClick={handleProductClick}
                  className="flex items-center px-4 py-3 hover:bg-gray-50 cursor-pointer transition-colors border-b border-gray-100 last:border-b-0"
                >
                  <div className="flex-shrink-0 w-12 h-12 mr-4">
                    <img
                      src={product.images[0]}
                      alt={product.name}
                      className="w-full h-full object-cover rounded-lg"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=150&h=150&fit=crop&crop=center';
                      }}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-medium text-gray-900 truncate">
                      {product.name}
                    </h4>
                    <p className="text-xs text-gray-500 truncate">
                      {product.category}
                    </p>
                    <div className="flex items-center mt-1">
                      <span className="text-sm font-semibold text-blue-600">
                        ${product.price}
                      </span>
                      {product.originalPrice && product.originalPrice > product.price && (
                        <span className="text-xs text-gray-400 line-through ml-2">
                          ${product.originalPrice}
                        </span>
                      )}
                      <div className="flex items-center ml-auto">
                        <div className="flex items-center">
                          {[...Array(5)].map((_, i) => (
                            <svg
                              key={i}
                              className={`w-3 h-3 ${
                                i < Math.floor(product.rating) ? 'text-yellow-400' : 'text-gray-300'
                              }`}
                              fill="currentColor"
                              viewBox="0 0 20 20"
                            >
                              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                            </svg>
                          ))}
                        </div>
                        <span className="text-xs text-gray-500 ml-1">
                          ({product.reviews})
                        </span>
                      </div>
                    </div>
                  </div>
                </Link>
              ))}
              {filteredProducts.length > 0 && (
                <div className="px-4 py-2 border-t border-gray-200 bg-gray-50">
                  <Link
                    to="/products"
                    onClick={() => setShowResults(false)}
                    className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                  >
                    View all results ({filteredProducts.length})
                  </Link>
                </div>
              )}
            </div>
          ) : (
            <div className="px-4 py-6 text-center">
              <div className="text-gray-500 mb-2">No products found</div>
              <div className="text-sm text-gray-400">
                Try searching with different keywords
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default SearchBar;