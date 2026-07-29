import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import {
  Pill, Home, Building2, Zap, ShoppingCart,
  ChevronDown, ChevronRight, Menu, X, FlaskConical,
} from 'lucide-react';
import { RootState } from '../store/store';

interface NavItem {
  label: string;
  path: string;
  icon: React.ElementType;
  showBadge?: boolean;
}

const navSections: { id: string; label: string; items: NavItem[] }[] = [
  {
    id: 'intro',
    label: 'Intro & Overview',
    items: [
      { label: 'Landing Page',       path: '/',         icon: Home       },
      { label: 'Company Overview',   path: '/overview', icon: Building2  },
    ],
  },
  {
    id: 'catalog',
    label: 'Product Catalog',
    items: [
      { label: 'Browse Medications', path: '/medications', icon: FlaskConical },
      { label: 'Shopping Cart',      path: '/cart',        icon: ShoppingCart, showBadge: true },
    ],
  },
  {
    id: 'hcp',
    label: 'HCP',
    items: [
      { label: 'Prescriber Portal', path: '/prescriber-portal', icon: Pill },
    ],
  },
];

interface SidebarProps {
  mobileOpen: boolean;
  onMobileClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ mobileOpen, onMobileClose }) => {
  const location = useLocation();
  const itemCount = useSelector((state: RootState) => state.cart.itemCount);
  const [open, setOpen] = useState<Record<string, boolean>>({ intro: true, catalog: true, hcp: true });

  const toggle = (id: string) => setOpen(prev => ({ ...prev, [id]: !prev[id] }));

  const isActive = (path: string) =>
    path === '/' ? location.pathname === '/' : location.pathname.startsWith(path);

  return (
    <>
      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 bg-black/50 z-30 lg:hidden" onClick={onMobileClose} />
      )}

      <aside
        className={`fixed left-0 top-0 h-full w-56 bg-[#0b1120] flex flex-col z-40 transition-transform duration-300
          ${mobileOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}
      >
        {/* Logo */}
        <div className="flex items-center justify-between px-5 py-5 border-b border-slate-700/50 flex-shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex-shrink-0">
              <img src="https://dreamdemoassets.blob.core.windows.net/telco-noa/caldovalogo.png" alt="Caldova" className="h-7 w-auto" />
            </div>
            <div>
             
              <p className="text-slate-500 text-[11px] mt-0.5">AI Demo Platform</p>
            </div>
          </div>
          <button onClick={onMobileClose} className="lg:hidden text-slate-500 hover:text-slate-300">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
          {navSections.map(section => (
            <div key={section.id} className="mb-3">
              <button
                onClick={() => toggle(section.id)}
                className="w-full flex items-center justify-between px-2 py-1.5 mb-1 rounded-md group cursor-pointer transition-all duration-150 hover:bg-slate-800/40 active:scale-[0.98] active:bg-slate-700/50"
              >
                <span className="text-[10px] font-bold uppercase tracking-[0.12em] text-slate-500 group-hover:text-slate-400 transition-colors">
                  {section.label}
                </span>
                {open[section.id]
                  ? <ChevronDown className="h-3 w-3 text-slate-600" />
                  : <ChevronRight className="h-3 w-3 text-slate-600" />
                }
              </button>

              {open[section.id] && (
                <div className="space-y-0.5">
                  {section.items.map(item => {
                    const active = isActive(item.path);
                    const Icon = item.icon;
                    return (
                      <Link
                        key={item.path}
                        to={item.path}
                        onClick={onMobileClose}
                        className={`flex items-center gap-2.5 px-3 py-2 rounded-md text-[13px] relative cursor-pointer transition-all duration-150 active:scale-[0.98]
                          ${active
                            ? 'bg-teal-500/10 text-teal-400 hover:bg-teal-500/15 active:bg-teal-500/20'
                            : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50 active:bg-slate-700/60'
                          }`}
                      >
                        {active && (
                          <span className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 bg-teal-500 rounded-r" />
                        )}
                        <Icon className="h-[15px] w-[15px] flex-shrink-0" />
                        <span className="flex-1 font-medium">{item.label}</span>
                        {item.showBadge && itemCount > 0 && (
                          <span className="bg-teal-600 text-white text-[10px] rounded-full w-[18px] h-[18px] flex items-center justify-center font-bold">
                            {itemCount > 9 ? '9+' : itemCount}
                          </span>
                        )}
                      </Link>
                    );
                  })}
                </div>
              )}
            </div>
          ))}
        </nav>

        {/* Footer */}
        <div className="px-5 py-4 border-t border-slate-700/50 flex-shrink-0">
          <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-teal-500 animate-pulse" />
            <p className="text-[11px] text-slate-500">Platform v2.0: Updated Jun 2026</p>
          </div>
        </div>
      </aside>
    </>
  );
};

export { navSections };
export default Sidebar;
