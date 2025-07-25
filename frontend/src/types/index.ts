export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  originalPrice?: number;
  description: string;
  specifications: Record<string, string>;
  images: string[];
  inStock: boolean;
  rating: number;
  reviews: number;
  featured?: boolean;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface CartState {
  items: CartItem[];
  total: number;
  itemCount: number;
}

export interface ProductState {
  products: Product[];
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