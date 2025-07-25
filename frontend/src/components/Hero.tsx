import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ChevronLeft, ChevronRight, ShoppingBag } from 'lucide-react';

const Hero: React.FC = () => {
  const [currentSlide, setCurrentSlide] = useState(0);

  const slides = [
    {
      title: 'Premium Motor Oil Collection',
      subtitle: 'Protect your engine with top-quality oils',
      description: 'From synthetic to conventional, find the perfect oil for your vehicle',
      image: 'https://images.pexels.com/photos/279949/pexels-photo-279949.jpeg?auto=compress&cs=tinysrgb&w=1200',
      cta: 'Shop Now',
      discount: 'Up to 25% Off'
    },
    {
      title: 'High-Performance Brake Parts',
      subtitle: 'Safety first with premium brake components',
      description: 'Professional-grade brake pads, rotors, and fluids for superior stopping power',
      image: 'https://images.pexels.com/photos/190574/pexels-photo-190574.jpeg?auto=compress&cs=tinysrgb&w=1200',
      cta: 'Explore Parts',
      discount: 'Free Installation'
    },
    {
      title: 'Complete Engine Care',
      subtitle: 'Everything your engine needs',
      description: 'Air filters, spark plugs, and maintenance essentials for peak performance',
      image: 'https://images.pexels.com/photos/3807277/pexels-photo-3807277.jpeg?auto=compress&cs=tinysrgb&w=1200',
      cta: 'View Collection',
      discount: 'Bundle & Save'
    }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % slides.length);
    }, 5000);

    return () => clearInterval(timer);
  }, [slides.length]);

  const nextSlide = () => {
    setCurrentSlide((prev) => (prev + 1) % slides.length);
  };

  const prevSlide = () => {
    setCurrentSlide((prev) => (prev - 1 + slides.length) % slides.length);
  };

  return (
    <div className="bg-gray-100 py-4 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="relative h-[240px] md:h-[280px] overflow-hidden bg-gray-900 rounded-2xl shadow-2xl">
          {slides.map((slide, index) => (
            <div
              key={index}
              className={`absolute inset-0 transition-opacity duration-1000 rounded-2xl overflow-hidden ${
                index === currentSlide ? 'opacity-100' : 'opacity-0'
              }`}
            >
              <div
                className="absolute inset-0 bg-cover bg-center"
                style={{ backgroundImage: `url(${slide.image})` }}
              >
                <div className="absolute inset-0 bg-black bg-opacity-50 rounded-2xl" />
              </div>
              
              <div className="relative h-full flex items-center p-4 md:p-6">
                <div className="max-w-xl">
                  <div className="mb-2">
                    <span className="inline-block bg-orange-500 text-white px-2 py-1 rounded-full text-xs font-semibold shadow-lg">
                      {slide.discount}
                    </span>
                  </div>
                  <h1 className="text-xl md:text-3xl font-bold text-white mb-2 leading-tight">
                    {slide.title}
                  </h1>
                  <h2 className="text-sm md:text-lg text-gray-200 mb-2">
                    {slide.subtitle}
                  </h2>
                  <p className="text-xs md:text-sm text-gray-300 mb-4 leading-relaxed max-w-md">
                    {slide.description}
                  </p>
                  <Link
                    to="/products"
                    className="inline-flex items-center bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-semibold transition-all transform hover:scale-105 duration-300 shadow-lg hover:shadow-xl text-sm"
                  >
                    <ShoppingBag className="mr-2 h-4 w-4" />
                    {slide.cta}
                  </Link>
                </div>
              </div>
            </div>
          ))}

          {/* Navigation Arrows */}
          <button
            onClick={prevSlide}
            className="absolute left-3 top-1/2 transform -translate-y-1/2 bg-white bg-opacity-20 hover:bg-opacity-30 text-white p-1.5 rounded-full transition-all backdrop-blur-sm shadow-lg"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button
            onClick={nextSlide}
            className="absolute right-3 top-1/2 transform -translate-y-1/2 bg-white bg-opacity-20 hover:bg-opacity-30 text-white p-1.5 rounded-full transition-all backdrop-blur-sm shadow-lg"
          >
            <ChevronRight className="h-4 w-4" />
          </button>

          {/* Dots Indicator */}
          <div className="absolute bottom-3 left-1/2 transform -translate-x-1/2 flex space-x-1.5">
            {slides.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentSlide(index)}
                className={`w-2 h-2 rounded-full transition-all shadow-lg ${
                  index === currentSlide ? 'bg-white scale-125' : 'bg-white bg-opacity-50 hover:bg-opacity-75'
                }`}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Hero;