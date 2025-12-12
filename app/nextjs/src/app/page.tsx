import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-slate-900 text-white flex flex-col items-center justify-center p-4">
      <div className="max-w-2xl w-full text-center space-y-8">
        <div className="space-y-4">
          <h1 className="text-6xl font-black bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
            Wiz Demo
          </h1>
          <p className="text-xl text-slate-400">
            Next.js RSC Architecture POC
          </p>
          <div className="inline-block px-3 py-1 rounded-full bg-red-900/30 border border-red-500/30 text-red-400 text-sm font-mono mt-4">
            v16.0.6 (Vulnerable to CVE-2025-66478)
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
          <div className="p-6 bg-slate-800 rounded-xl border border-slate-700 hover:border-blue-500 transition-all group">
            <h2 className="text-2xl font-bold mb-2 group-hover:text-blue-400">Status Check</h2>
            <p className="text-slate-400 mb-4">View system health and banners.</p>
            <Link href="/status" className="inline-block w-full py-2 bg-slate-700 hover:bg-slate-600 rounded text-center transition-colors">
              View Status
            </Link>
          </div>
          <div className="p-6 bg-slate-800 rounded-xl border border-slate-700 hover:border-purple-500 transition-all group">
            <h2 className="text-2xl font-bold mb-2 group-hover:text-purple-400">Secure Data</h2>
            <p className="text-slate-400 mb-4">Access encrypted corporate records.</p>
            <Link href="/data" className="inline-block w-full py-2 bg-slate-700 hover:bg-slate-600 rounded text-center transition-colors">
              Access Data
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
