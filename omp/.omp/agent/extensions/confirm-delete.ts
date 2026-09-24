import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const confirmDelete = (pi: ExtensionAPI) => {
  pi.on("tool_call", async (event, ctx) => {
    const name = event.toolName;
    const input = event.input as Record<string, unknown>;
    let deletionInput: string | undefined;

    // Dedicated delete tools are prompted by tools.approval in config.yml.

    // edit / apply_patch
    if (name === "edit" || name === "apply_patch") {
      const text = String(input.input ?? input.patch ?? input._input ?? "");

      if (
        // hashline: REM = delete whole file
        /^\s*REM\s*$/m.test(text) ||
        // apply_patch: *** Delete File:
        /^\s*\*\*\* Delete File:/m.test(text)
      ) {
        deletionInput = text;
      }
    }

    // Common shell deletion commands
    if (name === "bash") {
      const command = String(input.command ?? "");

      if (
        /(^|[;&|]\s*|\b)(rm|rmdir|unlink)\s/.test(command) ||
        /(^|[;&|]\s*|\b)git\s+(rm|clean)\b/.test(command) ||
        /\bfind\b.*\s-delete\b/.test(command)
      ) {
        deletionInput = command;
      }
    }

    if (deletionInput === undefined) return;

    if (!ctx.hasUI) {
      return {
        block: true,
        reason: "File deletion requires interactive approval",
      };
    }

    const preview =
      deletionInput.length > 1_000
        ? `${deletionInput.slice(0, 1_000)}…`
        : deletionInput;
    const approved = await ctx.ui.confirm(
      "Confirm file deletion",
      `Allow this ${name} operation?\n\n${preview}`,
    );

    if (!approved) {
      return {
        block: true,
        reason: "File deletion was not approved",
      };
    }
  });
};

export default confirmDelete;
