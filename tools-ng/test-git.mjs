import { execSync } from 'child_process';

const projectPath = 'D:\\work\\code\\order-reveal';
const author = 'yangbo';
const since = '2026-04-21';
const until = '2026-04-21';

let command = `git -C "${projectPath}" -c core.quotepath=false log --since="${since} 00:00:00" --author="${author}" --pretty=format:"%H|%ad|%an|%s" --date=format:"%Y-%m-%d %H:%M:%S" --no-merges`;
command += ` --until="${until} 23:59:59"`;

console.log('Executing:', command);

try {
  const output = execSync(command, { 
    encoding: 'utf-8', 
    stdio: ['pipe', 'pipe', 'pipe']
  });
  console.log('Output:', output);
} catch (error) {
  console.error('Error:', error.message);
  console.error('Stderr:', error.stderr?.toString());
  console.error('Stdout:', error.stdout?.toString());
}
