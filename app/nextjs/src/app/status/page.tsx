import fs from 'fs/promises';
import { CheckCircle, AlertTriangle } from 'lucide-react';
import os from 'os';
import Link from 'next/link';

async function getSystemInfo() {
    const hostname = os.hostname();
    const uptime = os.uptime();

    let banner = null;
    try {
        // VULNERABILITY INDICATOR: Check for file created by attacker
        const data = await fs.readFile('/tmp/banner.json', 'utf-8');
        banner = JSON.parse(data);
    } catch {
        // File doesn't exist yet (normal state)
    }

    return { hostname, uptime, banner };
}

export default async function StatusPage() {
    const info = await getSystemInfo();
    const isCompromised = !!info.banner;

    return (
        <div className="min-h-screen bg-slate-900 text-white p-8 font-sans">
            <div className="max-w-4xl mx-auto space-y-8">

                <header className="flex justify-between items-center border-b border-slate-700 pb-4">
                    <h1 className="text-3xl font-bold text-blue-400">System Status</h1>
                    <Link href="/" className="text-slate-400 hover:text-white transition-colors">← Back to Home</Link>
                </header>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="p-6 bg-slate-800 rounded-lg border border-slate-700">
                        <h3 className="text-slate-400 text-sm uppercase tracking-wider mb-2">Hostname</h3>
                        <p className="text-2xl font-mono">{info.hostname}</p>
                    </div>
                    <div className="p-6 bg-slate-800 rounded-lg border border-slate-700">
                        <h3 className="text-slate-400 text-sm uppercase tracking-wider mb-2">Uptime</h3>
                        <p className="text-2xl font-mono">{Math.floor(info.uptime / 60)} minutes</p>
                    </div>
                </div>

                {/* COMPROMISE BANNER */}
                {isCompromised ? (
                    <div className="p-8 bg-red-900/20 border-2 border-red-500 rounded-xl flex items-center gap-6 animate-pulse">
                        <AlertTriangle className="w-16 h-16 text-red-500" />
                        <div>
                            <h2 className="text-2xl font-bold text-red-500 mb-2">SECURITY ALERT</h2>
                            <p className="text-red-200 text-lg">{info.banner?.message || "System Compromised"}</p>
                            {info.banner?.severity && (
                                <span className="inline-block mt-2 bg-red-600 text-white text-xs px-2 py-1 rounded">
                                    SEVERITY: {info.banner.severity}
                                </span>
                            )}
                        </div>
                    </div>
                ) : (
                    <div className="p-8 bg-green-900/10 border border-green-800 rounded-xl flex items-center gap-6">
                        <CheckCircle className="w-12 h-12 text-green-500" />
                        <div>
                            <h2 className="text-xl font-bold text-green-500 mb-1">System Secure</h2>
                            <p className="text-slate-400">No security incidents detected on this node.</p>
                        </div>
                    </div>
                )}

            </div>
        </div>
    );
}
