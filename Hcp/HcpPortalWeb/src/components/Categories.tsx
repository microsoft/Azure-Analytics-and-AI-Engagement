import React, { useRef, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { RootState } from '../store/store';
import { setSelectedCategory } from '../store/medicationSlice';
import {
  LayoutGrid, Pill, Shield, Apple, Thermometer,
  Activity, Heart, Smile, Plus, Leaf,
} from 'lucide-react';

const categoryIcons: Record<string, React.ReactNode> = {
  'All':              <LayoutGrid className="w-10 h-10 text-teal-500" />,
  'Pain Relief':      <Pill className="w-10 h-10 text-orange-500" />,
  'Antibiotics':      <Shield className="w-10 h-10 text-blue-500" />,
  'Vitamins':         <Apple className="w-10 h-10 text-green-500" />,
  'Cold & Flu':       <Thermometer className="w-10 h-10 text-indigo-500" />,
  'Diabetes Care':    <Activity className="w-10 h-10 text-purple-500" />,
  'Heart Health':     <Heart className="w-10 h-10 text-red-500" />,
  'Skin Care':        <Smile className="w-10 h-10 text-pink-500" />,
  'First Aid':        <Plus className="w-10 h-10 text-emerald-500" />,
  'Digestive Health': <Leaf className="w-10 h-10 text-lime-500" />,
};

const categoryColors: Record<string, string> = {
  'All':              'bg-teal-50 border-teal-200',
  'Pain Relief':      'bg-orange-50 border-orange-200',
  'Antibiotics':      'bg-blue-50 border-blue-200',
  'Vitamins':         'bg-green-50 border-green-200',
  'Cold & Flu':       'bg-indigo-50 border-indigo-200',
  'Diabetes Care':    'bg-purple-50 border-purple-200',
  'Heart Health':     'bg-red-50 border-red-200',
  'Skin Care':        'bg-pink-50 border-pink-200',
  'First Aid':        'bg-emerald-50 border-emerald-200',
  'Digestive Health': 'bg-lime-50 border-lime-200',
};

const Categories: React.FC = () => {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [showLeft, setShowLeft] = useState(false);
  const [showRight, setShowRight] = useState(true);
  const { categories } = useSelector((state: RootState) => state.medications);
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const handleClick = (category: string) => {
    dispatch(setSelectedCategory(category));
    navigate('/medications');
  };

  const scroll = (dir: 'left' | 'right') => {
    scrollRef.current?.scrollBy({ left: dir === 'left' ? -300 : 300, behavior: 'smooth' });
  };

  const handleScroll = () => {
    if (scrollRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = scrollRef.current;
      setShowLeft(scrollLeft > 0);
      setShowRight(scrollLeft < scrollWidth - clientWidth - 1);
    }
  };

  return (
    <section className="py-10 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="text-xl font-bold text-gray-900 mb-6">Browse by Category</h2>
        <div className="relative">
          {showLeft && (
            <button onClick={() => scroll('left')} className="absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-white rounded-full p-2 shadow-lg border border-gray-200 hover:bg-gray-50">
              <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
            </button>
          )}
          {showRight && (
            <button onClick={() => scroll('right')} className="absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-white rounded-full p-2 shadow-lg border border-gray-200 hover:bg-gray-50">
              <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
            </button>
          )}
          <div ref={scrollRef} onScroll={handleScroll} className="flex gap-4 overflow-x-auto px-2" style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}>
            {categories.map(cat => (
              <button
                key={cat}
                onClick={() => handleClick(cat)}
                className={`flex flex-col items-center min-w-[100px] gap-2 p-3 rounded-xl border-2 cursor-pointer transition-all hover:shadow-md hover:scale-105 ${categoryColors[cat] ?? 'bg-gray-50 border-gray-200'}`}
              >
                <div className="w-16 h-16 rounded-full bg-white flex items-center justify-center shadow-sm">
                  {categoryIcons[cat] ?? <Pill className="w-10 h-10 text-gray-400" />}
                </div>
                <span className="text-xs font-medium text-gray-800 text-center leading-tight">{cat}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default Categories;
