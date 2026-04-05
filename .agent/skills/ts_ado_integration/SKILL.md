# TS ADO Integration

Expertise for developing high-performance, maintainable TypeScript-based task logic for Azure DevOps extensions.

## Core Expertise
- **TypeScript & Node.js**: Strong focus on type safety, async/await patterns, and modern ES features.
- **Task Library (`azure-pipelines-task-lib`)**: Expert use of the official SDK for input handling, task status, and file operations.
- **Web API (`azure-devops-node-api`)**: Interfacing with the Azure DevOps REST APIs via strong types.

## Development Standards

### Type Safety and Interfaces
- **Strict Typing**: Always use `interface` definitions for complex data models to prevent runtime errors.
- **Input Validation**: Use `tl.getInput()`, `tl.getBoolInput()`, and `tl.getDelimitedInput()` with proper validation early in the task lifecyle.

### Async/Await and Promises
- **Concurrency Control**: Be mindful of large operations; use `Promise.all()` for parallel API requests where appropriate but avoid overwhelming the agent's resources.
- **Error Propagation**: Wrap top-level logic in a `try...catch` block that reports failures via `tl.setResult(tl.TaskResult.Failed, ...)`.

### Project Structure
- **Modular Code**: Break logic into testable modules away from the main `task.ts` entry point.
- **Distribution**: Ensure `node_modules` are handled correctly for production tasks (minification or bundling where appropriate).

## Common Pitfalls to Avoid
- **Blocking Events**: Never use synchronous file or network I/O in the main event loop.
- **Global States**: Avoid global variables that could persist across task iterations in a single agent process.
- **Missing Dependencies**: Always check if dependencies are bundled or provided by the agent's path.
