#!/usr/bin/env node
import React from "react";
import { render } from "ink";
import App from "./App.js";
const maxIterations = parseInt(process.argv[2] || "10", 10);
render(React.createElement(App, { maxIterations: maxIterations }));
