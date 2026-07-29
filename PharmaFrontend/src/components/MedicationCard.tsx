import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { AlertCircle, ShieldCheck, ShoppingCart, Check } from 'lucide-react';
import { Medication } from '../types';
import { addToCart } from '../store/cartSlice';
import type { AppDispatch } from '../store/store';

interface MedicationCardProps {
  product: Medication;
}

const MedicationCard: React.FC<MedicationCardProps> = ({ product }) => {
  const dispatch = useDispatch<AppDispatch>();
  const [added, setAdded] = useState(false);

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dispatch(addToCart(product));
    setAdded(true);
    setTimeout(() => setAdded(false), 1600);
  };

  return (
    <Link to={`/medication/${product.id}`} className="group block h-full">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200 overflow-hidden flex flex-col h-full">

        {/* Image */}
        <div className="relative w-full aspect-[4/3] bg-slate-100 overflow-hidden">
          <img
            src={product.imageUrl}
            alt={product.name}
            className="w-full h-full object-cover object-center transition-transform duration-300 group-hover:scale-105"
            onError={e => { (e.target as HTMLImageElement).src = 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=500'; }}
          />

          {/* Badges */}
          {product.requiresPrescription && (
            <span className="absolute top-2.5 left-2.5 bg-blue-600/90 backdrop-blur-sm text-white text-[10px] font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
              <ShieldCheck className="h-3 w-3" /> Rx Only
            </span>
          )}
          <span className={`absolute top-2.5 right-2.5 text-[10px] font-semibold px-2 py-0.5 rounded-full ${
            product.inStock
              ? 'bg-emerald-500/90 backdrop-blur-sm text-white'
              : 'bg-red-500/90 backdrop-blur-sm text-white'
          }`}>
            {product.inStock ? 'In Stock' : 'Out of Stock'}
          </span>

          {/* Out-of-stock overlay */}
          {!product.inStock && (
            <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
              <span className="text-white font-semibold text-sm flex items-center gap-1.5 bg-black/50 px-3 py-1.5 rounded-lg">
                <AlertCircle className="h-4 w-4" /> Out of Stock
              </span>
            </div>
          )}
        </div>

        {/* Content */}
        <div className="flex flex-col flex-1 p-4">
          {/* Category */}
          <span className="text-[11px] font-bold uppercase tracking-widest text-teal-600 mb-1">
            {product.category}
          </span>

          {/* Name */}
          <h3 className="text-[15px] font-bold text-slate-800 line-clamp-1 group-hover:text-teal-700 transition-colors mb-0.5">
            {product.name}
          </h3>

          {/* Generic name */}
          {product.genericName && (
            <p className="text-xs text-slate-400 italic mb-2">{product.genericName}</p>
          )}

          {/* Description */}
          <p className="text-slate-500 text-[13px] leading-relaxed line-clamp-2 mb-3">
            {product.description}
          </p>

          {/* Dosage chips */}
          {(product.dosageForm || product.strength) && (
            <div className="flex flex-wrap gap-1.5 mb-3">
              {product.dosageForm && (
                <span className="bg-slate-100 text-slate-500 text-[11px] px-2 py-0.5 rounded-md font-medium">
                  {product.dosageForm}
                </span>
              )}
              {product.strength && (
                <span className="bg-slate-100 text-slate-500 text-[11px] px-2 py-0.5 rounded-md font-medium">
                  {product.strength}
                </span>
              )}
            </div>
          )}

          {/* Price + Add to Cart */}
          <div className="mt-auto pt-3 border-t border-slate-100">
            <div className="flex items-center justify-between mb-2.5">
              <span className="text-xl font-extrabold text-slate-900">${product.price.toFixed(2)}</span>
              {product.manufacturer && (
                <span className="text-[11px] text-slate-400 truncate max-w-[100px]">{product.manufacturer}</span>
              )}
            </div>
            <button
              onClick={handleAddToCart}
              disabled={!product.inStock}
              className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all duration-200 ${
                added
                  ? 'bg-emerald-500 text-white shadow-sm shadow-emerald-200'
                  : product.inStock
                  ? 'bg-teal-600 hover:bg-teal-700 text-white shadow-sm shadow-teal-100 hover:shadow-teal-200'
                  : 'bg-slate-100 text-slate-400 cursor-not-allowed'
              }`}
            >
              {added ? (
                <><Check className="h-4 w-4" /> Added to Cart</>
              ) : (
                <><ShoppingCart className="h-4 w-4" /> Add to Cart</>
              )}
            </button>
          </div>
        </div>
      </div>
    </Link>
  );
};

export default MedicationCard;
