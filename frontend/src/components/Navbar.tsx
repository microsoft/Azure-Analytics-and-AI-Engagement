import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { 
  Search, 
  ShoppingCart, 
  Menu, 
  X, 
  Car, 
  ChevronDown, 
  User, 
  Heart, 
  Phone,
  MapPin,
  Clock
} from 'lucide-react';
import { RootState } from '../store/store';
import NavbarSearchBar from './NavbarSearchBar';

const Navbar: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null);
  const cartItemCount = useSelector((state: RootState) => state.cart.itemCount);
  const navigate = useNavigate();
  const location = useLocation();

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu when route changes
  useEffect(() => {
    setIsMenuOpen(false);
    setIsSearchOpen(false);
  }, [location]);

  const toggleMenu = () => setIsMenuOpen(!isMenuOpen);
  const toggleSearch = () => setIsSearchOpen(!isSearchOpen);

  const handleDropdownToggle = (dropdown: string) => {
    setActiveDropdown(activeDropdown === dropdown ? null : dropdown);
  };

  const categories = [
    { name: 'All Products', path: '/products' },
    { name: 'Zava Products', path: '/products?category=Zava' }
  ];

  // Determine selected category from URL
  const getSelectedCategoryName = () => {
    if (location.pathname === '/products') {
      const params = new URLSearchParams(location.search);
      const category = params.get('category');
      if (category === 'Zava') return 'Zava Products';
      return 'All Products';
    }
    return null;
  };
  const selectedCategoryName = getSelectedCategoryName();

  return (
    <>
      {/* Main navbar */}
      <nav className={`bg-white shadow-lg sticky top-0 z-50 transition-all duration-300 ${
        isScrolled ? 'shadow-xl' : 'shadow-md'
      }`}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            {/* Logo */}
            <Link to="/" className="flex items-center space-x-3 group">
              <div className="relative">
                <Car className="h-10 w-10 text-blue-600 group-hover:text-blue-700 transition-colors" />
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-orange-500 rounded-full animate-pulse"></div>
              </div>
              <div className="flex flex-col">
                <span className="text-xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">
                  Parts Unlimited
                </span>
                <span className="text-xs text-gray-500">Premium Auto Parts</span>
              </div>
            </Link>

            {/* Desktop Search */}
            <div className="hidden lg:flex flex-1 max-w-xl mx-8 relative">
              <NavbarSearchBar />
            </div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-1">
              <Link 
                to="/" 
                className={`px-4 py-2 rounded-lg transition-all duration-200 ${
                  location.pathname === '/' 
                    ? 'bg-blue-100 text-blue-700 font-medium' 
                    : 'text-gray-700 hover:text-blue-700 hover:bg-gray-100'
                }`}
              >
                Home
              </Link>
              
              {/* Products dropdown */}
              <div className="relative">
                <button
                  onClick={() => handleDropdownToggle('products')}
                  className={`px-4 py-2 rounded-lg transition-all duration-200 flex items-center space-x-1 ${
                    location.pathname === '/products' 
                      ? 'bg-blue-100 text-blue-700 font-medium' 
                      : 'text-gray-700 hover:text-blue-700 hover:bg-gray-100'
                  }`}
                >
                  <span>{selectedCategoryName || 'Products'}</span>
                  <ChevronDown className={`h-4 w-4 transition-transform duration-200 ${
                    activeDropdown === 'products' ? 'rotate-180' : ''
                  }`} />
                </button>
                
                {activeDropdown === 'products' && (
                  <div className="absolute top-full left-0 mt-2 w-64 bg-white rounded-lg shadow-xl border border-gray-200 py-2 z-50">
                    {categories.map((category) => (
                      <Link
                        key={category.name}
                        to={category.path}
                        className="block px-4 py-2 text-gray-700 hover:text-blue-700 hover:bg-gray-50 transition-colors"
                        onClick={() => setActiveDropdown(null)}
                      >
                        {category.name}
                      </Link>
                    ))}
                  </div>
                )}
              </div>

              <Link 
                to="/about" 
                className="px-4 py-2 rounded-lg text-gray-700 hover:text-blue-700 hover:bg-gray-100 transition-all duration-200"
              >
                About
              </Link>
              
              <Link 
                to="/contact" 
                className="px-4 py-2 rounded-lg text-gray-700 hover:text-blue-700 hover:bg-gray-100 transition-all duration-200"
              >
                Contact
              </Link>
            </div>

            {/* Desktop Actions */}
            <div className="hidden md:flex items-center space-x-3">
              <Link 
                to="/wishlist" 
                className="p-2 text-gray-700 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all duration-200"
              >
                <Heart className="h-6 w-6" />
              </Link>
              
              <Link 
                to="/cart" 
                className="relative p-2 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
              >
                <ShoppingCart className="h-6 w-6" />
                {cartItemCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-orange-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-medium animate-bounce">
                    {cartItemCount}
                  </span>
                )}
              </Link>
              
              <Link 
                to="/account" 
                className="p-2 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
              >
                <User className="h-6 w-6" />
              </Link>
            </div>

            {/* Mobile menu and search buttons */}
            <div className="md:hidden flex items-center space-x-2">
              <button
                onClick={toggleSearch}
                className="p-2 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
              >
                <Search className="h-6 w-6" />
              </button>
              
              <Link 
                to="/cart" 
                className="relative p-2 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
              >
                <ShoppingCart className="h-6 w-6" />
                {cartItemCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-orange-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-medium">
                    {cartItemCount}
                  </span>
                )}
              </Link>
              
              <button
                onClick={toggleMenu}
                className="p-2 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
              >
                {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
              </button>
            </div>
          </div>

          {/* Mobile Search */}
          {isSearchOpen && (
            <div className="md:hidden py-4 border-t border-gray-200 bg-gray-50">
              <NavbarSearchBar />
            </div>
          )}

          {/* Mobile Menu */}
          {isMenuOpen && (
            <div className="md:hidden border-t border-gray-200 bg-white">
              <div className="px-4 py-4 space-y-2">
                <Link
                  to="/"
                  className="block px-4 py-3 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200 font-medium"
                >
                  Home
                </Link>
                
                <div className="space-y-2">
                  <div className="px-4 py-2 text-sm font-medium text-gray-500 uppercase tracking-wide">
                    Products
                  </div>
                  {categories.map((category) => (
                    <Link
                      key={category.name}
                      to={category.path}
                      className="block px-8 py-2 text-gray-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
                    >
                      {category.name}
                    </Link>
                  ))}
                </div>
                
                <Link
                  to="/about"
                  className="block px-4 py-3 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200 font-medium"
                >
                  About
                </Link>
                
                <Link
                  to="/contact"
                  className="block px-4 py-3 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200 font-medium"
                >
                  Contact
                </Link>
                
                <div className="pt-4 border-t border-gray-200">
                  <Link
                    to="/wishlist"
                    className="flex items-center px-4 py-3 text-gray-700 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all duration-200"
                  >
                    <Heart className="h-5 w-5 mr-3" />
                    Wishlist
                  </Link>
                  
                  <Link
                    to="/account"
                    className="flex items-center px-4 py-3 text-gray-700 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-all duration-200"
                  >
                    <User className="h-5 w-5 mr-3" />
                    Account
                  </Link>
                </div>
              </div>
            </div>
          )}
        </div>
      </nav>
    </>
  );
};

export default Navbar;