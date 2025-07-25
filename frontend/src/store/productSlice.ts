import { createSlice, PayloadAction, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';
import { Product, ProductState } from '../types';

export interface FetchProductsParams {
  search?: string;
  category?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  page?: number;
  pageSize?: number;
  append?: boolean; // If true, append to products
}

export const fetchProducts = createAsyncThunk<
  { products: Product[]; total: number; append?: boolean },
  FetchProductsParams | undefined
>(
  'products/fetchProducts',
  async (params, { getState }) => {
    // Use params or fallback to state
    const state = getState() as { products: ProductState };
    const {
      searchTerm,
      selectedCategory,
      sortBy,
      sortOrder,
      page,
      pageSize,
    } = state.products;
    const query = {
      search: params?.search ?? searchTerm,
      category: params?.category ?? (selectedCategory === 'All' ? undefined : selectedCategory),
      sortBy: params?.sortBy ?? sortBy,
      sortOrder: params?.sortOrder ?? sortOrder,
      page: params?.page ?? page,
      pageSize: params?.pageSize ?? pageSize,
    };
    const queryString = Object.entries(query)
      .filter(([, v]) => v !== undefined && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v as string)}`)
      .join('&');
    try {
      const response = await axios.get(`http://localhost:5188/api/products?${queryString}`);
      // API returns an array directly
      return {
        products: response.data.map((item: any, idx: number) => ({
          id: String(item.id),
          name: item.name,
          category: item.category,
          price: item.price,
          originalPrice: undefined, // Not provided by API
          description: item.description,
          specifications: {}, // Not provided by API
          images: [item.imageUrl],
          inStock: item.stock > 0,
          rating: 4.5, // Dummy value
          reviews: 10, // Dummy value
          featured: idx < 4 // First 4 products are featured
        })),
        total: response.data.length,
        append: params?.append,
      };
    } catch (error) {
      // Fallback to dummy data
      const dummyProducts: Product[] = [
        {
          id: '1',
          name: 'Engine Oil - Castrol GTX Motor Oil 5W-30',
          category: 'Engine Oil',
          price: 24.99,
          originalPrice: undefined,
          description: 'Premium conventional motor oil that provides superior protection against viscosity and thermal breakdown.',
          specifications: {},
          images: ['https://pensol.com/img/pxt_pride.jpg'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: true,
        },
        {
          id: '2',
          name: 'Brake Pads - ACDelco Professional',
          category: 'Brake Parts',
          price: 89.99,
          originalPrice: undefined,
          description: 'High-performance brake pads designed for superior stopping power and extended pad life.',
          specifications: {},
          images: ['https://images.pexels.com/photos/190574/pexels-photo-190574.jpeg?auto=compress&cs=tinysrgb&w=500'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: true,
        },
        {
          id: '3',
          name: 'Spark Plugs - NGK Set of 4',
          category: 'Ignition',
          price: 32.99,
          originalPrice: undefined,
          description: 'Premium spark plugs engineered for optimal performance, fuel efficiency, and long life.',
          specifications: {},
          images: ['https://images.pexels.com/photos/3807277/pexels-photo-3807277.jpeg?auto=compress&cs=tinysrgb&w=500'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: true,
        },
        {
          id: '4',
          name: 'Wiper Blades - Bosch Pair',
          category: 'Exterior',
          price: 19.99,
          originalPrice: undefined,
          description: 'All-weather wiper blades with dual rubber compounds for streak-free wiping in all conditions.',
          specifications: {},
          images: ['https://www.vtlworld.in/cdn/shop/files/81i2juQ8rWL._SL1500.jpg?v=1699696722&width=1946'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: true,
        },
        {
          id: '5',
          name: 'Transmission Fluid - Valvoline MaxLife',
          category: 'Transmission',
          price: 34.99,
          originalPrice: undefined,
          description: 'Full synthetic transmission fluid designed for high-mileage vehicles with seal conditioners.',
          specifications: {},
          images: ['https://www.mobil.com/lubricants/-/media/project/wep/mobil/mobil-row-us-1/automatic-transmission-fluid-synthetic-grouping-2020/automatic-transmission-fluid-synthetic-grouping-2020-fb-og.jpg'],
          inStock: 0 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '6',
          name: 'Tires - Michelin Defender T+H',
          category: 'Tires',
          price: 129.99,
          originalPrice: undefined,
          description: 'All-season touring tire with MaxTouch Construction for longer tread life and fuel efficiency.',
          specifications: {},
          images: ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzWjFxegUOy40rbRPk_NaWx7U9zGWOJ1PGQA&s'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '7',
          name: 'Battery - Optima RedTop',
          category: 'Electrical',
          price: 199.99,
          originalPrice: undefined,
          description: 'High-performance AGM battery with exceptional starting power and deep-cycle capability.',
          specifications: {},
          images: ['https://p.kindpng.com/picc/s/137-1372233_battery-png-image-transparent-background-exide-battery-images.png'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '8',
          name: 'Oil Filter - Mobil 1 Extended Performance',
          category: 'Engine Oil',
          price: 15.99,
          originalPrice: undefined,
          description: 'Advanced synthetic oil filter for long-lasting engine protection and performance.',
          specifications: {},
          images: ['https://www.shutterstock.com/image-illustration/motor-oil-canisters-car-filter-260nw-1180984981.jpg'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '9',
          name: 'Headlight Bulbs - Philips X-tremeVision',
          category: 'Electrical',
          price: 39.99,
          originalPrice: undefined,
          description: 'High-performance halogen headlight bulbs for maximum visibility and safety.',
          specifications: {},
          images: ['https://i.ebayimg.com/images/g/sQoAAOSwcRBkiShG/s-l1200.jpg'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '10',
          name: 'Wiper Blades - Rain-X Latitude',
          category: 'Exterior',
          price: 22.99,
          originalPrice: undefined,
          description: 'Premium wiper blades with water-repellent coating for streak-free performance.',
          specifications: {},
          images: ['https://www.boschaftermarket.com/xrm/media/images/country_specific/in/parts_11/wipers/bosch_aerotwin_universal_ap_flat_wiper_blade_res_800x450.webp'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '11',
          name: 'Brake Rotor - Bosch QuietCast Premium',
          category: 'Brake Parts',
          price: 74.99,
          originalPrice: undefined,
          description: 'Precision-balanced brake rotor for smooth, quiet braking and long life.',
          specifications: {},
          images: ['https://t3.ftcdn.net/jpg/04/91/72/40/360_F_491724099_KNhoJGIawrr9FDPkeCAeTrLlxvA7hXEk.jpg'],
          inStock: 500 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '12',
          name: 'Tires - Goodyear Assurance All-Season',
          category: 'Tires',
          price: 119.99,
          originalPrice: undefined,
          description: 'Reliable all-season tire with enhanced traction and long tread life.',
          specifications: {},
          images: ['https://media.istockphoto.com/id/994415414/photo/car-wheel-set.jpg?s=612x612&w=0&k=20&c=IyaV9jxoaGUwNU8dWLsPofSNqSgxBJlorngVC1k5gpw='],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '13',
          name: 'Spark Plug - Denso Iridium TT',
          category: 'Ignition',
          price: 13.99,
          originalPrice: undefined,
          description: 'Iridium spark plug for improved ignition efficiency and fuel economy.',
          specifications: {},
          images: ['https://www.partspro.ph/cdn/shop/products/Standard_e795d2ad-c6b3-4ec8-8f28-ea9966921ae3.jpg?v=1552880792'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
        {
          id: '14',
          name: 'Battery - DieHard Platinum AGM',
          category: 'Electrical',
          price: 229.99,
          originalPrice: undefined,
          description: 'Premium AGM battery with high cold cranking amps and long service life.',
          specifications: {},
          images: ['https://spn-sta.spinny.com/blog/20220921165654/SLI-edited-scaled.webp?compress=true&quality=80&w=732&dpr=2.6'],
          inStock: 100 > 0,
          rating: 4.5,
          reviews: 10,
          featured: false,
        },
      ];
      // Optionally filter, sort, and paginate dummy data as per query
      let filtered = dummyProducts;
      if (query.search) {
        filtered = filtered.filter(p => p.name.toLowerCase().includes((query.search as string).toLowerCase()));
      }
      if (query.category) {
        filtered = filtered.filter(p => p.category === query.category);
      }
      // Sorting (only by featured or price for demo)
      if (query.sortBy === 'price') {
        filtered = filtered.sort((a, b) => query.sortOrder === 'asc' ? a.price - b.price : b.price - a.price);
      } else if (query.sortBy === 'featured') {
        filtered = filtered.sort((a, b) => (b.featured ? 1 : 0) - (a.featured ? 1 : 0));
      }
      // Pagination
      const total = filtered.length;
      const start = ((query.page as number) - 1) * (query.pageSize as number);
      const end = start + (query.pageSize as number);
      const paginated = filtered.slice(start, end);
      return {
        products: paginated,
        total,
        append: params?.append,
      };
    }
  }
);

const initialState: ProductState = {
  products: [],
  categories: ['All', 'Break', 'Lighting', 'Wheel & Tiar', 'Engine Oil', 'Battery', 'Handle', 'Music System', 'Seat'],
  searchTerm: '',
  selectedCategory: 'All',
  loading: false,
  total: 0,
  page: 1,
  pageSize: 8,
  sortBy: 'featured',
  sortOrder: 'desc',
  hasMore: true,
};

const productSlice = createSlice({
  name: 'products',
  initialState,
  reducers: {
    setSearchTerm: (state, action: PayloadAction<string>) => {
      state.searchTerm = action.payload;
      state.page = 1;
    },
    setSelectedCategory: (state, action: PayloadAction<string>) => {
      state.selectedCategory = action.payload;
      state.page = 1;
    },
    setPage: (state, action: PayloadAction<number>) => {
      state.page = action.payload;
    },
    setPageSize: (state, action: PayloadAction<number>) => {
      state.pageSize = action.payload;
      state.page = 1;
    },
    setSortBy: (state, action: PayloadAction<string>) => {
      state.sortBy = action.payload;
      state.page = 1;
    },
    setSortOrder: (state, action: PayloadAction<'asc' | 'desc'>) => {
      state.sortOrder = action.payload;
      state.page = 1;
    },
    resetProducts: (state) => {
      state.products = [];
      state.page = 1;
      state.hasMore = true;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchProducts.pending, (state) => {
        state.loading = true;
      })
      .addCase(fetchProducts.fulfilled, (state, action) => {
        if (action.payload.append) {
          state.products = [...state.products, ...action.payload.products];
        } else {
          state.products = action.payload.products;
        }
        state.total = action.payload.total;
        state.loading = false;
        state.hasMore = action.payload.products.length === state.pageSize;
      })
      .addCase(fetchProducts.rejected, (state) => {
        state.loading = false;
      });
  },
});

export const { setSearchTerm, setSelectedCategory, setPage, setPageSize, setSortBy, setSortOrder, resetProducts } = productSlice.actions;
export default productSlice.reducer;