import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useLocation } from 'react-router-dom';
import {
  fetchMedications, setSortBy, setSortOrder,
  setSelectedCategory, createMedication, setSearchTerm,
} from '../store/medicationSlice';
import type { AppDispatch } from '../store/store';
import { RootState } from '../store/store';
import MedicationCard from '../components/MedicationCard';
import {
  Search, SlidersHorizontal, Plus, X,
  ChevronLeft, ChevronRight, FlaskConical,
} from 'lucide-react';

const PAGE_SIZE = 8;

const DOSAGE_FORMS = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Solution', 'Drops', 'Spray', 'Patch', 'Effervescent Tablet', 'Soft Gel', 'Powder', 'Inhaler'];
const CATEGORIES   = ['Pain Relief', 'Antibiotics', 'Vitamins', 'Cold & Flu', 'Diabetes Care', 'Heart Health', 'Skin Care', 'First Aid', 'Digestive Health'];

// ── Add Medication Modal ──────────────────────────────────────────────────────

const emptyForm = () => ({
  name: '', genericName: '', category: 'Pain Relief', description: '',
  manufacturer: '', dosageForm: 'Tablet', strength: '', price: 0,
  stock: 0, requiresPrescription: false, imageUrl: '',
});

interface ModalProps { onClose: () => void; onSave: (data: any) => void; }

const AddMedicationModal: React.FC<ModalProps> = ({ onClose, onSave }) => {
  const [form, setForm] = useState<any>(emptyForm());
  const set = (f: string, v: any) => setForm((prev: any) => ({ ...prev, [f]: v }));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) { alert('Name is required.'); return; }
    onSave(form);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-teal-600 mb-0.5">Admin</p>
            <h2 className="text-xl font-bold text-slate-900">Add New Medication</h2>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 rounded-lg p-1 hover:bg-gray-100">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="sm:col-span-2">
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Brand Name *</label>
            <input value={form.name} onChange={e => set('name', e.target.value)} required placeholder="e.g. Panadol Extra" className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div className="sm:col-span-2">
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Generic Name</label>
            <input value={form.genericName} onChange={e => set('genericName', e.target.value)} placeholder="e.g. Paracetamol" className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Category</label>
            <select value={form.category} onChange={e => set('category', e.target.value)} className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors">
              {CATEGORIES.map(c => <option key={c}>{c}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Dosage Form</label>
            <select value={form.dosageForm} onChange={e => set('dosageForm', e.target.value)} className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors">
              {DOSAGE_FORMS.map(d => <option key={d}>{d}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Manufacturer</label>
            <input value={form.manufacturer} onChange={e => set('manufacturer', e.target.value)} placeholder="e.g. GSK" className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Strength</label>
            <input value={form.strength} onChange={e => set('strength', e.target.value)} placeholder="e.g. 500mg" className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Price ($) *</label>
            <input type="number" min={0} step="0.01" value={form.price} onChange={e => set('price', parseFloat(e.target.value) || 0)} required className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Stock</label>
            <input type="number" min={0} value={form.stock} onChange={e => set('stock', parseInt(e.target.value) || 0)} className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div className="sm:col-span-2">
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Image URL</label>
            <input value={form.imageUrl} onChange={e => set('imageUrl', e.target.value)} placeholder="https://..." className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors" />
          </div>
          <div className="sm:col-span-2">
            <label className="block text-sm font-semibold text-slate-700 mb-1.5">Description</label>
            <textarea value={form.description} onChange={e => set('description', e.target.value)} rows={3} className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 focus:ring-2 focus:ring-teal-500 outline-none text-sm bg-gray-50 focus:bg-white transition-colors resize-none" />
          </div>
          <div className="sm:col-span-2 flex items-center gap-2.5">
            <input type="checkbox" id="rx" checked={form.requiresPrescription} onChange={e => set('requiresPrescription', e.target.checked)} className="accent-teal-600 w-4 h-4 rounded" />
            <label htmlFor="rx" className="text-sm text-slate-600 font-medium">Requires Prescription (Rx)</label>
          </div>
          <div className="sm:col-span-2 flex justify-end gap-3 pt-2 border-t border-gray-100">
            <button type="button" onClick={onClose} className="px-5 py-2.5 border border-gray-200 rounded-xl text-slate-600 hover:bg-gray-50 text-sm font-semibold transition-colors">Cancel</button>
            <button type="submit" className="px-6 py-2.5 bg-teal-600 hover:bg-teal-700 text-white rounded-xl text-sm font-semibold transition-colors shadow-sm">Add Medication</button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ── Pagination ────────────────────────────────────────────────────────────────

interface PaginationProps { currentPage: number; totalPages: number; total: number; onChange: (p: number) => void; }

const Pagination: React.FC<PaginationProps> = ({ currentPage, totalPages, total, onChange }) => {
  if (totalPages <= 1) return null;
  const pages: (number | '…')[] = [];
  if (totalPages <= 7) {
    for (let i = 1; i <= totalPages; i++) pages.push(i);
  } else {
    pages.push(1);
    if (currentPage > 3) pages.push('…');
    for (let i = Math.max(2, currentPage - 1); i <= Math.min(totalPages - 1, currentPage + 1); i++) pages.push(i);
    if (currentPage < totalPages - 2) pages.push('…');
    pages.push(totalPages);
  }
  const start = (currentPage - 1) * PAGE_SIZE + 1;
  const end   = Math.min(currentPage * PAGE_SIZE, total);

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-6 pb-2 mt-6 border-t border-gray-100">
      <p className="text-sm text-slate-500">
        Showing <span className="font-semibold text-slate-700">{start}–{end}</span> of <span className="font-semibold text-slate-700">{total}</span> medications
      </p>
      <div className="flex items-center gap-1">
        <button onClick={() => onChange(currentPage - 1)} disabled={currentPage === 1}
          className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-gray-200 text-sm text-slate-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
          <ChevronLeft className="h-4 w-4" /> Prev
        </button>
        {pages.map((p, i) =>
          p === '…' ? <span key={`e${i}`} className="px-2 text-slate-400">…</span> : (
            <button key={p} onClick={() => onChange(p as number)}
              className={`w-9 h-9 rounded-lg text-sm font-semibold transition-colors ${p === currentPage ? 'bg-teal-600 text-white shadow-sm' : 'border border-gray-200 text-slate-600 hover:bg-gray-50'}`}>
              {p}
            </button>
          )
        )}
        <button onClick={() => onChange(currentPage + 1)} disabled={currentPage === totalPages}
          className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-gray-200 text-sm text-slate-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
          Next <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

// ── Page ──────────────────────────────────────────────────────────────────────

const sortOptions = [
  { label: 'Default',            value: 'default'   },
  { label: 'Price: Low → High',  value: 'priceLow'  },
  { label: 'Price: High → Low',  value: 'priceHigh' },
  { label: 'Name A–Z',           value: 'nameAsc'   },
];

const MedicationsPage: React.FC = () => {
  const dispatch    = useDispatch<AppDispatch>();
  const location    = useLocation();
  const { categories, selectedCategory, searchTerm, sortBy, sortOrder, products, loading } =
    useSelector((state: RootState) => state.medications);

  const [currentPage, setCurrentPage] = useState(1);
  const [modalOpen,   setModalOpen]   = useState(false);
  const [localSearch, setLocalSearch] = useState(searchTerm);

  // Sync category from URL
  useEffect(() => {
    const cat = new URLSearchParams(location.search).get('category');
    dispatch(setSelectedCategory(cat ?? 'All'));
  }, [location.search, dispatch]);

  // Fetch on filter change
  useEffect(() => {
    dispatch(fetchMedications({ search: searchTerm, category: selectedCategory === 'All' ? undefined : selectedCategory, sortBy, sortOrder, pageSize: 1000 }));
    setCurrentPage(1);
  }, [dispatch, searchTerm, selectedCategory, sortBy, sortOrder]);

  // Debounce search input
  useEffect(() => {
    const t = setTimeout(() => dispatch(setSearchTerm(localSearch)), 300);
    return () => clearTimeout(t);
  }, [localSearch, dispatch]);

  const totalPages = Math.ceil(products.length / PAGE_SIZE);
  const pageItems  = products.slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);

  const handleSortChange = (v: string) => {
    if      (v === 'priceLow')  { dispatch(setSortBy('price')); dispatch(setSortOrder('asc'));  }
    else if (v === 'priceHigh') { dispatch(setSortBy('price')); dispatch(setSortOrder('desc')); }
    else if (v === 'nameAsc')   { dispatch(setSortBy('name'));  dispatch(setSortOrder('asc'));  }
    else                        { dispatch(setSortBy('id'));    dispatch(setSortOrder('asc'));  }
  };

  const currentSortValue = sortBy === 'price' ? (sortOrder === 'asc' ? 'priceLow' : 'priceHigh') : sortBy === 'name' ? 'nameAsc' : 'default';

  const handlePageChange = (p: number) => { setCurrentPage(p); window.scrollTo({ top: 0, behavior: 'smooth' }); };

  return (
    <div className="min-h-screen bg-[#f5f7fa]">

      {/* ── Search + Sort toolbar ── */}
      <div className="bg-white border-b border-gray-200 px-8 lg:px-10 py-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input
              type="text"
              value={localSearch}
              onChange={e => setLocalSearch(e.target.value)}
              placeholder="Search by name, generic name, category…"
              className="w-full pl-10 pr-10 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-slate-800 placeholder-slate-400 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500 focus:bg-white transition-all"
            />
            {localSearch && (
              <button onClick={() => { setLocalSearch(''); dispatch(setSearchTerm('')); }} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
          <div className="flex items-center gap-2">
            <SlidersHorizontal className="h-4 w-4 text-slate-400 flex-shrink-0" />
            <select
              value={currentSortValue}
              onChange={e => handleSortChange(e.target.value)}
              className="bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-700 focus:ring-2 focus:ring-teal-500 outline-none cursor-pointer"
            >
              {sortOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
        </div>
      </div>

      {/* ── Content ── */}
      <div className="max-w-7xl mx-auto px-6 lg:px-10 py-8 flex flex-col lg:flex-row gap-7">

        {/* Sidebar filters */}
        <aside className="lg:w-56 flex-shrink-0 space-y-4">
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
            <p className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-3">Category</p>
            <div className="space-y-1">
              {categories.map(cat => (
                <button
                  key={cat}
                  onClick={() => dispatch(setSelectedCategory(cat))}
                  className={`w-full text-left px-3 py-2 rounded-lg text-[13px] font-medium transition-colors ${
                    selectedCategory === cat
                      ? 'bg-teal-50 text-teal-700 border border-teal-200'
                      : 'text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
            <p className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-3">Prescription</p>
            <div className="space-y-2 text-[13px]">
              {['All', 'OTC Only', 'Rx Required'].map(opt => (
                <label key={opt} className="flex items-center gap-2.5 cursor-pointer text-slate-600 hover:text-slate-800">
                  <input type="radio" name="rx" defaultChecked={opt === 'All'} className="accent-teal-600" />
                  {opt}
                </label>
              ))}
            </div>
          </div>

          {/* Quick stats */}
          <div className="bg-[#0b1120] rounded-2xl p-5 text-white">
            <div className="flex items-center gap-2 mb-3">
              <FlaskConical className="h-4 w-4 text-teal-400" />
              <p className="text-xs font-bold uppercase tracking-widest text-teal-400">Catalog Stats</p>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-[13px]">
                <span className="text-slate-400">Total</span>
                <span className="font-bold">{products.length}</span>
              </div>
              <div className="flex justify-between text-[13px]">
                <span className="text-slate-400">In Stock</span>
                <span className="font-bold text-emerald-400">{products.filter(p => p.inStock).length}</span>
              </div>
              <div className="flex justify-between text-[13px]">
                <span className="text-slate-400">Rx Only</span>
                <span className="font-bold text-blue-400">{products.filter(p => p.requiresPrescription).length}</span>
              </div>
            </div>
          </div>
        </aside>

        {/* Grid */}
        <div className="flex-1 min-w-0">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="text-center">
                <div className="w-10 h-10 border-2 border-teal-600 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
                <p className="text-slate-500 text-sm">Loading medications…</p>
              </div>
            </div>
          ) : pageItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <FlaskConical className="h-12 w-12 text-slate-300 mb-3" />
              <p className="text-slate-500 font-medium">No medications found</p>
              <p className="text-slate-400 text-sm mt-1">Try adjusting your search or filters</p>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                {pageItems.map(med => (
                  <MedicationCard key={med.id} product={med} />
                ))}
              </div>
              <Pagination currentPage={currentPage} totalPages={totalPages} total={products.length} onChange={handlePageChange} />
            </>
          )}
        </div>
      </div>

      {modalOpen && (
        <AddMedicationModal
          onClose={() => setModalOpen(false)}
          onSave={data => dispatch(createMedication(data))}
        />
      )}
    </div>
  );
};

export default MedicationsPage;
