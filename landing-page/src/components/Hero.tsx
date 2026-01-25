import { motion } from 'framer-motion';
import { ArrowRight, Download } from 'lucide-react';

export default function Hero() {
  return (
    <section className="relative flex flex-col items-center justify-center min-h-screen px-4 pt-20 overflow-hidden bg-white">
      <div className="absolute inset-0 z-0 opacity-[0.03]" 
           style={{ backgroundImage: 'radial-gradient(#000 1px, transparent 1px)', backgroundSize: '32px 32px' }}>
      </div>

      <div className="relative z-10 max-w-4xl mx-auto text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <span className="inline-block px-3 py-1 mb-6 text-xs font-semibold tracking-wider text-gray-500 uppercase bg-gray-100 rounded-full">
            iOS 17+ • Widgets • Shortcuts
          </span>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-5xl md:text-7xl font-bold tracking-tighter text-gray-900 mb-6 leading-[1.1]"
        >
          Invisible Tracking.<br />
          <span className="text-gray-400">Visible Progress.</span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="max-w-xl mx-auto mb-10 text-lg md:text-xl text-gray-600 leading-relaxed"
        >
          Log your habits without opening the app. 
          Focus on what matters with a minimalist GitHub-style contribution graph.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <a
            href="https://apps.apple.com/app/monogrid"
            className="flex items-center gap-2 px-8 py-4 text-base font-semibold text-white bg-black rounded-full hover:bg-gray-800 transition-all hover:shadow-lg"
          >
            <Download className="w-5 h-5" />
            Download on App Store
          </a>
          <a
            href="#features"
            className="flex items-center gap-2 px-8 py-4 text-base font-semibold text-gray-900 bg-gray-100 rounded-full hover:bg-gray-200 transition-all"
          >
            Learn more <ArrowRight className="w-4 h-4" />
          </a>
        </motion.div>
      </div>

      {/* Abstract Visual Representation of Grid */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 1, delay: 0.5 }}
        className="mt-20 w-full max-w-5xl"
      >
        <div className="relative rounded-2xl border border-gray-200 bg-gray-50/50 p-4 md:p-8 shadow-2xl backdrop-blur-sm">
           <div className="grid grid-cols-12 gap-2 opacity-50">
             {Array.from({ length: 48 }).map((_, i) => (
               <div 
                key={i} 
                className={`aspect-square rounded-md ${Math.random() > 0.7 ? 'bg-green-500' : Math.random() > 0.4 ? 'bg-green-200' : 'bg-gray-200'}`}
               />
             ))}
           </div>
           <div className="absolute inset-0 flex items-center justify-center">
             <span className="bg-white/80 backdrop-blur px-4 py-2 rounded-lg text-sm font-medium text-gray-500 shadow-sm border border-gray-100">
               Your Year in Pixels
             </span>
           </div>
        </div>
      </motion.div>
    </section>
  );
}
