import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { fetchMedications } from '../store/medicationSlice';
import type { AppDispatch } from '../store/store';
import Hero from '../components/Hero';
import Categories from '../components/Categories';
import FeaturedMedications from '../components/FeaturedMedications';
import TopMedications from '../components/TopMedications';
import { Truck, ShieldCheck, HeadphonesIcon, Clock } from 'lucide-react';

const benefits = [
  {
    icon: <Truck className="w-8 h-8 text-teal-600" />,
    bg: 'bg-teal-100',
    title: 'Free Delivery',
    desc: 'Free shipping on all orders over $30. Fast and discreet delivery to your door.',
  },
  {
    icon: <ShieldCheck className="w-8 h-8 text-green-600" />,
    bg: 'bg-green-100',
    title: 'Licensed Pharmacy',
    desc: 'All medications are sourced from certified manufacturers and verified suppliers.',
  },
  {
    icon: <HeadphonesIcon className="w-8 h-8 text-blue-600" />,
    bg: 'bg-blue-100',
    title: 'Pharmacist Support',
    desc: 'Speak with a licensed pharmacist anytime for medication advice and guidance.',
  },
  {
    icon: <Clock className="w-8 h-8 text-purple-600" />,
    bg: 'bg-purple-100',
    title: '24/7 Availability',
    desc: "Order at any time. Our online pharmacy never closes — your health can't wait.",
  },
];

const HomePage: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();

  useEffect(() => {
    dispatch(fetchMedications());
  }, [dispatch]);

  return (
    <div className="min-h-screen">
      <Hero />
      <Categories />
      <FeaturedMedications />
      <TopMedications />

      <section className="py-16 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-10">Why Choose PharmaCare?</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {benefits.map(b => (
              <div key={b.title} className="text-center">
                <div className={`${b.bg} w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4`}>
                  {b.icon}
                </div>
                <h3 className="text-lg font-semibold mb-2">{b.title}</h3>
                <p className="text-gray-600 text-sm">{b.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
