import React, { useState, useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Link, useNavigate } from 'react-router-dom';
import { Search, X, ShieldCheck } from 'lucide-react';
import { RootState } from '../store/store';
import { setSearchTerm } from '../store/medicationSlice';

const SearchBar: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const searchTerm = useSelector((state: RootState) => state.medications.searchTerm);
  const medications = useSelector((state: RootState) => state.medications.products);
  const [showResults, setShowResults] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  const filtered = medications.filter(m =>
    m.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.genericName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.category.toLowerCase().includes(searchTerm.toLowerCase())
  ).slice(0, 6);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setShowResults(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  useEffect(() => {
    setShowResults(!!searchTerm.trim() && isFocused);
  }, [searchTerm, isFocused]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchTerm.trim()) { setShowResults(false); navigate('/medications'); }
  };

  return (
    <div ref={searchRef} className="relative w-full">
      <form onSubmit={handleSearch}>
        <div className="relative">
          <input
            type="text"
            value={searchTerm}
            onChange={e => dispatch(setSearchTerm(e.target.value))}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            placeholder="Search medications..."
            className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent outline-none transition-all text-sm"
          />
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          {searchTerm && (
            <button type="button" onClick={() => dispatch(setSearchTerm(''))} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </form>

      {showResults && searchTerm.trim() && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-xl z-50 max-h-80 overflow-y-auto">
          {filtered.length > 0 ? (
            <div className="py-1">
              {filtered.map(med => (
                <Link key={med.id} to={`/medication/${med.id}`} onClick={() => { setShowResults(false); dispatch(setSearchTerm('')); }}
                  className="flex items-center px-4 py-3 hover:bg-gray-50 border-b border-gray-100 last:border-0 gap-3">
                  <img src={med.imageUrl} alt={med.name} className="w-10 h-10 object-cover rounded-lg flex-shrink-0"
                    onError={e => { (e.target as HTMLImageElement).src = 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=100'; }} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1">
                      <p className="text-sm font-medium text-gray-900 truncate">{med.name}</p>
                      {med.requiresPrescription && <ShieldCheck className="h-3.5 w-3.5 text-blue-500 flex-shrink-0" />}
                    </div>
                    <p className="text-xs text-gray-500 truncate">{med.category} · {med.dosageForm}</p>
                  </div>
                  <span className="text-sm font-semibold text-teal-600 flex-shrink-0">${med.price.toFixed(2)}</span>
                </Link>
              ))}
              <div className="px-4 py-2 bg-gray-50 border-t">
                <Link to="/medications" onClick={() => setShowResults(false)} className="text-sm text-teal-600 hover:text-teal-700 font-medium">
                  View all results ({filtered.length}) →
                </Link>
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

export default SearchBar;
