import { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider, useDispatch } from 'react-redux';
import { store } from './store/store';
import type { AppDispatch } from './store/store';
import { fetchMedications } from './store/medicationSlice';
import Sidebar from './components/Sidebar';
import ScrollToTop from './components/ScrollToTop';
import { Menu } from 'lucide-react';

import LandingPage from './pages/LandingPage';
import CompanyOverviewPage from './pages/CompanyOverviewPage';
import DemoHookPage from './pages/DemoHookPage';
import MedicationsPage from './pages/MedicationsPage';
import MedicationDetailPage from './pages/MedicationDetailPage';
import CartPage from './pages/CartPage';
import PrescriberPortal from './pages/PrescriberPortal';

function AppContent() {
  const dispatch = useDispatch<AppDispatch>();
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    dispatch(fetchMedications({ pageSize: 1000 }));
  }, [dispatch]);

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar mobileOpen={mobileOpen} onMobileClose={() => setMobileOpen(false)} />

      <div className="flex-1 lg:ml-56 flex flex-col min-w-0">
        <div className="lg:hidden flex items-center gap-3 px-4 py-3 bg-[#0b1120] border-b border-slate-700/50 sticky top-0 z-30">
          <button onClick={() => setMobileOpen(true)} className="text-slate-400 hover:text-white">
            <Menu className="h-6 w-6" />
          </button>
          <span className="text-white font-semibold text-sm">Caldova</span>
        </div>

        <main className="flex-1">
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/overview" element={<CompanyOverviewPage />} />
            <Route path="/demo" element={<DemoHookPage />} />
            <Route path="/medications" element={<MedicationsPage />} />
            <Route path="/medication/:id" element={<MedicationDetailPage />} />
            <Route path="/cart" element={<CartPage />} />
            <Route path="/prescriber-portal" element={<PrescriberPortal />} />
            <Route path="/products" element={<MedicationsPage />} />
            <Route path="/product/:id" element={<MedicationDetailPage />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

function App() {
  return (
    <Provider store={store}>
      <Router>
        <ScrollToTop />
        <AppContent />
      </Router>
    </Provider>
  );
}

export default App;