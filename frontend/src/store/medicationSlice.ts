import { createSlice, PayloadAction, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';
import { Medication, MedicationState } from '../types';

const API_BASE = 'http://localhost:5188/api/medications';

export interface FetchMedicationsParams {
  search?: string;
  category?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  page?: number;
  pageSize?: number;
  append?: boolean;
}

function mapApiItem(item: any, idx: number): Medication {
  return {
    id: String(item.id),
    name: item.name,
    genericName: item.genericName ?? '',
    category: item.category,
    description: item.description,
    manufacturer: item.manufacturer ?? '',
    dosageForm: item.dosageForm ?? '',
    strength: item.strength ?? '',
    price: item.price,
    stock: item.stock,
    requiresPrescription: item.requiresPrescription ?? false,
    imageUrl: item.imageUrl,
    inStock: item.stock > 0,
    featured: idx < 4,
  };
}

export const fetchMedications = createAsyncThunk<
  { products: Medication[]; total: number; append?: boolean },
  FetchMedicationsParams | undefined
>(
  'medications/fetchMedications',
  async (params, { getState }: { getState: () => unknown }) => {
    const state = getState() as { medications: MedicationState };
    const { searchTerm, selectedCategory, sortBy, sortOrder, page, pageSize } = state.medications;

    const query: Record<string, string | number | undefined> = {
      search: params?.search ?? searchTerm,
      category: params?.category ?? (selectedCategory === 'All' ? undefined : selectedCategory),
      sortBy: params?.sortBy ?? sortBy,
      sortOrder: params?.sortOrder ?? sortOrder,
      page: params?.page ?? page,
      pageSize: params?.pageSize ?? pageSize,
    };

    const qs = Object.entries(query)
      .filter(([, v]) => v !== undefined && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v as string)}`)
      .join('&');

    try {
      const res = await axios.get(`${API_BASE}?${qs}`);
      const items: Medication[] = res.data.map(mapApiItem);
      return { products: items, total: items.length, append: params?.append };
    } catch {
      return { products: fallbackMedications, total: fallbackMedications.length, append: params?.append };
    }
  }
);

export const createMedication = createAsyncThunk<Medication, Omit<Medication, 'id' | 'inStock' | 'featured'>>(
  'medications/createMedication',
  async (data) => {
    const res = await axios.post(API_BASE, data);
    return mapApiItem(res.data, 999);
  }
);

export const updateMedication = createAsyncThunk<Medication, Medication>(
  'medications/updateMedication',
  async (data) => {
    await axios.put(`${API_BASE}/${data.id}`, { ...data, id: Number(data.id) });
    return { ...data, inStock: data.stock > 0 };
  }
);

export const deleteMedication = createAsyncThunk<string, string>(
  'medications/deleteMedication',
  async (id) => {
    await axios.delete(`${API_BASE}/${id}`);
    return id;
  }
);

const initialState: MedicationState = {
  products: [],
  categories: ['All', 'Pain Relief', 'Antibiotics', 'Vitamins', 'Cold & Flu', 'Diabetes Care', 'Heart Health', 'Skin Care', 'First Aid', 'Digestive Health'],
  searchTerm: '',
  selectedCategory: 'All',
  loading: false,
  total: 0,
  page: 1,
  pageSize: 8,
  sortBy: 'id',
  sortOrder: 'asc',
  hasMore: true,
};

const medicationSlice = createSlice({
  name: 'medications',
  initialState,
  reducers: {
    setSearchTerm: (state, action: PayloadAction<string>) => { state.searchTerm = action.payload; state.page = 1; },
    setSelectedCategory: (state, action: PayloadAction<string>) => { state.selectedCategory = action.payload; state.page = 1; },
    setPage: (state, action: PayloadAction<number>) => { state.page = action.payload; },
    setPageSize: (state, action: PayloadAction<number>) => { state.pageSize = action.payload; state.page = 1; },
    setSortBy: (state, action: PayloadAction<string>) => { state.sortBy = action.payload; state.page = 1; },
    setSortOrder: (state, action: PayloadAction<'asc' | 'desc'>) => { state.sortOrder = action.payload; state.page = 1; },
    resetMedications: (state) => { state.products = []; state.page = 1; state.hasMore = true; },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMedications.pending, (state) => { state.loading = true; })
      .addCase(fetchMedications.fulfilled, (state, action) => {
        state.products = action.payload.append
          ? [...state.products, ...action.payload.products]
          : action.payload.products;
        state.total = action.payload.total;
        state.loading = false;
        state.hasMore = action.payload.products.length === state.pageSize;
      })
      .addCase(fetchMedications.rejected, (state) => { state.loading = false; })
      .addCase(createMedication.fulfilled, (state, action) => {
        state.products.unshift(action.payload);
        state.total += 1;
      })
      .addCase(updateMedication.fulfilled, (state, action) => {
        const idx = state.products.findIndex((m: Medication) => m.id === action.payload.id);
        if (idx !== -1) state.products[idx] = action.payload;
      })
      .addCase(deleteMedication.fulfilled, (state, action) => {
        state.products = state.products.filter((m: Medication) => m.id !== action.payload);
        state.total = Math.max(0, state.total - 1);
      });
  },
});

export const {
  setSearchTerm, setSelectedCategory, setPage, setPageSize,
  setSortBy, setSortOrder, resetMedications,
} = medicationSlice.actions;

export default medicationSlice.reducer;

// Keep legacy export names so existing code doesn't break
export { fetchMedications as fetchProducts, resetMedications as resetProducts };

// Fallback data when API is unavailable
const fallbackMedications: Medication[] = [
  { id: '1', name: 'Panadol Extra', genericName: 'Paracetamol 500mg', category: 'Pain Relief', description: 'Fast relief from headaches and fever.', manufacturer: 'GSK', dosageForm: 'Tablet', strength: '500mg', price: 4.99, stock: 200, requiresPrescription: false, imageUrl: 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: true },
  { id: '2', name: 'Amoxil', genericName: 'Amoxicillin', category: 'Antibiotics', description: 'Broad-spectrum antibiotic for bacterial infections.', manufacturer: 'Pfizer', dosageForm: 'Capsule', strength: '500mg', price: 12.99, stock: 150, requiresPrescription: true, imageUrl: 'https://images.pexels.com/photos/208518/pexels-photo-208518.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: true },
  { id: '3', name: 'Vitamin C', genericName: 'Ascorbic Acid', category: 'Vitamins', description: 'Immune support and antioxidant protection.', manufacturer: 'Bayer', dosageForm: 'Effervescent Tablet', strength: '1000mg', price: 7.49, stock: 300, requiresPrescription: false, imageUrl: 'https://images.pexels.com/photos/3683053/pexels-photo-3683053.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: true },
  { id: '4', name: 'Brufen', genericName: 'Ibuprofen', category: 'Pain Relief', description: 'Anti-inflammatory for pain and fever.', manufacturer: 'Abbott', dosageForm: 'Tablet', strength: '400mg', price: 5.99, stock: 175, requiresPrescription: false, imageUrl: 'https://images.pexels.com/photos/3786157/pexels-photo-3786157.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: true },
  { id: '5', name: 'Glucophage', genericName: 'Metformin', category: 'Diabetes Care', description: 'Controls blood sugar in type 2 diabetes.', manufacturer: 'Merck', dosageForm: 'Tablet', strength: '500mg', price: 9.99, stock: 100, requiresPrescription: true, imageUrl: 'https://images.pexels.com/photos/4386467/pexels-photo-4386467.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: false },
  { id: '6', name: 'Lipitor', genericName: 'Atorvastatin', category: 'Heart Health', description: 'Lowers cholesterol and protects heart health.', manufacturer: 'Pfizer', dosageForm: 'Tablet', strength: '20mg', price: 24.99, stock: 90, requiresPrescription: true, imageUrl: 'https://images.pexels.com/photos/4021775/pexels-photo-4021775.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: false },
  { id: '7', name: 'Zyrtec', genericName: 'Cetirizine', category: 'Cold & Flu', description: '24-hour non-drowsy allergy relief.', manufacturer: 'UCB', dosageForm: 'Tablet', strength: '10mg', price: 11.99, stock: 160, requiresPrescription: false, imageUrl: 'https://images.pexels.com/photos/3683038/pexels-photo-3683038.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: false },
  { id: '8', name: 'Betadine', genericName: 'Povidone-Iodine', category: 'First Aid', description: 'Topical antiseptic for wound care.', manufacturer: 'Mundipharma', dosageForm: 'Solution', strength: '10%', price: 6.99, stock: 200, requiresPrescription: false, imageUrl: 'https://images.pexels.com/photos/4386370/pexels-photo-4386370.jpeg?auto=compress&cs=tinysrgb&w=500', inStock: true, featured: false },
];
