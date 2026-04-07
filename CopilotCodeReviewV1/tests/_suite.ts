import * as path from "path";
import * as assert from "assert";
import * as ttm from "azure-pipelines-task-lib/mock-test";

describe("Copilot Code Review Task Suite", function () {
  it("should succeed with valid inputs", async function () {
    this.timeout(10000);

    let tp = path.join(__dirname, "L0.js");
    let tr: ttm.MockTestRunner = new ttm.MockTestRunner(tp);

    await tr.runAsync();
    console.log("Succeeded:", tr.succeeded);
    if (!tr.succeeded) {
      console.log("STDOUT:", tr.stdout);
      console.log("STDERR:", tr.stderr);
    }
    assert.strictEqual(tr.succeeded, true, "should have succeeded");
    assert.strictEqual(tr.warningIssues.length, 0, "should have no warnings");
    assert.strictEqual(tr.errorIssues.length, 0, "should have no errors");
  });

  it("should fail if githubPat is missing", async function () {
    this.timeout(10000);

    let tp = path.join(__dirname, "L0_no_github_pat.js");
    let tr: ttm.MockTestRunner = new ttm.MockTestRunner(tp);

    await tr.runAsync();

    assert.strictEqual(tr.succeeded, false, "should have failed");
    assert.strictEqual(tr.errorIssues.length, 1, "should have one error");
    assert.ok(
      tr.errorIssues[0].includes("Input required: githubPat"),
      "error message should mention missing githubPat",
    );
  });

  it("should use custom working directory when specified", async function () {
    this.timeout(10000);

    let tp = path.join(__dirname, "L0_working_directory.js");
    let tr: ttm.MockTestRunner = new ttm.MockTestRunner(tp);

    await tr.runAsync();

    if (!tr.succeeded) {
      console.log("STDOUT:", tr.stdout);
      console.log("STDERR:", tr.stderr);
    }

    assert.strictEqual(tr.succeeded, true, "should have succeeded");
    assert.ok(
      tr.stdout.includes("Using working directory:"),
      "should log the working directory",
    );
    assert.ok(
      tr.stdout.includes("custom_cwd"),
      "should log the custom working directory name",
    );
  });

  it("should fail if working directory does not exist", async function () {
    this.timeout(10000);

    let tp = path.join(__dirname, "L0_working_directory_missing.js");
    let tr: ttm.MockTestRunner = new ttm.MockTestRunner(tp);

    await tr.runAsync();

    assert.strictEqual(tr.succeeded, false, "should have failed");
    assert.strictEqual(tr.errorIssues.length, 1, "should have one error");
    assert.ok(
      tr.errorIssues[0].includes("Working directory not found"),
      "error message should mention missing working directory",
    );
  });
});
