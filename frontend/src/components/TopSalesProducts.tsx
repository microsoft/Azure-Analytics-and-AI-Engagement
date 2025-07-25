import React from 'react';
import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { RootState } from '../store/store';
import ProductCard from './ProductCard';

const TopSalesProducts: React.FC = () => {
  const products = useSelector((state: RootState) => state.products.products);
  const TopSalesProducts = products.filter(product => product.featured).slice(0, 4);

  return (
    <section className="py-10 sm:py-14 md:py-16 bg-gray-50">
      <div className="max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8">
        <div className="text-center mb-8 md:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-gray-900 mb-3 md:mb-4">
            Top Sales Products
          </h2>
          <p className="text-base sm:text-lg text-gray-600 max-w-2xl mx-auto">
            Discover our top sales products, popular and highest-rated motor parts, trusted by professionals and enthusiasts alike
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-10 md:mb-12">
          {TopSalesProducts.map((product) => (
            <div key={product.id} className="h-full flex">
              <ProductCard product={product} />
            </div>
          ))}
        </div>

        <div className="text-center">
          <Link
            to="/products"
            className="inline-flex items-center bg-blue-600 hover:bg-blue-700 text-white px-6 sm:px-8 py-2.5 sm:py-3 rounded-lg font-semibold transition-colors text-base sm:text-lg"
          >
            View All Products
            <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </div>
      </div>
    </section>
  );
};

export default TopSalesProducts;