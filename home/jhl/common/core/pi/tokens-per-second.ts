import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Output throughput in pi's footer.
 *
 * The built-in footer carries token counts, cache hits, cost and context use,
 * but not speed. This adds one field: the output tokens of the assistant
 * message divided by how long that message took, wall clock.
 *
 * Wall clock means thinking time counts. That is deliberate -- the number is
 * meant to answer "how fast did that feel", not to benchmark the decode loop.
 *
 * The value stays in the footer until the next response replaces it, so it is
 * still readable while you type the follow-up.
 *
 * Deployed by home/jhl/common/core/pi.nix to ~/.pi/agent/extensions/, which pi
 * auto-discovers -- it needs no entry in settings.json.
 */
export default function (pi: ExtensionAPI) {
	const STATUS_KEY = "tok-per-s";
	let startedAt: number | undefined;

	pi.on("message_start", async (event) => {
		if (event.message?.role === "assistant") startedAt = Date.now();
	});

	pi.on("message_end", async (event, ctx) => {
		if (event.message?.role !== "assistant" || startedAt === undefined) return;

		const seconds = (Date.now() - startedAt) / 1000;
		startedAt = undefined;

		// An aborted or errored turn ends with no usage at all; leave whatever
		// the last real response put there rather than blanking the field.
		const output = event.message.usage?.output;
		if (!output || seconds <= 0) return;

		ctx.ui.setStatus(STATUS_KEY, `${(output / seconds).toFixed(1)} tok/s`);
	});
}
