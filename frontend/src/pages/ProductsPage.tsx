import React, { useEffect, useState, useRef } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchProducts, setPage, setPageSize, setSortBy, setSortOrder } from '../store/productSlice';
import type { AppDispatch } from '../store/store';
import ProductGrid from '../components/ProductGrid';
import ProductsPageSearchBar from '../components/ProductsPageSearchBar';
import { ArrowDownWideNarrow } from 'lucide-react';
import { RootState } from '../store/store';
import { setSelectedCategory } from '../store/productSlice';
import { useLocation } from 'react-router-dom';

const sortOptions = [
  { label: 'Featured', value: 'featured' },
  { label: 'Price: Low to High', value: 'priceLow' },
  { label: 'Price: High to Low', value: 'priceHigh' },
  { label: 'Rating', value: 'rating' },
  { label: 'Newest', value: 'newest' },
];

const ratingOptions = [5, 4, 3, 2, 1];

const ProductsPage: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const location = useLocation();
  const { categories, selectedCategory, searchTerm, page, pageSize, sortBy, sortOrder, total, loading } = useSelector((state: RootState) => state.products);
  const productGridScrollRef = useRef<HTMLDivElement>(null);

  // Set selectedCategory from URL query param on mount and when location changes
  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const category = params.get('category');
    if (category) {
      dispatch(setSelectedCategory(category === 'Zava' ? 'Zava' : 'All'));
    } else {
      dispatch(setSelectedCategory('All'));
    }
  }, [location.search, dispatch]);

  // Reset products and page when filters/search/sort/pageSize change
  useEffect(() => {
    dispatch({ type: 'products/resetProducts' });
  }, [dispatch, searchTerm, selectedCategory, sortBy, sortOrder, pageSize]);

  // Fetch products when page or filters change
  useEffect(() => {
    dispatch(fetchProducts({
      search: searchTerm,
      category: selectedCategory === 'All' ? undefined : selectedCategory,
      sortBy,
      sortOrder,
      page,
      pageSize,
      append: page > 1,
    }));
  }, [dispatch, searchTerm, selectedCategory, sortBy, sortOrder, page, pageSize]);

  const handleCategoryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    dispatch(setSelectedCategory(e.target.value));
  };

  const handleSortChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    if (value === 'priceLow') {
      dispatch(setSortBy('price'));
      dispatch(setSortOrder('asc'));
    } else if (value === 'priceHigh') {
      dispatch(setSortBy('price'));
      dispatch(setSortOrder('desc'));
    } else if (value === 'rating') {
      dispatch(setSortBy('rating'));
      dispatch(setSortOrder('desc'));
    } else if (value === 'newest') {
      dispatch(setSortBy('createdAt'));
      dispatch(setSortOrder('desc'));
    } else {
      dispatch(setSortBy('featured'));
      dispatch(setSortOrder('desc'));
    }
  };

  // Pagination controls
  const totalPages = Math.ceil(total / pageSize);
  const handlePageChange = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages) {
      dispatch(setPage(newPage));
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Sticky Search & Sort Bar */}
        <div className="sticky top-0 z-30 bg-gray-50 pt-4 pb-4 mb-4 flex flex-col md:flex-row md:items-center gap-4" style={{ boxShadow: '0 2px 8px 0 rgba(0,0,0,0.03)' }}>
          <div className="flex-1">
            <ProductsPageSearchBar />
          </div>
          <div className="flex items-center gap-2">
            {/* Sort Select */}
            <ArrowDownWideNarrow className="h-5 w-5 text-gray-400" />
            <select
              value={sortBy === 'price' ? (sortOrder === 'asc' ? 'priceLow' : 'priceHigh') : sortBy}
              onChange={handleSortChange}
              className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none text-gray-700 bg-white"
            >
              {sortOptions.map(option => (
                <option key={option.value} value={option.value}>{option.label}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex flex-col lg:flex-row gap-8">
          {/* Sticky Sidebar */}
          <div className="lg:w-72 flex-shrink-0">
            <div className="sticky top-24 z-20 space-y-6 pb-8" style={{ marginBottom: '2rem' }}>
              {/* Category Select */}
              <div className="bg-white p-4 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Category</h3>
                <select
                  value={selectedCategory}
                  onChange={handleCategoryChange}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none text-gray-700 bg-white"
                >
                  {categories.map((category) => (
                    <option key={category} value={category}>{category}</option>
                  ))}
                </select>
              </div>
              {/* Dummy Ratings Filter */}
              <div className="bg-white p-4 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Rating</h3>
                <div className="flex flex-col gap-1">
                  {[5, 4, 3, 2, 1].map(rating => (
                    <label key={rating} className="inline-flex items-center gap-1 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={false}
                        onChange={() => {}}
                        className="accent-blue-600"
                      />
                      <span className="flex items-center">
                        {[...Array(rating)].map((_, i) => (
                          <span key={i} className="text-yellow-400 text-base">★</span>
                        ))}
                      </span>
                      <span className="text-gray-600 text-xs ml-1">&amp; up</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Main Content: Product List/Grid */}
          <div className="flex-1">
            <div ref={productGridScrollRef} style={{ maxHeight: 'calc(100vh - 180px)', overflowY: 'auto' }} className="custom-scrollbar">
              {loading ? (
                <div className="text-center py-12 text-lg text-gray-500">Loading...</div>
              ) : (
                <ProductGrid scrollContainerRef={productGridScrollRef} />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductsPage;