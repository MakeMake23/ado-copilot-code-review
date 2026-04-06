const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');


const versionArg = process.argv[2] || 'patch';

const rootPkgPath = path.resolve(__dirname, '../package.json');
if (!fs.existsSync(rootPkgPath)) {
    console.error(`Error: root package.json not found at ${rootPkgPath}`);
    process.exit(1);
}

const rootPkg = JSON.parse(fs.readFileSync(rootPkgPath, 'utf8'));
const currentVersion = rootPkg.version;

function calculateNewVersion(current, arg) {
    // If arg is a specific version number
    if (/^\d+\.\d+\.\d+$/.test(arg)) {
        return arg;
    }

    const parts = current.split('.').map(Number);
    if (parts.length !== 3 || parts.some(isNaN)) {
        throw new Error(`Invalid current version in package.json: ${current}`);
    }

    switch (arg.toLowerCase()) {
        case 'major':
            parts[0]++;
            parts[1] = 0;
            parts[2] = 0;
            break;
        case 'minor':
            parts[1]++;
            parts[2] = 0;
            break;
        case 'patch':
            parts[2]++;
            break;
        default:
            throw new Error(`Invalid bump type: ${arg}. Use "major", "minor", "patch", or a specific version like "1.2.3".`);
    }

    return parts.join('.');
}

let newVersion;
try {
    newVersion = calculateNewVersion(currentVersion, versionArg);
} catch (e) {
    console.error(e.message);
    process.exit(1);
}

const [major, minor, patch] = newVersion.split('.').map(Number);

console.log(`Bumping version from ${currentVersion} to ${newVersion}...`);

const filesToUpdate = [
    { name: 'Root package.json', path: '../package.json', type: 'json-string' },
    { name: 'CopilotCodeReviewV1/package.json', path: '../CopilotCodeReviewV1/package.json', type: 'json-string' },
    { name: 'vss-extension.json', path: '../vss-extension.json', type: 'json-string' },
    { name: 'vss-extension.dev.json', path: '../vss-extension.dev.json', type: 'json-string' },
    { name: 'CopilotCodeReviewV1/task.json', path: '../CopilotCodeReviewV1/task.json', type: 'json-object' },
    { name: 'CopilotCodeReviewDevV1/task.json', path: '../CopilotCodeReviewDevV1/task.json', type: 'json-object' }
];

filesToUpdate.forEach(file => {
    const fullPath = path.resolve(__dirname, file.path);
    if (!fs.existsSync(fullPath)) {
        console.warn(`Warning: File not found - ${file.name} (${fullPath})`);
        return;
    }

    const contentString = fs.readFileSync(fullPath, 'utf8');
    const content = JSON.parse(contentString);

    if (file.type === 'json-string') {
        content.version = newVersion;
    } else if (file.type === 'json-object') {
        if (!content.version) {
            content.version = {};
        }
        content.version.Major = major;
        content.version.Minor = minor;
        content.version.Patch = patch;
    }

    // Preserve original indentation if possible (default to 2 spaces)
    const indentation = contentString.match(/^\s+/m)?.[0]?.length || 2;
    fs.writeFileSync(fullPath, JSON.stringify(content, null, indentation) + '\n', 'utf8');
    console.log(`✅ Updated ${file.name}`);
});

console.log(`\nAll files updated to version ${newVersion} successfully.`);

try {
    console.log(`\nCommitting changes...`);
    execSync('git add .', { stdio: 'inherit' });
    execSync(`git commit -m "chore: bump to v${newVersion}"`, { stdio: 'inherit' });
    console.log(`✅ Committed successfully: chore: bump to v${newVersion}`);
} catch (error) {
    console.error(`\n❌ Failed to commit: ${error.message}`);
    console.log('You may need to commit manually.');
}
