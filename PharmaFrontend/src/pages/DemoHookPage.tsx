import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, ArrowLeft } from 'lucide-react';

const hooks = [
  {
    num: 'One',
    text: `When we encounter PharmaCare, they are reacting to the breaking news that a direct competitor has announced a new product launch in a therapeutic category where the company already has a leading position, offering a longer-lasting injection with fewer doses and an earlier market entry timeline.`,
  },
  {
    num: 'Two',
    text: `With the announcement, the expected time-to-market advantage is reduced, with the competitor expected to launch ahead of PharmaCare's next-generation product, creating immediate pressure and forcing the company to adjust its operations in real time — but its current systems aren't equipped to respond at that pace.`,
  },
  {
    num: 'Three',
    text: `This forces a critical leadership question: Can PharmaCare respond fast enough to close the timing gap and defend market share, without introducing operational or regulatory risk?`,
  },
  {
    num: 'Four',
    text: `With this backdrop, the team moves quickly to assemble a cross-functional team. They pull together data across the business, identify where they can unlock operational systems to deliver at speed and scale — with supply chain and capacity emerging as the primary constraint — and define requirements for real-time demand response with fully autonomous agents within defined governance boundaries.`,
  },
  {
    num: 'Five',
    text: `This kicks off the remaining demos, which explore how they build, secure, govern, operate, and optimize this AI-first supply chain system. We see: increase batch release velocity, capture early market share, reduce time-to-first-prescription, maintain continuous GMP compliance, sustain competitive market leadership, and accelerate payor and formulary readiness.`,
  },
];

const DemoHookPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#0b1120] flex flex-col">
      {/* Header */}
      <div className="px-8 lg:px-16 pt-14 pb-10 max-w-6xl mx-auto w-full">
        <p className="text-xs font-bold uppercase tracking-widest text-teal-500 mb-3">Demo Scenario</p>
        <h1 className="text-4xl lg:text-5xl font-extrabold text-white leading-tight">
          The Demo Hook
        </h1>
      </div>

      {/* Grid of hooks */}
      <div className="flex-1 px-8 lg:px-16 pb-8 max-w-6xl mx-auto w-full">
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {hooks.slice(0, 3).map(h => (
            <HookCard key={h.num} num={h.num} text={h.text} />
          ))}
        </div>
        <div className="grid md:grid-cols-2 gap-5 mt-5">
          {hooks.slice(3).map(h => (
            <HookCard key={h.num} num={h.num} text={h.text} />
          ))}
        </div>
      </div>

      {/* Sticky nav */}
      <div className="sticky bottom-0 bg-slate-900/90 backdrop-blur-sm border-t border-slate-700/50 px-8 py-3 flex items-center justify-between z-20">
        <button
          onClick={() => navigate('/overview')}
          className="flex items-center gap-2 text-slate-400 hover:text-white text-sm transition-colors"
        >
          <ArrowLeft className="h-4 w-4" /> Company Overview
        </button>
        <span className="text-slate-600 text-xs font-medium uppercase tracking-widest">Demo Scenario</span>
        <button
          onClick={() => navigate('/medications')}
          className="flex items-center gap-2 text-teal-400 hover:text-teal-300 text-sm font-semibold transition-colors"
        >
          Browse Medications <ArrowRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

interface HookCardProps { num: string; text: string; }
const HookCard: React.FC<HookCardProps> = ({ num, text }) => (
  <div className="bg-white/5 border border-white/10 rounded-2xl p-6 flex gap-4 hover:bg-white/[0.07] transition-colors">
    <div className="flex-shrink-0">
      <div className="w-8 h-full border-l-2 border-teal-500 pl-3 flex flex-col justify-start">
        <span className="text-teal-400 text-xs font-bold uppercase tracking-widest rotate-180 [writing-mode:vertical-rl]">
          {num}
        </span>
      </div>
    </div>
    <p className="text-slate-300 text-[13px] leading-relaxed">{text}</p>
  </div>
);

export default DemoHookPage;
