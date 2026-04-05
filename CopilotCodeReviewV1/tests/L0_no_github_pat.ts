import { TaskMockRunner } from "azure-pipelines-task-lib/mock-run";
import * as path from "path";

const taskPath = path.join(__dirname, "..", "index.js");
const tmr = new TaskMockRunner(taskPath);

tmr.setInput("azureDevOpsPat", "ado_token");
tmr.setInput("organization", "myorg");
tmr.setInput("project", "myproject");
process.env["SYSTEM_COLLECTIONURI"] = "https://dev.azure.com/myorg";
tmr.setInput("repository", "myrepo");
tmr.setInput("pullRequestId", "123");
tmr.setInput("useSystemAccessToken", "false");

process.env["AGENT_TEMPDIRECTORY"] = "/tmp";
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "/tmp";

// Mock child_process for prerequisite checks
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
  spawn: (cmd: string, args: string[]) => {
    return {
      on: (event: string, cb: any) => {
        if (event === "close") cb(0);
        if (event === "error") {
        }
      },
      kill: () => {},
    };
  },
});

// Mock answers for task-lib (used by ran, etc.)
const a = {
  which: {
    pwsh: "/usr/local/bin/pwsh",
    copilot: "/usr/local/bin/copilot",
  },
  checkPath: {
    "/usr/local/bin/pwsh": true,
    "/usr/local/bin/copilot": true,
  },
  exec: {
    "/usr/local/bin/pwsh -NoProfile -File /tmp/scripts/Get-AzureDevOpsPR.ps1": {
      code: 0,
      stdout: "Mocked PR Details",
    },
  },
};
tmr.setAnswers(a);

tmr.run();
