#!/bin/bash

# Git Commit Tracker for macOS (Node.js Version)
# This script captures all git commits globally and saves daily counts to a JSON file

# Configuration
TRACKER_DIR="$HOME/.git-commit-tracker"
JSON_FILE="$TRACKER_DIR/daily_commits.json"
LOG_FILE="$TRACKER_DIR/tracker.log"

# Create directory
mkdir -p "$TRACKER_DIR"

# Initialize JSON file (if it doesn't exist)
if [ ! -f "$JSON_FILE" ]; then
    echo '{}' >"$JSON_FILE"
fi

# Create Node.js commit tracker script
create_nodejs_tracker() {
    cat >"$TRACKER_DIR/commit-tracker.js" <<'NODE_EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

const TRACKER_DIR = path.join(os.homedir(), '.git-commit-tracker');
const JSON_FILE = path.join(TRACKER_DIR, 'daily_commits.json');
const LOG_FILE = path.join(TRACKER_DIR, 'tracker.log');

// Increment commit count
function incrementCommitCount() {
const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format

try {
    // Read JSON file
    let data = {};
    if (fs.existsSync(JSON_FILE)) {
        const fileContent = fs.readFileSync(JSON_FILE, 'utf8');
        try {
            data = JSON.parse(fileContent);
        } catch (parseError) {
            console.error('JSON parse error, creating new data object');
            data = {};
        }
    }
    
    // Increment today's count
    if (data[today]) {
        data[today] += 1;
    } else {
        data[today] = 1;
    }
    
    // Update JSON file
    fs.writeFileSync(JSON_FILE, JSON.stringify(data, null, 2));
    
    // Log entry
    const logEntry = `${new Date().toISOString()}: Commit recorded for ${today}\n`;
    fs.appendFileSync(LOG_FILE, logEntry);
    
    console.log(`Commit count updated: ${today} = ${data[today]}`);
    
} catch (error) {
    console.error('Error updating commit count:', error);
    const errorLog = `${new Date().toISOString()}: ERROR - ${error.message}\n`;
    fs.appendFileSync(LOG_FILE, errorLog);
}
}

// Show statistics
function showStats() {
try {
    if (!fs.existsSync(JSON_FILE)) {
        console.log('No commit data found.');
        return;
    }
    
    const data = JSON.parse(fs.readFileSync(JSON_FILE, 'utf8'));
    
    if (Object.keys(data).length === 0) {
        console.log('No commits recorded yet.');
        return;
    }
    
    console.log('=== Git Commit Statistics ===');
    
    // Total commit count
    const totalCommits = Object.values(data).reduce((sum, count) => sum + count, 0);
    console.log(`Total commits tracked: ${totalCommits}`);
    console.log(`Days with commits: ${Object.keys(data).length}`);
    
    // Last 7 days statistics
    console.log('\nLast 7 days:');
    for (let i = 6; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        const dateStr = date.toISOString().split('T')[0];
        const commits = data[dateStr] || 0;
        console.log(`  ${dateStr}: ${commits} commits`);
    }
    
    // Most active days
    console.log('\nTop 5 most active days:');
    const sortedDays = Object.entries(data)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 5);
        
    sortedDays.forEach(([date, count]) => {
        console.log(`  ${date}: ${count} commits`);
    });
    
    // Weekly average
    const weeklyAverage = totalCommits / Math.max(1, Object.keys(data).length / 7);
    console.log(`\nWeekly average: ${weeklyAverage.toFixed(1)} commits`);
    
    // This month total
    const currentMonth = new Date().toISOString().substring(0, 7); // YYYY-MM
    const monthlyCommits = Object.entries(data)
        .filter(([date]) => date.startsWith(currentMonth))
        .reduce((sum, [, count]) => sum + count, 0);
    console.log(`This month total: ${monthlyCommits} commits`);
    
} catch (error) {
    console.error('Error reading statistics:', error);
}
}

// Reset data
function resetData() {
try {
    fs.writeFileSync(JSON_FILE, '{}');
    fs.writeFileSync(LOG_FILE, '');
    console.log('All data has been reset.');
} catch (error) {
    console.error('Error resetting data:', error);
}
}

// Show log file
function showLog() {
try {
    if (!fs.existsSync(LOG_FILE)) {
        console.log('No log file found.');
        return;
    }
    
    const logContent = fs.readFileSync(LOG_FILE, 'utf8');
    const lines = logContent.trim().split('\n');
    const lastLines = lines.slice(-20); // Last 20 lines
    
    console.log('=== Recent Log Entries ===');
    lastLines.forEach(line => {
        if (line.trim()) console.log(line);
    });
    
} catch (error) {
    console.error('Error reading log file:', error);
}
}

// Weekly report
function weeklyReport() {
try {
    if (!fs.existsSync(JSON_FILE)) {
        console.log('No commit data found.');
        return;
    }
    
    const data = JSON.parse(fs.readFileSync(JSON_FILE, 'utf8'));
    console.log('=== Weekly Commit Report ===');
    
    const today = new Date();
    const weekDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    // Collect data from the last 4 weeks
    const weeklyData = {};
    weekDays.forEach(day => weeklyData[day] = []);
    
    Object.entries(data).forEach(([dateStr, count]) => {
        const date = new Date(dateStr);
        const dayName = weekDays[date.getDay()];
        weeklyData[dayName].push(count);
    });
    
    // Calculate average for each day
    weekDays.forEach(day => {
        const counts = weeklyData[day];
        const average = counts.length > 0 ? 
            (counts.reduce((sum, count) => sum + count, 0) / counts.length).toFixed(1) : 
            '0.0';
        const total = counts.reduce((sum, count) => sum + count, 0);
        console.log(`${day.padEnd(10)}: ${total} total, ${average} avg`);
    });
    
} catch (error) {
    console.error('Error generating weekly report:', error);
}
}

// Process command line arguments
const command = process.argv[2];

switch (command) {
case 'increment':
    incrementCommitCount();
    break;
case 'stats':
    showStats();
    break;
case 'reset':
    resetData();
    break;
case 'log':
    showLog();
    break;
case 'weekly':
    weeklyReport();
    break;
default:
    console.log('Git Commit Tracker - Node.js Version');
    console.log('Usage: node commit-tracker.js [command]');
    console.log('');
    console.log('Commands:');
    console.log('  increment - Record a new commit');
    console.log('  stats     - Show commit statistics');
    console.log('  reset     - Reset all data');
    console.log('  log       - Show tracker log');
    console.log('  weekly    - Show weekly report');
    console.log('');
    console.log('Files:');
    console.log(`  JSON data: ${JSON_FILE}`);
    console.log(`  Log file:  ${LOG_FILE}`);
    break;
}
NODE_EOF

    chmod +x "$TRACKER_DIR/commit-tracker.js"
}

# Commit counter function (using Node.js)
increment_commit_count() {
    node "$TRACKER_DIR/commit-tracker.js" increment
}

# Global git hook setup
setup_global_hooks() {
    echo "Setting up global git hooks..."

    # Check Node.js availability
    if ! command -v node &>/dev/null; then
        echo "Error: Node.js is not installed. Please install Node.js first."
        echo "You can install it via Homebrew: brew install node"
        exit 1
    fi

    # Global hooks directory
    GLOBAL_HOOKS_DIR="$HOME/.git-hooks"
    mkdir -p "$GLOBAL_HOOKS_DIR"

    # Create post-commit hook
    cat >"$GLOBAL_HOOKS_DIR/post-commit" <<'HOOK_EOF'
#!/bin/bash
# Global post-commit hook for tracking commits

TRACKER_DIR="$HOME/.git-commit-tracker"
node "$TRACKER_DIR/commit-tracker.js" increment
HOOK_EOF

    # Make hook executable
    chmod +x "$GLOBAL_HOOKS_DIR/post-commit"

    # Tell Git about the global hooks directory
    git config --global core.hooksPath "$GLOBAL_HOOKS_DIR"

    echo "Global git hooks configured successfully!"
}

# Statistics display function
show_stats() {
    node "$TRACKER_DIR/commit-tracker.js" stats
}

# Weekly report
weekly_report() {
    node "$TRACKER_DIR/commit-tracker.js" weekly
}

# Help function
show_help() {
    echo "Git Commit Tracker - macOS (Node.js Version)"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup     - Setup global git hooks"
    echo "  stats     - Show commit statistics"
    echo "  weekly    - Show weekly commit report"
    echo "  reset     - Reset all data"
    echo "  log       - Show tracker log"
    echo "  test      - Test commit recording"
    echo "  help      - Show this help"
    echo ""
    echo "Files:"
    echo "  JSON data: $JSON_FILE"
    echo "  Log file:  $LOG_FILE"
    echo "  Node.js tracker: $TRACKER_DIR/commit-tracker.js"
}

# Reset function
reset_data() {
    read -p "Are you sure you want to reset all commit data? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        node "$TRACKER_DIR/commit-tracker.js" reset
    else
        echo "Reset cancelled."
    fi
}

# Test function
test_tracker() {
    echo "Testing commit tracker..."
    node "$TRACKER_DIR/commit-tracker.js" increment
    echo "Test completed. Check stats to see if it worked."
}

# Main command processing
case "$1" in
setup)
    create_nodejs_tracker
    setup_global_hooks
    echo "Git commit tracker has been set up successfully!"
    echo "All future git commits will be tracked automatically."
    echo ""
    echo "Test the setup with: $0 test"
    ;;
stats)
    show_stats
    ;;
weekly)
    weekly_report
    ;;
reset)
    reset_data
    ;;
log)
    node "$TRACKER_DIR/commit-tracker.js" log
    ;;
test)
    test_tracker
    ;;
help | --help | -h)
    show_help
    ;;
*)
    if [ -z "$1" ]; then
        show_help
    else
        echo "Unknown command: $1"
        show_help
        exit 1
    fi
    ;;
esac
