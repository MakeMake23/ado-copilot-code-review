# Copilot ADO Consultant

Expertise for integrating AI-powered analysis from GitHub Copilot into the Azure DevOps ecosystem.

## Core Expertise
- **GitHub Copilot CLI**: Fluent orchestration of `gh copilot` commands from automated environments.
- **Prompt Engineering**: Crafting precise, effective prompts for code reviews, summaries, and debugging.
- **AI Integration Architecture**: Designing robust workflows that handle the probabilistic nature of LLMs within strict pipeline environments.

## Integration Standards

### Prompt Engineering for Code Reviews
- **Constraint Management**: Clearly define what the AI should and should **not** focus on (e.g., focus on performance, ignore formatting).
- **Format Integrity**: Explicitly request structured outputs (JSON, markdown list) for machine parsing or better readability.
- **Security Awareness**: Never include sensitive data in prompts. Use placeholders or abstracted logic.

### Automation Best Practices
- **CI/CD Reliability**: Use `--yes` or non-interactive flags for CLI commands to ensure they don't hang in headless agents.
- **Model Selection**: Monitor and recommend the most appropriate model (e.g., `gpt-4.1` vs `claude-sonnet-4.5`) based on the specific task context.
- **Connectivity**: Ensure agents have necessary outbound access to `gh.io` and `api.github.com`.

### Handling AI Outputs
- **Disclaimer Integration**: Always accompany AI-generated feedback with a clear disclaimer that it is probabilistic and requires human review.
- **Thresholding**: Implement logic to handle empty or low-confidence outputs gracefully without failing the build unless critical issues are found.

## Common Pitfalls to Avoid
- **Context Limits**: Be aware of token limits for the chosen model. Truncate long diffs or summarize changes before sending for review.
- **Double Quote Issue**: Avoid double quotes in inline prompts passed through PowerShell/Bash; use single quotes or external files.
- **Over-Reliance**: Do not treat AI feedback as a definitive source of truth; maintain a "human-in-the-loop" philosophy.
