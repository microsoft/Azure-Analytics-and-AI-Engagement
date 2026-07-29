export interface Medication {
  id: string;
  name: string;
  genericName: string;
  category: string;
  description: string;
  manufacturer: string;
  dosageForm: string;
  strength: string;
  price: number;
  stock: number;
  requiresPrescription: boolean;
  imageUrl: string;
  inStock: boolean;
  featured?: boolean;
}

// Keep Product as alias so imports don't break
export type Product = Medication;

export interface CartItem {
  product: Medication;
  quantity: number;
}

export interface CartState {
  items: CartItem[];
  total: number;
  itemCount: number;
}

export interface MedicationState {
  products: Medication[];
  categories: string[];
  searchTerm: string;
  selectedCategory: string;
  loading: boolean;
  total: number;
  page: number;
  pageSize: number;
  sortBy: string;
  sortOrder: 'asc' | 'desc';
  hasMore: boolean;
}

export type ProductState = MedicationState;
