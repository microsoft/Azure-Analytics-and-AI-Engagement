import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ChevronRight, Brain, Users, Cpu, ArrowRight, ArrowLeft } from 'lucide-react';

/* ── Section 1 — How We Got Here ─────────────────────────────────────────── */
const HowWeGotHere: React.FC = () => (
  <section className="min-h-screen flex items-center bg-white px-8 lg:px-16 py-16">
    <div className="max-w-6xl mx-auto w-full grid lg:grid-cols-2 gap-12 items-center">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-3">Company Overview</p>
        <h2 className="text-4xl lg:text-5xl font-extrabold text-slate-900 leading-tight mb-6">
          How We<br />Got Here
        </h2>
        <p className="text-slate-600 text-lg leading-relaxed mb-6">
          Some months ago, PharmaCare made a deliberate strategic pivot to reframe how they think about AI. This pivot was grounded in a new operating philosophy:
        </p>
        <p className="text-xl font-bold text-teal-600 mb-8 leading-snug">
          "AI must do more than make us more efficient — it must make us extraordinary."
        </p>
        <p className="text-slate-600 leading-relaxed mb-4">
          This pivot builds on three decades of disciplined growth and capability building. Founded in the early 1990s, PharmaCare began as a regional generics manufacturer with a clear mission:
        </p>
        <p className="text-teal-600 font-semibold text-base mb-4">
          Make safe, effective medications more accessible globally.
        </p>
        <p className="text-slate-600 leading-relaxed">
          Over time, it scaled to a global enterprise operating in more than 100 countries with a diverse product portfolio, spanning over the counter (OTC), specialty therapeutics, and consumer health products.
        </p>
      </div>
      <div className="relative">
        <img
          src="https://images.pexels.com/photos/3985163/pexels-photo-3985163.jpeg?auto=compress&cs=tinysrgb&w=800"
          alt="Pharmaceutical research"
          className="rounded-2xl shadow-2xl w-full object-cover aspect-[4/3]"
        />
        <div className="absolute -bottom-4 -left-4 bg-teal-600 text-white rounded-xl px-5 py-3 shadow-xl">
          <p className="text-2xl font-extrabold">30+</p>
          <p className="text-xs font-medium text-teal-100">Years in pharma</p>
        </div>
        <div className="absolute -top-4 -right-4 bg-slate-900 text-white rounded-xl px-5 py-3 shadow-xl">
          <p className="text-2xl font-extrabold">100+</p>
          <p className="text-xs font-medium text-slate-300">Countries</p>
        </div>
      </div>
    </div>
  </section>
);

/* ── Section 2 — New Company Overview ────────────────────────────────────── */
const NewCompanyOverview: React.FC = () => (
  <section className="min-h-screen bg-slate-900 px-8 lg:px-16 py-16 flex items-center">
    <div className="max-w-6xl mx-auto w-full">
      <p className="text-xs font-bold uppercase tracking-widest text-teal-500 mb-3">Strategic Vision</p>
      <h2 className="text-4xl lg:text-5xl font-extrabold text-white leading-tight mb-6">
        New Company Overview
      </h2>
      <p className="text-slate-300 text-lg max-w-3xl mb-12 leading-relaxed">
        We're telling the story of a frontier firm operating globally in the pharmaceutical sector, whose ambition is to{' '}
        <span className="text-teal-400 font-bold">accelerate innovation, lower cost, and improve outcomes at scale.</span>
      </p>

      <div className="grid lg:grid-cols-2 gap-8 mb-12">
        <div className="group">
          <img
            src="https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=800"
            alt="Pharmaceutical manufacturing"
            className="rounded-xl shadow-xl w-full object-cover aspect-video mb-4 group-hover:scale-[1.01] transition-transform duration-300"
          />
          <p className="text-slate-400 text-sm leading-relaxed">
            They are not defined by a single industry slice. While grounded in drug discovery and manufacturing,{' '}
            <span className="text-teal-400 font-semibold">their work spans the pharmaceutical lifecycle</span> — from research
            and development through production, commercialization, and market access — giving us a narrative that can
            extend across verticals.
          </p>
        </div>
        <div className="group">
          <img
            src="https://images.pexels.com/photos/208518/pexels-photo-208518.jpeg?auto=compress&cs=tinysrgb&w=800"
            alt="Medication production line"
            className="rounded-xl shadow-xl w-full object-cover aspect-video mb-4 group-hover:scale-[1.01] transition-transform duration-300"
          />
          <p className="text-slate-400 text-sm leading-relaxed">
            At its core, this is a company committed to solving complex, real-world problems that ultimately make the
            world a better place:{' '}
            <span className="text-teal-400 font-semibold">
              Bringing life-improving medications to market faster, scaling production responsibly, and delivering
              better outcomes for patients.
            </span>
          </p>
        </div>
      </div>
    </div>
  </section>
);

/* ── Section 3 — Where They Are Today ───────────────────────────────────── */
const pillars = [
  {
    icon: Brain,
    color: 'text-teal-400',
    bg: 'bg-teal-500/10 border-teal-500/20',
    title: 'Human ambition is the starting point',
    points: [
      'Leaders, researchers, operators, and developers set direction and make decisions',
      'AI operates as a continuous layer that connects work, accelerates insight, and executes behind the scenes',
      'This intelligence layer becomes a strategic asset — moving faster and operating more competitively',
    ],
  },
  {
    icon: Users,
    color: 'text-blue-400',
    bg: 'bg-blue-500/10 border-blue-500/20',
    title: 'Work happens in connected teams, not in silos',
    points: [
      'PharmaCare works, builds, operates, observes, and optimizes its business with AI working across functions',
      'Multiple roles interact in a shared system, with AI helping coordinate and carry context across each step',
      'The connected AI-native lifecycle allows them to build intelligent systems, observe and govern them in real time',
    ],
  },
  {
    icon: Cpu,
    color: 'text-purple-400',
    bg: 'bg-purple-500/10 border-purple-500/20',
    title: 'AI is embedded throughout the business process',
    points: [
      "Not a separate tool — it shows up inside workflows: creating artifacts, analyzing signals, coordinating actions",
      'The experience spans everything from conversational AI to autonomous execution',
      'Security and trust are integrated into the flow — not bolted on afterward',
    ],
  },
];

const WhereWeAreToday: React.FC = () => (
  <section className="min-h-screen bg-[#0b1120] px-8 lg:px-16 py-16 flex items-center">
    <div className="max-w-6xl mx-auto w-full">
      <p className="text-xs font-bold uppercase tracking-widest text-teal-500 mb-3">Company Overview</p>
      <h2 className="text-4xl lg:text-5xl font-extrabold text-white leading-tight mb-4">
        Where We Are Today
      </h2>
      <p className="text-slate-400 text-lg max-w-2xl mb-12 leading-relaxed">
        The defining characteristic of PharmaCare is how they operate and the deep integration of AI across their business.
      </p>

      <div className="grid lg:grid-cols-3 gap-6">
        {pillars.map(p => {
          const Icon = p.icon;
          return (
            <div key={p.title} className={`rounded-2xl border p-6 ${p.bg}`}>
              <div className={`mb-4 ${p.color}`}>
                <Icon className="h-8 w-8" />
              </div>
              <h3 className={`text-base font-bold mb-4 ${p.color} leading-snug`}>{p.title}</h3>
              <ul className="space-y-3">
                {p.points.map((pt, i) => (
                  <li key={i} className="flex items-start gap-2 text-slate-400 text-sm leading-relaxed">
                    <ChevronRight className="h-4 w-4 flex-shrink-0 mt-0.5 text-slate-600" />
                    {pt}
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </div>
    </div>
  </section>
);

/* ── Page ────────────────────────────────────────────────────────────────── */
const CompanyOverviewPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="relative">
      <HowWeGotHere />
      <NewCompanyOverview />
      <WhereWeAreToday />

      {/* Sticky prev/next navigation */}
      <div className="sticky bottom-0 bg-slate-900/90 backdrop-blur-sm border-t border-slate-700/50 px-8 py-3 flex items-center justify-between z-20">
        <button
          onClick={() => navigate('/')}
          className="flex items-center gap-2 text-slate-400 hover:text-white text-sm transition-colors"
        >
          <ArrowLeft className="h-4 w-4" /> Landing Page
        </button>
        <span className="text-slate-600 text-xs font-medium uppercase tracking-widest">Company Overview</span>
        <button
          onClick={() => navigate('/medications')}
          className="flex items-center gap-2 text-slate-400 hover:text-white text-sm transition-colors"
        >
          Medications <ArrowRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

export default CompanyOverviewPage;
