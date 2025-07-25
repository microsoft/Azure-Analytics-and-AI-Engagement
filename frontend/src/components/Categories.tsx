import React, { useRef, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { RootState } from '../store/store';
import { setSelectedCategory } from '../store/productSlice';
import breakImg from '../assets/break.jpg';
import lightImg from '../assets/light.png';
import tiarImg from '../assets/tiar.avif';
import oilImg from '../assets/oil.png';
import batteryImg from '../assets/battery.jpg';
import handleImg from '../assets/handle.jpg';
import musicImg from '../assets/music.webp';
import seatImg from '../assets/seat.png';
import { LayoutGrid } from 'lucide-react';

const Categories: React.FC = () => {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const { categories } = useSelector((state: RootState) => state.products);
  const [showLeftButton, setShowLeftButton] = useState(false);
  const [showRightButton, setShowRightButton] = useState(true);
  const dispatch = useDispatch();
  const navigate = useNavigate();

  // More relevant automotive parts images
  const categoryImages: Record<string, string> = {
    'All': batteryImg,
    'Break': breakImg,
    'Lighting': lightImg,
    'Wheel & Tiar': tiarImg,
    'Engine Oil': oilImg,
    'Battery': batteryImg,
    'Handle': handleImg,
    'Music System': musicImg,
    'Seat': seatImg,
  };

  const handleCategoryClick = (category: string) => {
    dispatch(setSelectedCategory(category));
    navigate('/products');
  };

  const scroll = (direction: 'left' | 'right') => {
    if (scrollContainerRef.current) {
      const scrollAmount = 300; // Adjust scroll amount as needed
      const newScrollLeft = scrollContainerRef.current.scrollLeft + (direction === 'left' ? -scrollAmount : scrollAmount);
      
      scrollContainerRef.current.scrollTo({
        left: newScrollLeft,
        behavior: 'smooth'
      });
    }
  };

  const handleScroll = () => {
    if (scrollContainerRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;
      setShowLeftButton(scrollLeft > 0);
      setShowRightButton(scrollLeft < scrollWidth - clientWidth - 1);
    }
  };

  return (
    <section className="py-12 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="relative">
          {/* Left scroll button */}
          {showLeftButton && (
            <button
              onClick={() => scroll('left')}
              className="absolute left-0 top-1/2 transform -translate-y-1/2 z-10 bg-white rounded-full p-3 shadow-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              aria-label="Scroll left"
            >
              <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
          )}

          {/* Right scroll button */}
          {showRightButton && (
            <button
              onClick={() => scroll('right')}
              className="absolute right-0 top-1/2 transform -translate-y-1/2 z-10 bg-white rounded-full p-3 shadow-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              aria-label="Scroll right"
            >
              <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          )}

          {/* Scrollable categories container */}
          <div
            ref={scrollContainerRef}
            onScroll={handleScroll}
            className="flex gap-6 overflow-x-auto scrollbar-hide px-4"
            style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
          >
            {categories.map((category) => (
              <div 
                key={category} 
                className="flex flex-col items-center min-w-[120px] group cursor-pointer"
                onClick={() => handleCategoryClick(category)}
              >
                <div className="relative mb-3">
                  <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-white shadow-lg group-hover:shadow-xl transition-shadow flex items-center justify-center bg-white">
                    {category === 'All' ? (
                      <LayoutGrid className="w-12 h-12 text-blue-500" />
                    ) : (
                      <img
                        src={categoryImages[category] || 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=150&h=150&fit=crop&crop=center'}
                        alt={category}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.src = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=150&h=150&fit=crop&crop=center';
                        }}
                      />
                    )}
                  </div>
                  <div className="absolute inset-0 rounded-full bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all duration-200"></div>
                </div>
                <h3 className="text-sm font-medium text-gray-900 text-center group-hover:text-blue-600 transition-colors">
                  {category}
                </h3>
              </div>
            ))}
          </div>
        </div>
      </div>

      <style>{`
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
      `}</style>
    </section>
  );
};

export default Categories; 