import React, { useState, useEffect } from "react";
import { Box, Text } from "ink";
import Spinner from "ink-spinner";
import chalk from "chalk";
import { checkCredits, selectProvider, runAgent } from "./agent.js";

interface AppProps {
  maxIterations: number;
}

const App: React.FC<AppProps> = ({ maxIterations }) => {
  const [currentIteration, setCurrentIteration] = useState(0);
  const [status, setStatus] = useState("Starting Ralph...");
  const [provider, setProvider] = useState<string | null>(null);
  const [isRunning, setIsRunning] = useState(false);
  const [completed, setCompleted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [outputLines, setOutputLines] = useState<string[]>([]);

  useEffect(() => {
    runRalph();
  }, []);

  const runRalph = async () => {
    for (let i = 1; i <= maxIterations; i++) {
      setCurrentIteration(i);
      setStatus("Selecting provider...");

      try {
        // Select provider
        const selectedProvider = await selectProvider(setStatus);
        if (!selectedProvider) {
          setError("No providers available");
          return;
        }

        setProvider(selectedProvider);
        setStatus(`Running with ${selectedProvider}...`);
        setIsRunning(true);
        setOutputLines([]);

        // Run the agent with streaming output
        const output = await runAgent(selectedProvider, (line) => {
          setOutputLines((prev) => [...prev.slice(-3), line]);
        });
        setIsRunning(false);

        // Check for completion
        if (output.includes("<promise>COMPLETE</promise>")) {
          setCompleted(true);
          setStatus(`Completed at iteration ${i} of ${maxIterations}`);
          setTimeout(() => process.exit(0), 2000);
          return;
        }

        setStatus(`Iteration ${i} complete`);
        await new Promise((resolve) => setTimeout(resolve, 2000));
      } catch (err) {
        setIsRunning(false);
        setError(err instanceof Error ? err.message : "Unknown error");
        return;
      }
    }

    setStatus(`Reached max iterations (${maxIterations}) without completion`);
    setTimeout(() => process.exit(1), 2000);
  };

  return (
    <Box flexDirection="column" padding={1}>
      <Box marginBottom={1}>
        <Text bold color="cyan">
          Ralph - AI Agent Loop
        </Text>
      </Box>

      <Box marginBottom={1}>
        <Text>
          Iteration:{" "}
          <Text bold color="yellow">
            {currentIteration}
          </Text>
          {" / "}
          <Text dimColor>{maxIterations}</Text>
        </Text>
      </Box>

      {provider && (
        <Box marginBottom={1}>
          <Text>
            Provider:{" "}
            <Text bold color="green">
              {provider}
            </Text>
          </Text>
        </Box>
      )}

      <Box marginBottom={1}>
        {isRunning && (
          <Text>
            <Text color="green">
              <Spinner type="dots" />
            </Text>{" "}
            {status}
          </Text>
        )}
        {!isRunning && !error && !completed && (
          <Text color="blue">● {status}</Text>
        )}
        {completed && <Text color="green">✓ {status}</Text>}
        {error && <Text color="red">✗ {error}</Text>}
      </Box>

      {isRunning && outputLines.length > 0 && (
        <Box
          flexDirection="column"
          borderStyle="round"
          borderColor="gray"
          paddingX={1}
          marginBottom={1}
        >
          {outputLines.map((line, i) => (
            <Text key={i} dimColor>
              {line.slice(0, 120)}
            </Text>
          ))}
        </Box>
      )}

      {completed && (
        <Box borderStyle="round" borderColor="green" padding={1}>
          <Text color="green">🎉 All tasks completed successfully!</Text>
        </Box>
      )}
    </Box>
  );
};

export default App;
