import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

const slides = [
  {
    title: 'Your Trusted Pharmacy, Online',
    subtitle: 'Prescription & OTC medications delivered to your door',
    description: 'Browse thousands of medications, vitamins, and health products with fast, discreet delivery.',
    image: 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=1200',
    cta: 'Browse Medications',
    badge: 'Free Delivery Over $30',
  },
  {
    title: 'Vitamins & Supplements',
    subtitle: 'Support your immune system and wellbeing',
    description: 'High-quality vitamins, minerals, and supplements from trusted manufacturers worldwide.',
    image: 'https://images.pexels.com/photos/3683053/pexels-photo-3683053.jpeg?auto=compress&cs=tinysrgb&w=1200',
    cta: 'Shop Vitamins',
    badge: 'Up to 20% Off',
  },
  {
    title: 'Chronic Care Management',
    subtitle: 'Diabetes, heart health & more',
    description: 'Prescription medications for long-term conditions managed safely with pharmacist guidance.',
    image: 'https://images.pexels.com/photos/4386467/pexels-photo-4386467.jpeg?auto=compress&cs=tinysrgb&w=1200',
    cta: 'Explore Care',
    badge: 'Rx Available',
  },
];

const Hero: React.FC = () => {
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setCurrent(p => (p + 1) % slides.length), 5000);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="bg-gray-100 py-4 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="relative h-[240px] md:h-[280px] overflow-hidden bg-gray-900 rounded-2xl shadow-2xl">
          {slides.map((slide, i) => (
            <div
              key={i}
              className={`absolute inset-0 transition-opacity duration-1000 rounded-2xl overflow-hidden ${i === current ? 'opacity-100' : 'opacity-0'}`}
            >
              <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${slide.image})` }}>
                <div className="absolute inset-0 bg-black bg-opacity-55 rounded-2xl" />
              </div>
              <div className="relative h-full flex items-center p-4 md:p-8">
                <div className="max-w-xl">
                  <span className="inline-block bg-teal-500 text-white px-3 py-1 rounded-full text-xs font-semibold mb-3 shadow">
                    {slide.badge}
                  </span>
                  <h1 className="text-xl md:text-3xl font-bold text-white mb-2 leading-tight">{slide.title}</h1>
                  <h2 className="text-sm md:text-base text-teal-200 mb-2">{slide.subtitle}</h2>
                  <p className="text-xs md:text-sm text-gray-300 mb-4 leading-relaxed max-w-md">{slide.description}</p>
                  <Link
                    to="/products"
                    className="inline-flex items-center bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 rounded-lg font-semibold transition-all hover:scale-105 shadow-lg text-sm"
                  >
                    {slide.cta}
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </Link>
                </div>
              </div>
            </div>
          ))}


          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex space-x-1.5">
            {slides.map((_, i) => (
              <button key={i} onClick={() => setCurrent(i)} className={`w-2 h-2 rounded-full transition-all ${i === current ? 'bg-white scale-125' : 'bg-white/50 hover:bg-white/75'}`} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Hero;
