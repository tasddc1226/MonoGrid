import { motion } from 'framer-motion';

export default function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 bg-white/80 backdrop-blur-md border-b border-gray-100">
      <div className="flex items-center gap-2">
        <img src="/favicon.png" alt="MonoGrid Logo" className="w-8 h-8 rounded-lg shadow-sm" />
        <span className="text-xl font-bold tracking-tight text-gray-900">MonoGrid</span>
      </div>
      
      <div className="hidden md:flex items-center gap-8">
        <a href="#features" className="text-sm font-medium text-gray-600 hover:text-black transition-colors">Features</a>
        <a href="#about" className="text-sm font-medium text-gray-600 hover:text-black transition-colors">About</a>
        <a href="/support.html" className="text-sm font-medium text-gray-600 hover:text-black transition-colors">Support</a>
      </div>

      <motion.a 
        href="https://apps.apple.com/app/monogrid" 
        target="_blank"
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        className="px-4 py-2 text-sm font-semibold text-white bg-black rounded-full hover:bg-gray-800 transition-colors"
      >
        Download
      </motion.a>
    </nav>
  );
}
