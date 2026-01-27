import { motion } from 'framer-motion';
import { Grid, Zap, Smartphone, Cloud, Layers, Focus } from 'lucide-react';

const features = [
  {
    icon: <Grid className="w-6 h-6" />,
    title: "GitHub-style Grid",
    description: "Visualize your consistency with a beautiful 365-day contribution graph."
  },
  {
    icon: <Focus className="w-6 h-6" />,
    title: "The Power of 3",
    description: "Limit yourself to 3 core habits to maximize focus and success rates."
  },
  {
    icon: <Zap className="w-6 h-6" />,
    title: "Invisible Tracking",
    description: "Log habits via Widgets, Siri Shortcuts, or Control Center without opening the app."
  },
  {
    icon: <Smartphone className="w-6 h-6" />,
    title: "Interactive Widgets",
    description: "Check off habits directly from your Home Screen or Lock Screen."
  },
  {
    icon: <Cloud className="w-6 h-6" />,
    title: "iCloud Sync",
    description: "Seamlessly sync your data across all your iOS devices automatically."
  },
  {
    icon: <Layers className="w-6 h-6" />,
    title: "Dark Mode",
    description: "Beautifully designed for both light and dark appearances."
  }
];

export default function Features() {
  return (
    <section id="features" className="py-24 bg-gray-50">
      <div className="max-w-6xl mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">Everything you need. <br/><span className="text-gray-400">Nothing you don't.</span></h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            MonoGrid is designed to get out of your way. No ads, no social feed, just you and your progress.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
            >
              <div className="w-12 h-12 bg-gray-100 rounded-xl flex items-center justify-center mb-6 text-black">
                {feature.icon}
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">{feature.title}</h3>
              <p className="text-gray-600 leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
