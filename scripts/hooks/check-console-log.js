#!/usr/bin/env node

/**
 * Stop Hook: Check for console.log statements in modified files
 * 
 * This hook runs after each response and checks if any modified
 * JavaScript/TypeScript files contain console.log statements.
 * It provides warnings to help developers remember to remove
 * debug statements before committing.
 */

const { execSync } = require('child_process');
const fs = require('fs');

// Skip for team members (git diff on many files is slow in team scenarios)
// Also skip for team leads — Stop hook stdout is the response channel,
// and echoing raw JSON back can interfere with other Stop hooks (e.g., check-context.sh)
if (process.env.CLAUDE_AGENT_TEAM_MEMBER === '1' || process.env.CLAUDE_TEAM_NAME) {
  process.exit(0);
}

let data = '';

// Read stdin
process.stdin.on('data', chunk => {
  data += chunk;
});

process.stdin.on('end', () => {
  try {
    // Check if we're in a git repository
    try {
      execSync('git rev-parse --git-dir', { stdio: 'pipe' });
    } catch {
      // Not in a git repo, nothing to check
      process.exit(0);
    }

    // Get list of modified files
    const files = execSync('git diff --name-only HEAD', {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    })
      .split('\n')
      .filter(f => /\.(ts|tsx|js|jsx)$/.test(f) && fs.existsSync(f));

    let hasConsole = false;

    // Check each file for console.log
    for (const file of files) {
      const content = fs.readFileSync(file, 'utf8');
      if (content.includes('console.log')) {
        console.error(`[Hook] WARNING: console.log found in ${file}`);
        hasConsole = true;
      }
    }

    if (hasConsole) {
      console.error('[Hook] Remove console.log statements before committing');
    }
  } catch (_error) {
    // Silently ignore errors (git might not be available, etc.)
  }

  // Stop hook: stdout is the decision channel.
  // Do NOT echo raw input data — only stderr warnings above.
  // Empty stdout = allow stop.
});
