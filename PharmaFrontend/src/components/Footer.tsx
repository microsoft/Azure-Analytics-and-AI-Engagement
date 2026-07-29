import React from 'react';
import { Link } from 'react-router-dom';
import { Pill, Mail, Phone, MapPin, Facebook, Twitter, Instagram } from 'lucide-react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="py-12 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="space-y-4">
            <Link to="/" className="flex items-center space-x-2">
              <div className="bg-teal-600 rounded-full p-1.5">
                <Pill className="h-6 w-6 text-white" />
              </div>
              <span className="text-xl font-bold">PharmaCare</span>
            </Link>
            <p className="text-gray-300 text-sm leading-relaxed">
              Your trusted online pharmacy. Quality medications, vitamins, and health products delivered to your door with care and confidentiality.
            </p>
            <div className="flex space-x-3">
              <a href="#" className="text-gray-400 hover:text-teal-400 transition-colors"><Facebook className="h-5 w-5" /></a>
              <a href="#" className="text-gray-400 hover:text-teal-400 transition-colors"><Twitter className="h-5 w-5" /></a>
              <a href="#" className="text-gray-400 hover:text-teal-400 transition-colors"><Instagram className="h-5 w-5" /></a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2 text-sm">
              {[['Home', '/'], ['All Medications', '/products'], ['About Us', '#'], ['Contact', '#'], ['Pharmacist Support', '#']].map(([label, path]) => (
                <li key={label}>
                  <Link to={path} className="text-gray-300 hover:text-white transition-colors">{label}</Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Categories */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Categories</h3>
            <ul className="space-y-2 text-sm">
              {['Pain Relief', 'Antibiotics', 'Vitamins & Supplements', 'Cold & Flu', 'Diabetes Care', 'Heart Health'].map(cat => (
                <li key={cat}>
                  <Link to={`/products?category=${encodeURIComponent(cat)}`} className="text-gray-300 hover:text-white transition-colors">{cat}</Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Contact Us</h3>
            <div className="space-y-3 text-sm">
              <div className="flex items-center space-x-3">
                <Phone className="h-4 w-4 text-teal-400 flex-shrink-0" />
                <span className="text-gray-300">1-800-PHARMACY</span>
              </div>
              <div className="flex items-center space-x-3">
                <Mail className="h-4 w-4 text-teal-400 flex-shrink-0" />
                <span className="text-gray-300">support@pharmacare.com</span>
              </div>
              <div className="flex items-start space-x-3">
                <MapPin className="h-4 w-4 text-teal-400 flex-shrink-0 mt-0.5" />
                <span className="text-gray-300">123 Health Avenue<br />Medical District, NY 10001</span>
              </div>
            </div>
          </div>
        </div>

        {/* Newsletter */}
        <div className="py-8 border-t border-gray-800">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div>
              <h3 className="text-lg font-semibold mb-1">Health Tips & Offers</h3>
              <p className="text-gray-300 text-sm">Get the latest health advice and exclusive pharmacy deals.</p>
            </div>
            <div className="flex w-full md:w-auto">
              <input type="email" placeholder="Enter your email" className="flex-1 md:w-64 px-4 py-2 bg-gray-800 border border-gray-700 rounded-l-lg focus:outline-none focus:ring-2 focus:ring-teal-500 text-sm" />
              <button className="px-5 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-r-lg font-semibold transition-colors text-sm">Subscribe</button>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="py-5 border-t border-gray-800 flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-gray-400">
          <span>© 2026 PharmaCare. All rights reserved.</span>
          <div className="flex space-x-5">
            <a href="#" className="hover:text-white transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-white transition-colors">Terms of Service</a>
            <a href="#" className="hover:text-white transition-colors">Return Policy</a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
