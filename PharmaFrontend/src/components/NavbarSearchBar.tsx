import React, { useState, useEffect, useRef } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { Search, X, ShieldCheck } from 'lucide-react';
import { RootState } from '../store/store';

const NavbarSearchBar: React.FC = () => {
  const navigate = useNavigate();
  const products = useSelector((state: RootState) => state.medications.products);
  const [inputValue, setInputValue] = useState('');
  const [showResults, setShowResults] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  const filtered = products.filter(p =>
    p.name.toLowerCase().includes(inputValue.toLowerCase()) ||
    p.genericName.toLowerCase().includes(inputValue.toLowerCase()) ||
    p.category.toLowerCase().includes(inputValue.toLowerCase())
  ).slice(0, 6);

  useEffect(() => {
    const onClickOutside = (e: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setShowResults(false);
        setIsFocused(false);
      }
    };
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, []);

  useEffect(() => {
    setShowResults(!!inputValue.trim() && isFocused);
  }, [inputValue, isFocused]);

  const handleProductClick = (id: string) => {
    setShowResults(false);
    setInputValue('');
    navigate(`/medication/${id}`);
  };

  return (
    <div ref={searchRef} className="relative w-full">
      <div className="relative">
        <input
          type="text"
          value={inputValue}
          onChange={e => setInputValue(e.target.value)}
          onFocus={() => setIsFocused(true)}
          placeholder="Search medications..."
          className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent outline-none transition-all text-sm"
        />
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
        {inputValue && (
          <button type="button" onClick={() => setInputValue('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      {showResults && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-xl z-[60] max-h-80 overflow-y-auto">
          {filtered.length > 0 ? (
            <div className="py-1">
              {filtered.map(med => (
                <div key={med.id} onClick={() => handleProductClick(med.id)} className="flex items-center px-4 py-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-0 gap-3">
                  <img src={med.imageUrl} alt={med.name} className="w-10 h-10 object-cover rounded-lg flex-shrink-0"
                    onError={e => { (e.target as HTMLImageElement).src = 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=100'; }} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium text-gray-900 truncate">{med.name}</p>
                      {med.requiresPrescription && <ShieldCheck className="h-3.5 w-3.5 text-blue-500 flex-shrink-0" />}
                    </div>
                    <p className="text-xs text-gray-500 truncate">{med.category} · {med.dosageForm}</p>
                  </div>
                  <span className="text-sm font-semibold text-teal-600 flex-shrink-0">${med.price.toFixed(2)}</span>
                </div>
              ))}
              <div className="px-4 py-2 bg-gray-50 border-t">
                <button onClick={() => { setShowResults(false); navigate('/medications'); }} className="text-sm text-teal-600 hover:text-teal-700 font-medium">
                  View all results →
                </button>
              </div>
            </div>
          ) : (
            <div className="px-4 py-6 text-center text-gray-500 text-sm">No medications found</div>
          )}
        </div>
      )}
    </div>
  );
};

export default NavbarSearchBar;
