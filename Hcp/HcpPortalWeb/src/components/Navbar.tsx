import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Search, Menu, X, Pill, ChevronDown } from 'lucide-react';
import NavbarSearchBar from './NavbarSearchBar';

const Navbar: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);
  const [isCatOpen, setIsCatOpen] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 10);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    setIsMenuOpen(false);
    setIsSearchOpen(false);
    setIsCatOpen(false);
  }, [location]);

  const categories = [
    { name: 'All Medications', path: '/products' },
    { name: 'Pain Relief', path: '/products?category=Pain+Relief' },
    { name: 'Antibiotics', path: '/products?category=Antibiotics' },
    { name: 'Vitamins', path: '/products?category=Vitamins' },
    { name: 'Cold & Flu', path: '/products?category=Cold+%26+Flu' },
    { name: 'Diabetes Care', path: '/products?category=Diabetes+Care' },
    { name: 'Heart Health', path: '/products?category=Heart+Health' },
  ];

  const navLink = (path: string) =>
    `px-4 py-2 rounded-lg transition-all duration-200 ${
      location.pathname === path
        ? 'bg-teal-100 text-teal-700 font-medium'
        : 'text-gray-700 hover:text-teal-700 hover:bg-gray-100'
    }`;

  return (
    <nav className={`bg-white sticky top-0 z-50 transition-all duration-300 ${isScrolled ? 'shadow-xl' : 'shadow-md'}`}>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-3 group">
            <div className="relative">
              <div className="bg-teal-600 rounded-full p-2 group-hover:bg-teal-700 transition-colors">
                <Pill className="h-6 w-6 text-white" />
              </div>
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold text-gray-900 group-hover:text-teal-700 transition-colors">
                PharmaCare
              </span>
              <span className="text-xs text-gray-500">Your Health, Our Priority</span>
            </div>
          </Link>

          {/* Desktop Search */}
          <div className="hidden lg:flex flex-1 max-w-xl mx-8">
            <NavbarSearchBar />
          </div>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center space-x-1">
            <Link to="/" className={navLink('/')}>Home</Link>

            <div className="relative">
              <button
                onClick={() => setIsCatOpen(!isCatOpen)}
                className={`px-4 py-2 rounded-lg flex items-center space-x-1 transition-all duration-200 ${
                  location.pathname === '/products'
                    ? 'bg-teal-100 text-teal-700 font-medium'
                    : 'text-gray-700 hover:text-teal-700 hover:bg-gray-100'
                }`}
              >
                <span>Medications</span>
                <ChevronDown className={`h-4 w-4 transition-transform duration-200 ${isCatOpen ? 'rotate-180' : ''}`} />
              </button>
              {isCatOpen && (
                <div className="absolute top-full left-0 mt-2 w-56 bg-white rounded-lg shadow-xl border border-gray-200 py-2 z-50">
                  {categories.map(c => (
                    <Link key={c.name} to={c.path} className="block px-4 py-2 text-gray-700 hover:text-teal-700 hover:bg-gray-50 transition-colors text-sm">
                      {c.name}
                    </Link>
                  ))}
                </div>
              )}
            </div>

            <Link to="/about" className={navLink('/about')}>About</Link>
            <Link to="/contact" className={navLink('/contact')}>Contact</Link>
          </div>

          {/* Mobile buttons */}
          <div className="md:hidden flex items-center space-x-2">
            <button onClick={() => setIsSearchOpen(!isSearchOpen)} className="p-2 text-gray-700 hover:text-teal-700 hover:bg-teal-50 rounded-lg">
              <Search className="h-6 w-6" />
            </button>
            <button onClick={() => setIsMenuOpen(!isMenuOpen)} className="p-2 text-gray-700 hover:text-teal-700 hover:bg-teal-50 rounded-lg">
              {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>
        </div>

        {isSearchOpen && (
          <div className="md:hidden py-4 border-t border-gray-200 bg-gray-50">
            <NavbarSearchBar />
          </div>
        )}

        {isMenuOpen && (
          <div className="md:hidden border-t border-gray-200 bg-white">
            <div className="px-4 py-4 space-y-2">
              <Link to="/" className="block px-4 py-3 text-gray-700 hover:text-teal-700 hover:bg-teal-50 rounded-lg font-medium">Home</Link>
              <div className="space-y-1">
                <div className="px-4 py-2 text-sm font-medium text-gray-500 uppercase tracking-wide">Medications</div>
                {categories.map(c => (
                  <Link key={c.name} to={c.path} className="block px-8 py-2 text-gray-600 hover:text-teal-700 hover:bg-teal-50 rounded-lg">
                    {c.name}
                  </Link>
                ))}
              </div>
              <Link to="/about" className="block px-4 py-3 text-gray-700 hover:text-teal-700 hover:bg-teal-50 rounded-lg font-medium">About</Link>
              <Link to="/contact" className="block px-4 py-3 text-gray-700 hover:text-teal-700 hover:bg-teal-50 rounded-lg font-medium">Contact</Link>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;
