import { execa } from "execa";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs/promises";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SCRIPT_DIR = path.resolve(__dirname, "..");
const PROMPT_FILE = path.join(SCRIPT_DIR, "prompt.md");

type Provider = "amp" | "claude" | "copilot";

export async function checkCredits(provider: Provider): Promise<boolean> {
  try {
    const command = provider === "copilot" ? "copilot" : provider;

    const args =
      provider === "amp"
        ? ["--dangerously-allow-all"]
        : provider === "claude"
        ? ["--dangerously-skip-permissions"]
        : ["-p", "Respond with only the word: OK", "--allow-all-tools", "-s"];

    const { stdout, stderr } = await execa(command, args, {
      input: "Respond with only the word: OK",
      timeout: 30000,
      reject: false,
    });

    const output = stdout + stderr;

    // Check for error indicators
    if (
      /rate.?limit|quota|too many|capacity|overloaded|try again|exceeded|insufficient|credit/i.test(
        output
      )
    ) {
      return false;
    }

    return output.trim().length > 0;
  } catch {
    return false;
  }
}

export async function selectProvider(
  setStatus: (status: string) => void
): Promise<Provider | null> {
  setStatus("Checking amp credits...");
  if (await checkCredits("amp")) {
    return "amp";
  }

  setStatus("Amp unavailable. Checking claude...");
  if (await checkCredits("claude")) {
    return "claude";
  }

  setStatus("Claude unavailable. Checking copilot...");
  if (await checkCredits("copilot")) {
    return "copilot";
  }

  return null;
}

export async function runAgent(
  provider: Provider,
  onOutput?: (line: string) => void
): Promise<string> {
  const promptContent = await fs.readFile(PROMPT_FILE, "utf-8");

  const command = provider === "copilot" ? "copilot" : provider;

  const args =
    provider === "amp"
      ? ["--dangerously-allow-all"]
      : provider === "claude"
      ? ["--dangerously-skip-permissions"]
      : ["-p", promptContent, "--allow-all-tools"];

  const subprocess = execa(command, args, {
    input: provider === "copilot" ? undefined : promptContent,
    reject: false,
    all: true,
  });

  let fullOutput = "";

  // Stream output if callback provided
  if (onOutput && subprocess.all) {
    subprocess.all.on("data", (data) => {
      const text = data.toString();
      fullOutput += text;
      // Send each line to the callback
      const lines = text.split("\n").filter((line: string) => line.trim());
      lines.forEach((line: string) => onOutput(line));
    });
  }

  const { stdout, stderr } = await subprocess;
  return fullOutput || stdout + stderr;
}
