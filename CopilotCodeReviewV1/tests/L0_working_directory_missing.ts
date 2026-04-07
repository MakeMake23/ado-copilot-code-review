import { TaskMockRunner } from "azure-pipelines-task-lib/mock-run";
import * as path from "path";
import * as fs from "fs";

const taskPath = path.join(__dirname, "..", "index.js");
const tmr = new TaskMockRunner(taskPath);

const customWorkingDirectory = path.join("/tmp", "non_existent_cwd");

tmr.setInput("githubPat", "gh_token");
tmr.setInput("azureDevOpsPat", "ado_token");
tmr.setInput("organization", "myorg");
tmr.setInput("project", "myproject");
process.env["SYSTEM_COLLECTIONURI"] = "https://dev.azure.com/myorg";
tmr.setInput("repository", "myrepo");
tmr.setInput("pullRequestId", "123");
tmr.setInput("useSystemAccessToken", "false");
tmr.setInput("workingDirectory", customWorkingDirectory);

process.env["AGENT_TEMPDIRECTORY"] = "/tmp";
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "/tmp";

tmr.registerMock("child_process", {
  spawnSync: (cmd: string, args: string[]) => {
    if (cmd === "pwsh" && args.indexOf("--version") >= 0) {
      return { status: 0, stdout: "PowerShell 7.4.2" };
    }
    if (cmd === "copilot" && args.indexOf("--version") >= 0) {
      return { status: 0, stdout: "0.1.0" };
    }
    return { status: 0 };
  },
  spawn: (_cmd: string, _args: string[], _options: any) => {
    return {
      on: (event: string, cb: any) => {
        if (event === "close") cb(0);
      },
      kill: () => {},
    };
  },
});

tmr.registerMock("fs", {
  ...fs,
  existsSync: (p: string) => {
    if (p === customWorkingDirectory) return false;
    return fs.existsSync(p);
  },
});

const mockedAnswersForTaskLib = {
  which: {
    pwsh: "/usr/local/bin/pwsh",
    copilot: "/usr/local/bin/copilot",
  },
  checkPath: {
    "/usr/local/bin/pwsh": true,
    "/usr/local/bin/copilot": true,
  },
};
tmr.setAnswers(mockedAnswersForTaskLib);

tmr.run();
