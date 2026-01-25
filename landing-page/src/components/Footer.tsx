export default function Footer() {
  return (
    <footer className="bg-white border-t border-gray-100 pt-16 pb-8">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-12">
          <div className="mb-8 md:mb-0">
            <div className="flex items-center gap-2 mb-4">
              <img src="/favicon.png" alt="MonoGrid Logo" className="w-6 h-6 rounded shadow-sm" />
              <span className="text-lg font-bold text-gray-900">MonoGrid</span>
            </div>
            <p className="text-gray-500 max-w-xs">
              Minimalist habit tracker for iOS. <br/>
              Build better habits, one block at a time.
            </p>
          </div>

          <div className="flex gap-8 md:gap-12">
            <div className="flex flex-col gap-3">
              <h4 className="font-semibold text-gray-900">Product</h4>
              <a href="https://apps.apple.com/app/monogrid" className="text-gray-500 hover:text-black transition-colors">App Store</a>
              <a href="#features" className="text-gray-500 hover:text-black transition-colors">Features</a>
            </div>
            <div className="flex flex-col gap-3">
              <h4 className="font-semibold text-gray-900">Legal</h4>
              <a href="/privacy-policy.html" className="text-gray-500 hover:text-black transition-colors">Privacy Policy</a>
              <a href="/support.html" className="text-gray-500 hover:text-black transition-colors">Support</a>
            </div>
          </div>
        </div>

        <div className="pt-8 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-sm text-gray-400">
            © {new Date().getFullYear()} MonoGrid. All rights reserved.
          </p>
          <div className="flex gap-4">
             {/* Social links could go here */}
          </div>
        </div>
      </div>
    </footer>
  );
}
