import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const noDelete = (pi: ExtensionAPI) => {
  pi.on("tool_call", async (event) => {
    const name = event.toolName;
    const input = event.input as Record<string, unknown>;

    // Dedicated delete tools
    if (name === "delete" || name === "mcp__filesystem_delete") {
      return {
        block: true,
        reason: "File deletion is disabled",
      };
    }

    // edit / apply_patch
    if (name === "edit" || name === "apply_patch") {
      const text = String(input.input ?? input.patch ?? input._input ?? "");

      // hashline: REM = delete whole file
      if (/^\s*REM\s*$/m.test(text)) {
        return {
          block: true,
          reason: "File deletion is disabled",
        };
      }

      // apply_patch: *** Delete File:
      if (/^\s*\*\*\* Delete File:/m.test(text)) {
        return {
          block: true,
          reason: "File deletion is disabled",
        };
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
        return {
          block: true,
          reason: "File deletion is disabled",
        };
      }
    }
  });
};

export default noDelete;
