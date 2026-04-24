import { logger } from '../utils/logger.js';
import { getResumeData } from '../core/git-data-loader.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';
/**
 * 从git数据集生成简历内容
 */
export async function generateResume(outputBaseDir, startDate, endDate, name = '杨博', title = '高级前端开发工程师') {
    logger.section('Generating Resume from Git Dataset...');
    const dataDir = path.join(outputBaseDir, 'data', 'git-activities');
    // 默认使用最近一年的数据
    const end = endDate || new Date().toISOString().split('T')[0];
    const start = startDate || (() => {
        const d = new Date();
        d.setFullYear(d.getFullYear() - 1);
        return d.toISOString().split('T')[0];
    })();
    logger.info(`Date range: ${start} ~ ${end}`);
    // 从数据集加载
    const resumeData = await getResumeData(dataDir, start, end);
    if (resumeData.totalCommits === 0) {
        logger.warn('No git activity found in the specified date range');
        return '';
    }
    // 生成简历
    const resume = generateResumeContent(resumeData, name, title, start, end);
    // 保存简历
    const outputDir = path.join(outputBaseDir, 'resume-builder');
    await ensureDir(outputDir);
    const resumeFile = path.join(outputDir, `resume-${end}.md`);
    await writeFile(resumeFile, resume);
    logger.success(`Resume saved to: ${resumeFile}`);
    logger.info('\n' + resume);
    return resume;
}
/**
 * 生成简历内容
 */
function generateResumeContent(data, name, title, startDate, endDate) {
    const totalChanges = data.totalInsertions + data.totalDeletions;
    let resume = `# ${name} - ${title}

> 统计周期: ${startDate} ~ ${endDate}

---

## 📊 核心数据

| 指标 | 数值 |
|------|------|
| **总提交数** | ${data.totalCommits} 次 |
| **代码新增** | +${data.totalInsertions.toLocaleString()} 行 |
| **代码删除** | -${data.totalDeletions.toLocaleString()} 行 |
| **代码变更** | ${totalChanges.toLocaleString()} 行 |
| **参与项目** | ${data.projects.length} 个 |

---

## 🏆 主要成就

${data.achievements.map(a => `- ✅ ${a}`).join('\n')}

---

## 💼 项目经验

`;
    // 按提交数排序项目
    const sortedProjects = data.projects.sort((a, b) => b.commits - a.commits);
    for (const project of sortedProjects) {
        const projectChanges = project.insertions + project.deletions;
        resume += `### ${project.name}

- **提交次数**: ${project.commits} 次
- **代码变更**: +${project.insertions.toLocaleString()} / -${project.deletions.toLocaleString()} (${projectChanges.toLocaleString()} 行)
`;
        if (project.highlights.length > 0) {
            resume += '\n**主要工作**:\n';
            project.highlights.forEach(h => {
                resume += `- ${h}\n`;
            });
        }
        resume += '\n---\n\n';
    }
    resume += `## 📈 工作量统计

| 项目 | 提交数 | 占比 | 代码变更 |
|------|--------|------|----------|
`;
    sortedProjects.forEach(project => {
        const percent = data.totalCommits > 0
            ? Math.round((project.commits / data.totalCommits) * 100)
            : 0;
        const changes = project.insertions + project.deletions;
        resume += `| ${project.name} | ${project.commits} | ${percent}% | ${changes.toLocaleString()} 行 |\n`;
    });
    resume += `
---

## 💡 技术亮点

- 积极参与 ${data.projects.length} 个项目的开发与维护
- 累计提交 ${data.totalCommits} 次，代码变更 ${totalChanges.toLocaleString()} 行
- 涉及多个业务领域，具备良好的跨项目协作能力
- 持续交付高质量代码，保持稳定的开发节奏

---

*简历由 AI Work Archiver 根据 Git 活动数据自动生成*
`;
    return resume;
}
//# sourceMappingURL=resume-generator.js.map