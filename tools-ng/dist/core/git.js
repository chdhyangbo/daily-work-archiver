import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
export async function findGitDirs(rootPath, maxDepth = 3) {
    try {
        // 使用 PowerShell 查找 .git 目录，排除 node_modules 和 .git 本身
        const command = `powershell -Command "Get-ChildItem -Path '${rootPath}' -Directory -Recurse -Depth ${maxDepth} -Force | Where-Object { $_.Name -eq '.git' -and $_.FullName -notmatch 'node_modules' } | Select-Object -ExpandProperty FullName"`;
        const output = execSync(command, {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'ignore'],
            maxBuffer: 100 * 1024 * 1024 // 100MB buffer
        });
        const gitDirs = output.split('\n').filter(line => line.trim());
        // 过滤：排除 node_modules、.git 嵌套过深等
        const validGitDirs = gitDirs.filter(gitDir => {
            const normalizedPath = gitDir.trim();
            // 排除 node_modules
            if (normalizedPath.includes('node_modules'))
                return false;
            // 排除 .git 内部的 .git
            if ((normalizedPath.match(/\.git/g) || []).length > 1)
                return false;
            return true;
        });
        // 转换为项目路径（去掉 \.git）
        return validGitDirs.map(gitDir => {
            return gitDir.trim().replace(/\\\.git$/, '');
        });
    }
    catch (error) {
        logger.warn(`No git directories found in ${rootPath}`);
        return [];
    }
}
export async function getGitLog(projectPath, options) {
    try {
        // 使用 git -C 而不是 process.chdir，避免路径切换问题
        let command = `git -C "${projectPath}" -c core.quotepath=false log --since="${options.since} 00:00:00" --author="${options.author}" --pretty=format:"%H|%ad|%an|%s" --date=format:"%Y-%m-%d %H:%M:%S"`;
        if (options.noMerges) {
            command += ' --no-merges';
        }
        if (options.until) {
            command += ` --until="${options.until} 23:59:59"`;
        }
        const output = execSync(command, {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'ignore'],
            maxBuffer: 50 * 1024 * 1024 // 50MB buffer
        });
        if (!output.trim()) {
            return [];
        }
        const commits = [];
        const lines = output.split('\n').filter(line => line.trim());
        const projectName = projectPath.split(/[\/\\]/).pop() || '';
        for (const line of lines) {
            const parts = line.split('|', 4);
            if (parts.length < 4)
                continue;
            const [hash, dateTime, author, subject] = parts;
            const [date, time] = dateTime.split(' ');
            const hour = parseInt(time.split(':')[0]);
            // Get commit stats（使用 -C 参数）
            const stats = await getCommitStats(hash, projectPath);
            // Classify commit type
            const type = classifyCommitType(subject);
            commits.push({
                hash,
                shortHash: hash.substring(0, 7),
                dateTime,
                date,
                time,
                hour,
                author,
                project: projectName,
                subject,
                message: subject,
                type,
                insertions: stats.insertions,
                deletions: stats.deletions,
                changed: stats.insertions + stats.deletions
            });
        }
        return commits;
    }
    catch (error) {
        // 静默失败，不显示警告（避免过多输出）
        return [];
    }
}
export async function getCommitStats(hash, projectPath) {
    try {
        const cwdFlag = projectPath ? `-C "${projectPath}"` : '';
        const output = execSync(`git ${cwdFlag} show --stat --format="" ${hash}`, {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'ignore']
        });
        const lastLine = output.trim().split('\n').pop() || '';
        let insertions = 0;
        let deletions = 0;
        const insertionMatch = lastLine.match(/(\d+) insertion/);
        if (insertionMatch) {
            insertions = parseInt(insertionMatch[1]);
        }
        const deletionMatch = lastLine.match(/(\d+) deletion/);
        if (deletionMatch) {
            deletions = parseInt(deletionMatch[1]);
        }
        return { insertions, deletions };
    }
    catch (error) {
        return { insertions: 0, deletions: 0 };
    }
}
function classifyCommitType(subject) {
    const lowerSubject = subject.toLowerCase();
    if (lowerSubject.match(/feat|新增|添加|实现|feature/)) {
        return 'FEATURE';
    }
    else if (lowerSubject.match(/fix|修复|解决|bug|fixed/)) {
        return 'FIX';
    }
    else if (lowerSubject.match(/refactor|重构/)) {
        return 'REFACTOR';
    }
    else if (lowerSubject.match(/docs|文档/)) {
        return 'DOCS';
    }
    else if (lowerSubject.match(/test|测试/)) {
        return 'TEST';
    }
    else {
        return 'OTHER';
    }
}
//# sourceMappingURL=git.js.map