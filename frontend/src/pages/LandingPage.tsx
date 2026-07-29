import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Globe, Award, Pill } from 'lucide-react';

const stats = [
  { value: '30+',    label: 'Years of Excellence' },
  { value: '100+',   label: 'Countries Served'    },
  { value: '15,000+',label: 'Medications Tracked' },
  { value: 'AI-First',label: 'Operations Model'   },
];

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

      {/* Top-right label */}
      <div className="absolute top-5 right-6 z-10">
        <span className="text-xs text-slate-400 font-medium tracking-widest uppercase">Updated Jun 2026</span>
      </div>

      {/* Center card */}
      <div className="relative z-10 flex flex-col items-center text-center px-6 max-w-2xl">
        {/* Logo mark */}
        <div className="mb-6 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-5 shadow-2xl">
          <div className="flex items-center justify-center gap-4">
            <div className="bg-teal-600 rounded-xl p-3">
              <Pill className="h-10 w-10 text-white" />
            </div>
            <div className="text-left">
              <h1 className="text-4xl sm:text-5xl font-extrabold text-white tracking-tight leading-none">
                PharmaCare
              </h1>
              <p className="text-teal-400 text-base font-semibold tracking-wide mt-1">AI-Powered Pharmaceutical Operations</p>
            </div>
          </div>
        </div>

        {/* Tagline */}
        <p className="text-slate-300 text-lg sm:text-xl leading-relaxed max-w-xl mb-2">
          Making <span className="text-teal-400 font-semibold">safe, effective medications</span> more accessible globally
        </p>
        <p className="text-slate-400 text-sm mb-8 max-w-lg leading-relaxed">
          A frontier pharmaceutical firm operating across the full drug lifecycle — from R&D and manufacturing to commercialization and patient access.
        </p>

        {/* CTA */}
        <button
          onClick={() => navigate('/overview')}
          className="inline-flex items-center gap-2 bg-teal-600 hover:bg-teal-500 text-white font-semibold px-8 py-3.5 rounded-xl text-base transition-all hover:scale-105 shadow-lg shadow-teal-900/40"
        >
          Begin Demo <ArrowRight className="h-5 w-5" />
        </button>
      </div>

      {/* Stats bar */}
      <div className="absolute bottom-0 left-0 right-0 z-10 bg-black/40 backdrop-blur-sm border-t border-white/10">
        <div className="max-w-4xl mx-auto grid grid-cols-2 sm:grid-cols-4 divide-x divide-white/10">
          {stats.map(s => (
            <div key={s.label} className="px-6 py-4 text-center">
              <p className="text-teal-400 text-xl font-bold">{s.value}</p>
              <p className="text-slate-400 text-xs mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default LandingPage;
