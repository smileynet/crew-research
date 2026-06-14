# Review Dispatch

When reviewing or auditing your own implementation within the same session:

1. **Finish implementing** — complete all code changes first
2. **Read back your changes** — read the files you modified to get the final content
3. **Dispatch a review subagent** using the `subagent` tool with:
   - The full source code of what you wrote (paste it into the prompt — the subagent cannot read files)
   - The original requirements/constraints the code should meet
   - Explicit instruction: "Find real issues. Be critical. What would break? What edge cases are missed?"
4. **Report the subagent's findings** alongside your implementation

The subagent has fresh context — no memory of why you made your choices. This produces more objective critique than reviewing your own work inline.
