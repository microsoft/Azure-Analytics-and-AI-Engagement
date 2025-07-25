import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store/store';
import ProductCard from './ProductCard';
import { LayoutGrid, List, Loader2 } from 'lucide-react';
import { setPage } from '../store/productSlice';
import type { AppDispatch } from '../store/store';

interface ProductGridProps {
  scrollContainerRef?: React.RefObject<HTMLDivElement>;
}

const ProductGrid: React.FC<ProductGridProps> = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { products, loading, page, hasMore } = useSelector((state: RootState) => state.products);
  const [view, setView] = useState<'grid' | 'list'>('grid');

  const handleShowMore = () => {
    dispatch(setPage(page + 1));
  };

  return (
    <div style={{ minHeight: '60vh' }}>
      {/* Grid/List Toggle */}
      <div className="flex justify-end mb-4 gap-2">
        <button
          className={`p-2 rounded-lg border transition-colors ${view === 'grid' ? 'bg-blue-600 text-white' : 'bg-white text-gray-500 hover:bg-gray-100'}`}
          onClick={() => setView('grid')}
          aria-label="Grid view"
        >
          <LayoutGrid className="h-5 w-5" />
        </button>
        <button
          className={`p-2 rounded-lg border transition-colors ${view === 'list' ? 'bg-blue-600 text-white' : 'bg-white text-gray-500 hover:bg-gray-100'}`}
          onClick={() => setView('list')}
          aria-label="List view"
        >
          <List className="h-5 w-5" />
        </button>
      </div>

      {products.length === 0 && !loading ? (
        <div className="text-center py-12">
          <div className="text-gray-500 text-lg mb-4">No products found</div>
          <p className="text-gray-400">Try adjusting your search or filter criteria</p>
        </div>
      ) : view === 'grid' ? (
        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          {products.map((product) => (
            <div key={product.id} className="bg-white rounded-xl shadow-sm border hover:shadow-lg transition-all duration-300 flex flex-col md:flex-row items-center p-4 gap-6">
              <img src={product.images[0]} alt={product.name} className="w-32 h-32 object-cover rounded-lg" />
              <div className="flex-1 w-full">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2">
                  <div>
                    <div className="text-blue-600 font-medium text-sm mb-1">{product.category}</div>
                    <div className="text-xl font-bold text-gray-900 mb-1">{product.name}</div>
                    <div className="text-gray-600 text-sm mb-2 line-clamp-2">{product.description}</div>
                  </div>
                  <div className="flex flex-col items-end gap-2 min-w-[120px]">
                    <span className="text-2xl font-bold text-gray-900">${product.price.toFixed(2)}</span>
                    {product.originalPrice && (
                      <span className="text-sm text-gray-500 line-through">${product.originalPrice.toFixed(2)}</span>
                    )}
                    {!product.inStock && (
                      <span className="bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs font-semibold">Out of Stock</span>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
      {/* Loader and Show More button for pagination */}
      <div className="flex flex-col items-center py-6 gap-2">
        {loading && <Loader2 className="animate-spin h-6 w-6 text-blue-500" />}
        {!loading && hasMore && (
          <button
            onClick={handleShowMore}
            className="px-6 py-2 rounded bg-blue-600 text-white font-semibold hover:bg-blue-700 transition-colors"
          >
            Show More
          </button>
        )}
      </div>
    </div>
  );
};

export default ProductGrid;