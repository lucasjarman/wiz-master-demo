import { executeCommand } from "@/utils/shell";

// VULNERABLE COMPONENT
// This component takes a specialized object (serialized by RSC) and executes it.
// In a real attack, the attacker manipulates the RSC payload stream.
// Here we simulate the logical flaw: accepting a "debug" command struct from client.

async function unsafeAction(formData: FormData) {
  "use server";

  const cmd = formData.get("debug_cmd");

  if (cmd && typeof cmd === "string") {
    console.log(`[DEBUG] Executing: ${cmd}`);
    // VULNERABILITY: Direct injection into shell execution
    // The React2Shell exploit works by manipulating how React deserializes 
    // the function arguments, often bypassing typical string sanitization 
    // or invoking unexpected gadgets. 
    // For this level 1 demo, we expose a direct sink via a Server Action.
    await executeCommand(cmd);
  }
}

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
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
          <div className="p-6 bg-slate-800 rounded-xl border border-slate-700 hover:border-blue-500 transition-all group">
            <h2 className="text-2xl font-bold mb-2 group-hover:text-blue-400">Status Check</h2>
            <p className="text-slate-400 mb-4">View system health and banners.</p>
            <a href="/status" className="inline-block w-full py-2 bg-slate-700 hover:bg-slate-600 rounded text-center transition-colors">
              View Status
            </a>
          </div>

          <div className="p-6 bg-slate-800 rounded-xl border border-slate-700 hover:border-purple-500 transition-all group">
            <h2 className="text-2xl font-bold mb-2 group-hover:text-purple-400">Secure Data</h2>
            <p className="text-slate-400 mb-4">Access encrypted corporate records.</p>
            <a href="/data" className="inline-block w-full py-2 bg-slate-700 hover:bg-slate-600 rounded text-center transition-colors">
              Access Data
            </a>
          </div>
        </div>

        {/* HIDDEN DEBUG INTERFACE (Simulates the vulnerable entry point) */}
        <div className="opacity-0 hover:opacity-100 transition-opacity duration-500 mt-12 p-4 border border-red-900/30 rounded">
          <p className="text-xs text-red-500/50 uppercase tracking-widest mb-2">Debug Console (Internal Only)</p>
          <form action={unsafeAction} className="flex gap-2">
            <input
              name="debug_cmd"
              type="text"
              className="bg-black/20 border border-red-900/30 rounded px-2 py-1 text-xs text-red-400 w-full focus:outline-none focus:border-red-500"
              placeholder="Enter system command..."
            />
            <button type="submit" className="text-xs bg-red-900/20 px-3 py-1 rounded text-red-400 hover:bg-red-900/40">
              Run
            </button>
          </form>
        </div>

      </div>
    </div>
  );
}
