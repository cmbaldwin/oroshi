import React, { useState, useEffect } from "react";
import { Box, Text } from "ink";
import Spinner from "ink-spinner";
import { selectProvider, runAgent } from "./agent.js";
const App = ({ maxIterations }) => {
    const [currentIteration, setCurrentIteration] = useState(0);
    const [status, setStatus] = useState("Starting Ralph...");
    const [provider, setProvider] = useState(null);
    const [isRunning, setIsRunning] = useState(false);
    const [completed, setCompleted] = useState(false);
    const [error, setError] = useState(null);
    const [outputLines, setOutputLines] = useState([]);
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
            }
            catch (err) {
                setIsRunning(false);
                setError(err instanceof Error ? err.message : "Unknown error");
                return;
            }
        }
        setStatus(`Reached max iterations (${maxIterations}) without completion`);
        setTimeout(() => process.exit(1), 2000);
    };
    return (React.createElement(Box, { flexDirection: "column", padding: 1 },
        React.createElement(Box, { marginBottom: 1 },
            React.createElement(Text, { bold: true, color: "cyan" }, "Ralph - AI Agent Loop")),
        React.createElement(Box, { marginBottom: 1 },
            React.createElement(Text, null,
                "Iteration:",
                " ",
                React.createElement(Text, { bold: true, color: "yellow" }, currentIteration),
                " / ",
                React.createElement(Text, { dimColor: true }, maxIterations))),
        provider && (React.createElement(Box, { marginBottom: 1 },
            React.createElement(Text, null,
                "Provider:",
                " ",
                React.createElement(Text, { bold: true, color: "green" }, provider)))),
        React.createElement(Box, { marginBottom: 1 },
            isRunning && (React.createElement(Text, null,
                React.createElement(Text, { color: "green" },
                    React.createElement(Spinner, { type: "dots" })),
                " ",
                status)),
            !isRunning && !error && !completed && (React.createElement(Text, { color: "blue" },
                "\u25CF ",
                status)),
            completed && React.createElement(Text, { color: "green" },
                "\u2713 ",
                status),
            error && React.createElement(Text, { color: "red" },
                "\u2717 ",
                error)),
        isRunning && outputLines.length > 0 && (React.createElement(Box, { flexDirection: "column", borderStyle: "round", borderColor: "gray", paddingX: 1, marginBottom: 1 }, outputLines.map((line, i) => (React.createElement(Text, { key: i, dimColor: true }, line.slice(0, 120)))))),
        completed && (React.createElement(Box, { borderStyle: "round", borderColor: "green", padding: 1 },
            React.createElement(Text, { color: "green" }, "\uD83C\uDF89 All tasks completed successfully!")))));
};
export default App;
