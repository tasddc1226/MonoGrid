import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Features from './components/Features';
import Footer from './components/Footer';

function App() {
  return (
    <div className="min-h-screen bg-white text-gray-900 antialiased font-sans selection:bg-black selection:text-white">
      <Navbar />
      <main>
        <Hero />
        <Features />
        {/* CTA Section */}
        <section className="py-24 px-6 bg-black text-white text-center">
          <div className="max-w-3xl mx-auto">
            <h2 className="text-3xl md:text-5xl font-bold mb-6">Ready to start your streak?</h2>
            <p className="text-lg text-gray-400 mb-10">
              Join thousands of users building better habits with MonoGrid.
              Download now for free.
            </p>
            <a 
              href="https://apps.apple.com/app/monogrid"
              className="inline-block px-8 py-4 bg-white text-black font-bold rounded-full hover:bg-gray-200 transition-colors transform hover:scale-105"
            >
              Get MonoGrid
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}

export default App;