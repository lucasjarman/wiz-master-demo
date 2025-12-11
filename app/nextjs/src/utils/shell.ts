import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function executeCommand(command: string) {
  try {
    const check = command.trim().toLowerCase();

    // Some "security" filters to make it look realistic (but bypassable or incomplete)
    if (check.includes('rm -rf /')) {
      return { output: 'Action blocked by security policy', error: null };
    }

    const { stdout, stderr } = await execAsync(command);
    return { output: stdout, error: stderr };
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return { output: null, error: errorMessage };
  }
}
