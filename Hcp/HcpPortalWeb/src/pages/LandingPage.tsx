import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div
      className="relative w-full min-h-screen flex flex-col items-center justify-center overflow-hidden"
      style={{
        backgroundImage: `url(https://images.pexels.com/photos/3985163/pexels-photo-3985163.jpeg?auto=compress&cs=tinysrgb&w=1920)`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }}
    >
      {/* Dark overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-950/90 via-slate-900/80 to-teal-950/70" />

      {/* Center card */}
      <div className="relative z-10 flex flex-col items-center text-center px-6 max-w-2xl">
        {/* Logo mark */}
        <div className="mb-6 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-5 shadow-2xl">
          <div className="flex items-center justify-center">
            <img src="https://dreamdemoassets.blob.core.windows.net/telco-noa/caldovalogo.png" alt="Caldova" className="h-12 w-auto rounded" />
          </div>
        </div>

        {/* Tagline */}
        <p className="text-slate-300 text-lg sm:text-xl leading-relaxed max-w-xl mb-2">
          Making <span className="text-teal-400 font-semibold">safe, effective medications</span> more accessible globally
        </p>
        <p className="text-slate-400 text-sm mb-8 max-w-lg leading-relaxed">
          A frontier pharmaceutical firm operating across the full drug lifecycle from R&D and manufacturing to commercialization and patient access.
        </p>

        {/* CTA */}
        <button
          onClick={() => navigate('/overview')}
          className="inline-flex items-center gap-2 bg-teal-600 hover:bg-teal-500 text-white font-semibold px-8 py-3.5 rounded-xl text-base transition-all hover:scale-105 shadow-lg shadow-teal-900/40"
        >
          Begin Demo <ArrowRight className="h-5 w-5" />
        </button>
      </div>

    </div>
  );
};

export default LandingPage;
