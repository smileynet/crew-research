#!/usr/bin/env node
// tools/evals/harness/multi-turn-codex.mjs
// Multi-turn eval runner using Codex SDK threads
// Usage: node multi-turn-codex.mjs --definition <name> [--trials 3]

import { Codex } from "@openai/codex-sdk";
import { readFileSync, mkdtempSync, cpSync, mkdirSync, writeFileSync, rmSync } from "fs";
import { execSync } from "child_process";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { tmpdir } from "os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const EVALS_DIR = join(__dirname, "..");
const ATOMICS_DIR = join(__dirname, "../../../atomics/skills");
const JUDGES_DIR = join(EVALS_DIR, "judges");

// Parse args
const args = process.argv.slice(2);
const defName = args[args.indexOf("--definition") + 1];
const trials = parseInt(args[args.indexOf("--trials") + 1] || "3");
if (!defName) { console.error("Usage: --definition <name>"); process.exit(1); }

// Load definition
const defPath = join(EVALS_DIR, "definitions", `${defName}.yaml`);
const defYaml = execSync(`yq -o=json '.' "${defPath}"`, { encoding: "utf8" });
const def = JSON.parse(defYaml);

// Load judge config
const judgeYaml = execSync(`yq -o=json '.' "${join(JUDGES_DIR, "default.yaml")}"`, { encoding: "utf8" });
const judgeConfig = JSON.parse(judgeYaml);

console.log(`Multi-turn eval: ${def.name}`);
console.log(`Trials: ${trials} | Mode: codex-sdk threads`);
console.log();

// Setup workspace with fixture
function setupWorkspace(fixture) {
  const workdir = mkdtempSync(join(tmpdir(), `eval-mt-${def.name}-`));
  if (fixture) {
    const fixturePath = join(EVALS_DIR, "fixtures", `${fixture}.yaml`);
    const fixtureYaml = execSync(`yq -o=json '.' "${fixturePath}"`, { encoding: "utf8" });
    const fixtureData = JSON.parse(fixtureYaml);
    execSync(`git clone --depth 1 -q "${fixtureData.repo}" "${workdir}/project"`, { stdio: "pipe" });
    try { execSync(fixtureData.install, { cwd: `${workdir}/project`, stdio: "pipe" }); } catch {}
  }
  return workdir;
}

// Deploy skills to workspace
function deploySkills(workdir, skills) {
  for (const skill of skills) {
    const src = join(ATOMICS_DIR, skill, "SKILL.md");
    const dest = join(workdir, ".agents", "skills", skill, "SKILL.md");
    mkdirSync(dirname(dest), { recursive: true });
    cpSync(src, dest);
  }
}

// Run multi-turn conversation
async function runMultiTurn(workdir, turns) {
  const codex = new Codex();
  const thread = codex.startThread({
    workingDirectory: workdir,
    sandboxMode: "workspace-write",
    approvalPolicy: "never",
    skipGitRepoCheck: true,
  });

  const transcript = [];
  for (const userMsg of turns) {
    try {
      const turn = await thread.run(userMsg);
      transcript.push({ user: userMsg, agent: turn.finalResponse || "(no response)" });
    } catch (e) {
      transcript.push({ user: userMsg, agent: `(error: ${e.message})` });
      break;
    }
  }
  return transcript;
}

// Judge transcript
function judgeTranscript(transcript, criteria) {
  const transcriptText = transcript
    .map((t, i) => `Turn ${i + 1}:\nUser: ${t.user}\nAgent: ${t.agent}`)
    .join("\n\n");

  const prompt = `You are an evaluation judge. Score the following multi-turn agent transcript on a 1-5 scale.

CRITERIA:
${criteria}

AGENT TRANSCRIPT:
${transcriptText}

First reason step-by-step about the output quality against the criteria, then provide your final score.
Respond with EXACTLY this format at the end:
SCORE: <number 1-5>
REASON: <one sentence>`;

  const judgeDir = mkdtempSync(join(tmpdir(), "judge-mt-"));
  const promptFile = join(judgeDir, "prompt.txt");
  writeFileSync(promptFile, prompt);
  try {
    const result = execSync(
      `kiro-cli chat --no-interactive --model "${judgeConfig.model}" --wrap never "$(cat "${promptFile}")"`,
      { cwd: judgeDir, encoding: "utf8", timeout: 60000 }
    ).replace(/\x1B\[[0-9;]*[a-zA-Z]/g, "");
    rmSync(judgeDir, { recursive: true, force: true });

    const score = parseInt(result.match(/SCORE:\s*(\d+)/)?.[1] || "0");
    const reason = result.match(/REASON:\s*(.*)/)?.[1] || "parse error";
    return { score, reason };
  } catch {
    rmSync(judgeDir, { recursive: true, force: true });
    return { score: 0, reason: "judge failed" };
  }
}

// Main
async function main() {
  const conditions = Object.entries(def.conditions);
  const tasks = def.tasks;
  const results = {};

  for (const [condName, condDef] of conditions) {
    const skills = condDef.skills || [];
    const condScores = [];

    for (let taskIdx = 0; taskIdx < tasks.length; taskIdx++) {
      const task = tasks[taskIdx];
      const turns = task.turns;
      if (!turns) { console.error(`Task ${taskIdx} has no turns: array`); continue; }

      const taskScores = [];
      for (let trial = 0; trial < trials; trial++) {
        const workdir = setupWorkspace(def.fixture);
        deploySkills(workdir, skills);

        console.log(`  [${condName}] task ${taskIdx} trial ${trial + 1}/${trials}...`);
        const transcript = await runMultiTurn(
          def.fixture ? `${workdir}/project` : workdir,
          turns
        );
        const { score, reason } = judgeTranscript(transcript, task.criteria);
        taskScores.push(score);
        condScores.push(score);

        rmSync(workdir, { recursive: true, force: true });
      }

      const avg = taskScores.reduce((a, b) => a + b, 0) / taskScores.length;
      console.log(`    Task ${taskIdx} [${condName}]: avg ${avg.toFixed(2)} scores [${taskScores}]`);
    }

    const avg = condScores.reduce((a, b) => a + b, 0) / condScores.length;
    results[condName] = { avg, scores: condScores };
  }

  // Report
  console.log();
  const condNames = Object.keys(results);
  if (condNames.length === 2) {
    const [a, b] = condNames;
    const delta = results[a].avg - results[b].avg;
    console.log(`${a}: ${results[a].avg.toFixed(2)} | ${b}: ${results[b].avg.toFixed(2)} | delta: ${delta.toFixed(2)}`);
    const pass = results[a].avg >= def.threshold && delta >= (def.delta_threshold || 0);
    console.log(pass ? "  ✅ PASS" : "  ❌ FAIL");
  }
}

main().catch(e => { console.error(e); process.exit(1); });
