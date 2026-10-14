import * as path from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	renderDiff,
	type Theme,
	type ToolRenderers,
	VERSION,
} from "@earendil-works/pi-coding-agent";
import {
	type Component,
	type EditorTheme,
	stripTerminalSequences,
	type TUI,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

/**
 * Claude Code look for pi.
 *
 *   header   welcome box: name, version, cwd, model
 *   editor   horizontal rules with a "> " prompt
 *   footer   cwd (branch) on the left; model, thinking, context, cost and
 *            extension statuses (tok/s) on the right
 *   working  "✻ Pondering… (esc to interrupt)" spinner
 *   tools    "⏺ Read(path)" call line, "⎿" result line, collapsed to a few
 *            lines until ctrl+o expands them
 *
 * Colours come from the theme ("claude", deployed next to this file).
 * Tools that ship their own renderers keep them; built-in tools and tools
 * without renderers get the Claude Code layout.
 *
 * Deployed by home/jhl/common/core/pi.nix to ~/.pi/agent/extensions/.
 */

const SPINNER = ["·", "✢", "✳", "✶", "✻", "✽", "✻", "✶", "✳", "✢"];
const VERBS = [
	"Thinking",
	"Pondering",
	"Cogitating",
	"Brewing",
	"Noodling",
	"Percolating",
	"Simmering",
	"Mulling",
	"Ruminating",
	"Crafting",
	"Conjuring",
	"Tinkering",
	"Musing",
	"Synthesizing",
	"Wrangling",
];

const COLLAPSED_LINES = 3;
const COLLAPSED_DIFF_LINES = 20;
const EXPANDED_LINES = 200;

const BUILT_IN = new Set(["read", "bash", "edit", "write", "grep", "find", "ls"]);

function tildify(p: string): string {
	const home = process.env.HOME;
	return home && p.startsWith(home) ? `~${p.slice(home.length)}` : p;
}

function displayPath(p: unknown, cwd: string): string {
	if (typeof p !== "string" || p === "") return ".";
	const abs = path.resolve(cwd, p);
	const rel = path.relative(cwd, abs);
	return rel && !rel.startsWith("..") ? rel : tildify(abs);
}

function oneLine(s: string, max = 80): string {
	const flat = s.replace(/\s+/g, " ").trim();
	return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

function titleCase(name: string): string {
	return name
		.split(/[_\-\s]+/)
		.filter(Boolean)
		.map((w) => w[0]!.toUpperCase() + w.slice(1))
		.join(" ");
}

function cleanLines(text: string): string[] {
	const lines = stripTerminalSequences(text).replace(/\r/g, "").replace(/\t/g, "    ").split("\n");
	while (lines.length > 0 && lines[lines.length - 1]!.trim() === "") lines.pop();
	return lines;
}

function textOf(result: { content?: Array<{ type: string; text?: string }> }): string {
	return (result.content ?? [])
		.filter((c) => c.type === "text" && typeof c.text === "string")
		.map((c) => c.text!)
		.join("\n");
}

function fmtTokens(n: number): string {
	if (n < 1000) return `${n}`;
	if (n < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}

/** Lines with a first-line prefix and a hanging indent for everything after. */
class Hanging implements Component {
	constructor(
		private readonly prefix: string,
		private readonly indent: string,
		private readonly lines: string[],
	) {}

	render(width: number): string[] {
		const inner = Math.max(1, width - visibleWidth(this.indent));
		const out: string[] = [];
		for (const line of this.lines) {
			for (const wrapped of wrapTextWithAnsi(line, inner)) {
				out.push((out.length === 0 ? this.prefix : this.indent) + wrapped);
			}
		}
		return out;
	}

	invalidate(): void {}
}

/** "⎿  first line" then up to `limit` more, with a ctrl+o hint for the rest. */
function resultBlock(theme: Theme, lines: string[], expanded: boolean, limit = COLLAPSED_LINES, styled = false): Component {
	const max = expanded ? EXPANDED_LINES : limit;
	const shown = lines.slice(0, max).map((l) => (styled ? l : theme.fg("toolOutput", l)));
	const hidden = lines.length - shown.length;
	if (hidden > 0) {
		shown.push(theme.fg("dim", expanded ? `… +${hidden} lines` : `… +${hidden} lines (ctrl+o to expand)`));
	}
	if (shown.length === 0) shown.push(theme.fg("dim", "(No output)"));
	return new Hanging(`  ${theme.fg("dim", "⎿")}  `, "     ", shown);
}

function summaryLine(theme: Theme, text: string): Component {
	return new Hanging(`  ${theme.fg("dim", "⎿")}  `, "     ", [text]);
}

type CallSummary = { title: string; detail: string };

function describeCall(toolName: string, args: Record<string, unknown>, cwd: string): CallSummary {
	const a = args ?? {};
	switch (toolName) {
		case "read": {
			const range: string[] = [];
			if (a.offset) range.push(`from line ${a.offset}`);
			if (a.limit) range.push(`${a.limit} lines`);
			return { title: "Read", detail: displayPath(a.path, cwd) + (range.length ? ` · ${range.join(", ")}` : "") };
		}
		case "bash":
			return { title: "Bash", detail: oneLine(String(a.command ?? ""), 100) };
		case "edit":
			return { title: "Update", detail: displayPath(a.path, cwd) };
		case "write":
			return { title: "Write", detail: displayPath(a.path, cwd) };
		case "grep":
			return {
				title: "Search",
				detail: `pattern: "${oneLine(String(a.pattern ?? ""), 60)}"${a.path ? `, path: "${displayPath(a.path, cwd)}"` : ""}${a.glob ? `, glob: "${a.glob}"` : ""}`,
			};
		case "find":
			return {
				title: "Search",
				detail: `pattern: "${oneLine(String(a.pattern ?? ""), 60)}"${a.path ? `, path: "${displayPath(a.path, cwd)}"` : ""}`,
			};
		case "ls":
			return { title: "List", detail: displayPath(a.path, cwd) };
		default: {
			const parts = Object.entries(a)
				.filter(([, v]) => typeof v === "string" || typeof v === "number" || typeof v === "boolean")
				.slice(0, 2)
				.map(([k, v]) => `${k}: ${typeof v === "string" ? `"${oneLine(v, 50)}"` : v}`);
			return { title: titleCase(toolName), detail: parts.join(", ") };
		}
	}
}

function claudeRenderers(toolName: string): ToolRenderers {
	return {
		renderShell: "self",

		renderCall(args, theme, ctx) {
			const dot = ctx.isError ? theme.fg("error", "⏺") : ctx.isPartial ? theme.fg("dim", "⏺") : theme.fg("success", "⏺");
			const { title, detail } = describeCall(toolName, args as Record<string, unknown>, ctx.cwd);
			const line = theme.bold(title) + (detail ? theme.fg("muted", `(${detail})`) : "");
			return new Hanging(`${dot} `, "  ", [line]);
		},

		renderResult(result, { expanded, isPartial }, theme, ctx) {
			if (isPartial) {
				const label = toolName === "bash" ? "Running…" : "Working…";
				const partial = toolName === "bash" ? cleanLines(textOf(result)).slice(-COLLAPSED_LINES) : [];
				return partial.length > 0 ? resultBlock(theme, partial, false) : summaryLine(theme, theme.fg("dim", label));
			}

			const text = textOf(result);
			const lines = cleanLines(text);

			if (ctx.isError) {
				return resultBlock(
					theme,
					lines.map((l) => theme.fg("error", l)),
					expanded,
					COLLAPSED_LINES,
					true,
				);
			}

			const details = (result.details ?? {}) as Record<string, any>;
			const args = (ctx.args ?? {}) as Record<string, any>;

			switch (toolName) {
				case "read": {
					if ((result.content ?? []).some((c: { type: string }) => c.type === "image")) {
						return summaryLine(theme, "Read image");
					}
					// pi appends "[... use offset to continue]" style notes after the content.
					while (lines.length > 0 && /^\s*\[.*\]\s*$/.test(lines[lines.length - 1]!)) lines.pop();
					while (lines.length > 0 && lines[lines.length - 1]!.trim() === "") lines.pop();
					const n = lines.length;
					const head = `Read ${theme.bold(String(n))} ${n === 1 ? "line" : "lines"}`;
					return expanded ? resultBlock(theme, [head, ...lines], true, 0) : summaryLine(theme, head);
				}

				case "edit": {
					const diff: string | undefined = details.diff;
					if (!diff) return summaryLine(theme, "Updated");
					const raw = diff.split("\n");
					const added = raw.filter((l) => l.startsWith("+")).length;
					const removed = raw.filter((l) => l.startsWith("-")).length;
					const head =
						`Updated ${theme.bold(displayPath(args.path, ctx.cwd))} with ` +
						`${theme.fg("success", `${added} ${added === 1 ? "addition" : "additions"}`)} and ` +
						`${theme.fg("error", `${removed} ${removed === 1 ? "removal" : "removals"}`)}`;
					return resultBlock(theme, [head, ...renderDiff(diff).split("\n")], expanded, COLLAPSED_DIFF_LINES + 1, true);
				}

				case "write": {
					const content = typeof args.content === "string" ? args.content : "";
					const body = cleanLines(content).map((l) => theme.fg("toolOutput", l));
					const n = body.length;
					const head = `Wrote ${theme.bold(String(n))} ${n === 1 ? "line" : "lines"} to ${theme.bold(displayPath(args.path, ctx.cwd))}`;
					return resultBlock(theme, [head, ...body], expanded, COLLAPSED_LINES + 1, true);
				}

				case "grep":
				case "find":
				case "ls": {
					const n = lines.length;
					const noun = toolName === "grep" ? "lines" : toolName === "ls" ? "entries" : "files";
					const head = `Found ${theme.bold(String(n))} ${noun}`;
					return expanded ? resultBlock(theme, [head, ...lines.map((l) => theme.fg("toolOutput", l))], true, 0, true) : summaryLine(theme, head);
				}

				default:
					return resultBlock(theme, lines, expanded);
			}
		},
	};
}

class ClaudeEditor extends CustomEditor {
	constructor(
		tui: TUI,
		theme: EditorTheme,
		keybindings: KeybindingsManager,
		private readonly appTheme: () => Theme,
	) {
		super(tui, theme, keybindings, { paddingX: 2 });
	}

	render(width: number): string[] {
		const lines = super.render(width);
		// [top rule, ...text lines, bottom rule, ...autocomplete]
		if (lines.length >= 3 && lines[1]!.startsWith("  ")) {
			lines[1] = `${this.appTheme().fg("text", ">")} ${lines[1]!.slice(2)}`;
		}
		return lines;
	}
}

function welcomeBox(theme: Theme, ctx: ExtensionContext, width: number): string[] {
	const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : "no model";
	const rows = [
		`${theme.fg("accent", "✻")} Welcome to ${theme.bold("pi")}! ${theme.fg("dim", `v${VERSION}`)}`,
		"",
		theme.fg("muted", "  /help for help, /model to switch models"),
		"",
		theme.fg("muted", `  cwd: ${tildify(ctx.cwd)}`),
		theme.fg("muted", `  model: ${model}`),
	];
	const boxWidth = Math.min(width, Math.max(...rows.map(visibleWidth)) + 6);
	const inner = Math.max(1, boxWidth - 4);
	const border = (s: string) => theme.fg("accent", s);
	const row = (content: string) => {
		const fitted = truncateToWidth(content, inner, "…");
		return `${border("│")} ${fitted}${" ".repeat(Math.max(0, inner - visibleWidth(fitted)))} ${border("│")}`;
	};
	return [
		border(`╭${"─".repeat(Math.max(0, boxWidth - 2))}╮`),
		...rows.map(row),
		border(`╰${"─".repeat(Math.max(0, boxWidth - 2))}╯`),
		"",
	];
}

export default function (pi: ExtensionAPI) {
	let totals = { input: 0, output: 0, cost: 0 };

	const recount = (ctx: ExtensionContext) => {
		totals = { input: 0, output: 0, cost: 0 };
		for (const e of ctx.sessionManager.getBranch()) {
			if (e.type === "message" && e.message.role === "assistant") {
				const m = e.message as AssistantMessage;
				totals.input += m.usage?.input ?? 0;
				totals.output += m.usage?.output ?? 0;
				totals.cost += m.usage?.cost?.total ?? 0;
			}
		}
	};

	pi.registerToolRenderer((toolName, next) => {
		if (BUILT_IN.has(toolName)) return claudeRenderers(toolName);
		const theirs = next();
		return theirs?.renderCall || theirs?.renderResult ? theirs : claudeRenderers(toolName);
	});

	pi.on("message_end", async (_event, ctx) => recount(ctx));

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		const verb = VERBS[Math.floor(Math.random() * VERBS.length)];
		ctx.ui.setWorkingMessage(`${verb}… ${ctx.ui.theme.fg("dim", "(esc to interrupt)")}`);
	});

	pi.on("session_start", async (_event, ctx) => {
		recount(ctx);
		if (ctx.mode !== "tui") return;
		const ui = ctx.ui;

		ui.setWorkingIndicator({
			frames: SPINNER.map((f) => ui.theme.fg("accent", f)),
			intervalMs: 120,
		});
		ui.setHiddenThinkingLabel("∴ Thinking…");

		ui.setHeader((_tui, theme) => ({
			render: (width: number) => welcomeBox(theme, ctx, width),
			invalidate() {},
		}));

		ui.setEditorComponent((tui, theme, keybindings) => new ClaudeEditor(tui, theme, keybindings, () => ui.theme));

		ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const branch = footerData.getGitBranch();
					const left = theme.fg("dim", `  ${tildify(ctx.cwd)}${branch ? ` (${branch})` : ""}`);

					const parts: string[] = [];
					if (ctx.model) parts.push(ctx.model.id);
					const thinking = pi.getThinkingLevel();
					if (thinking && thinking !== "off") parts.push(thinking);
					const usage = ctx.getContextUsage();
					if (usage?.percent != null) parts.push(`ctx ${Math.round(usage.percent)}%`);
					if (totals.input || totals.output) parts.push(`↑${fmtTokens(totals.input)} ↓${fmtTokens(totals.output)}`);
					if (totals.cost > 0) parts.push(`$${totals.cost.toFixed(3)}`);
					for (const status of footerData.getExtensionStatuses().values()) {
						if (status) parts.push(stripTerminalSequences(status));
					}
					const right = theme.fg("dim", `${parts.join(" · ")}  `);

					const gap = width - visibleWidth(left) - visibleWidth(right);
					if (gap >= 1) return [left + " ".repeat(gap) + right];
					return [truncateToWidth(left, width), truncateToWidth(right, width)];
				},
			};
		});
	});
}
