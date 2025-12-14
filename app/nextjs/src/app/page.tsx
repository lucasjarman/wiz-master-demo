import { readFileSync, existsSync } from "fs";

// Force dynamic rendering - don't cache this page
export const dynamic = 'force-dynamic';

// Check for attacker-created banner file
function getBanner(): { message: string; severity?: string } | null {
  const bannerPath = "/tmp/banner.json";
  if (existsSync(bannerPath)) {
    try {
      const content = readFileSync(bannerPath, "utf-8");
      return JSON.parse(content);
    } catch {
      return null;
    }
  }
  return null;
}

export default function Home() {
  const banner = getBanner();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white flex flex-col items-center justify-center p-8 relative overflow-hidden">
      {/* Background glow effects */}
      <div className="absolute top-1/4 -left-32 w-96 h-96 bg-[#0254EC]/20 rounded-full blur-3xl animate-pulse" />
      <div className="absolute bottom-1/4 -right-32 w-96 h-96 bg-[#FFBFFF]/20 rounded-full blur-3xl animate-pulse" />

      {/* Compromise Banner - shows if /tmp/banner.json exists */}
      {banner && (
        <div className="absolute top-0 left-0 right-0 bg-red-600 text-white py-3 px-4 text-center font-bold text-lg z-50 animate-pulse">
          ⚠️ {banner.message} ⚠️
        </div>
      )}

      <div className={`max-w-3xl w-full text-center space-y-12 relative z-10 ${banner ? 'mt-16' : ''}`}>
        {/* Logo / Header Section */}
        <div className="space-y-6">
          {/* Wiz-style gradient text */}
          <h1 className="text-7xl md:text-8xl font-black tracking-tight">
            <span className="bg-gradient-to-r from-[#0254EC] via-[#7B93FF] to-[#FFBFFF] bg-clip-text text-transparent drop-shadow-lg">
              {banner ? "PWNED" : "Wiz"}
            </span>
            <span className="text-slate-200 ml-2">Demo</span>
          </h1>

          <p className="text-lg md:text-xl text-slate-400 font-light tracking-wide">
            {banner ? "This server has been compromised" : "Next.js React Server Components Architecture"}
          </p>

          {/* Divider line with gradient */}
          <div className={`w-24 h-1 mx-auto rounded-full ${banner ? 'bg-red-500' : 'bg-gradient-to-r from-[#0254EC] to-[#FFBFFF]'}`} />
        </div>

        {/* CVE Badge */}
        <div className="flex justify-center">
          <div className="group relative inline-flex items-center gap-3 px-5 py-3 rounded-xl bg-slate-800/60 border border-slate-700/50 backdrop-blur-sm hover:border-[#FFBFFF]/50 transition-all duration-300">
            <div className="flex items-center gap-2">
              <span className="relative flex h-3 w-3">
                <span className={`animate-ping absolute inline-flex h-full w-full rounded-full ${banner ? 'bg-red-400' : 'bg-red-400'} opacity-75`}></span>
                <span className={`relative inline-flex rounded-full h-3 w-3 ${banner ? 'bg-red-500' : 'bg-red-500'}`}></span>
              </span>
              <span className="text-red-400 font-semibold text-sm uppercase tracking-wider">
                {banner ? "EXPLOITED" : "Vulnerable"}
              </span>
            </div>
            <div className="h-4 w-px bg-slate-600" />
            <code className="text-slate-300 text-sm font-mono">
              Next.js 16.0.6 • CVE-2025-66478
            </code>
          </div>
        </div>

        {/* Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-left">
          <div className={`p-5 rounded-xl backdrop-blur-sm transition-all duration-300 ${banner ? 'bg-red-900/40 border border-red-700/50' : 'bg-slate-800/40 border border-slate-700/50 hover:bg-slate-800/60'}`}>
            <div className="text-2xl mb-2">{banner ? "💀" : "🛡️"}</div>
            <h3 className="text-slate-200 font-semibold mb-1">{banner ? "Compromised" : "Security Demo"}</h3>
            <p className="text-slate-500 text-sm">{banner ? "RCE exploit successful" : "Intentionally vulnerable for testing"}</p>
          </div>
          <div className={`p-5 rounded-xl backdrop-blur-sm transition-all duration-300 ${banner ? 'bg-red-900/40 border border-red-700/50' : 'bg-slate-800/40 border border-slate-700/50 hover:bg-slate-800/60'}`}>
            <div className="text-2xl mb-2">{banner ? "🔓" : "⚡"}</div>
            <h3 className="text-slate-200 font-semibold mb-1">{banner ? "Access Gained" : "RSC Exploit"}</h3>
            <p className="text-slate-500 text-sm">{banner ? "Attacker has shell access" : "React Server Components RCE"}</p>
          </div>
          <div className={`p-5 rounded-xl backdrop-blur-sm transition-all duration-300 ${banner ? 'bg-red-900/40 border border-red-700/50' : 'bg-slate-800/40 border border-slate-700/50 hover:bg-slate-800/60'}`}>
            <div className="text-2xl mb-2">{banner ? "☠️" : "☁️"}</div>
            <h3 className="text-slate-200 font-semibold mb-1">{banner ? "Data at Risk" : "Cloud Native"}</h3>
            <p className="text-slate-500 text-sm">{banner ? "S3 buckets accessible" : "Deployed on AWS EKS"}</p>
          </div>
        </div>

        {/* Footer */}
        <div className="pt-8 text-slate-600 text-sm">
          <p>{banner ? "Detected by" : "Powered by"} <span className="text-[#0254EC] font-medium">Wiz</span> Cloud Security</p>
        </div>
      </div>
    </div>
  );
}
