import { logger } from '../utils/logger.js';
import { readFile, writeFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import path from 'path';

export interface SkillNode {
  id: string;
  name: string;
  category: string;
  level: number; // 1-10
  startedAt: string;
  lastPracticed: string;
  milestones: string[];
}

export interface Milestone {
  id: string;
  title: string;
  date: string;
  description: string;
  category: 'technical' | 'soft' | 'leadership' | 'learning';
}

export interface CapabilityRadar {
  technical: number; // 1-10
  problemSolving: number;
  communication: number;
  leadership: number;
  creativity: number;
  learning: number;
}

export interface GrowthData {
  skills: SkillNode[];
  milestones: Milestone[];
  capabilities: CapabilityRadar;
  lastUpdated: string;
}

export async function initGrowthJourney(dataDir: string): Promise<string> {
  const growthDir = path.join(dataDir, 'growth');
  await ensureDir(growthDir);

  const growthFile = path.join(growthDir, 'data.json');
  try {
    await readFile(growthFile);
  } catch {
    const initialData: GrowthData = {
      skills: [],
      milestones: [],
      capabilities: {
        technical: 5,
        problemSolving: 5,
        communication: 5,
        leadership: 5,
        creativity: 5,
        learning: 5
      },
      lastUpdated: new Date().toISOString()
    };
    await writeJsonFile(growthFile, initialData);
    logger.success('成长旅程系统已初始化');
  }

  return growthDir;
}

export async function addSkill(
  dataDir: string,
  name: string,
  category: string,
  level: number = 1
): Promise<SkillNode> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    throw new Error('成长数据未初始化');
  }

  const skill: SkillNode = {
    id: `skill_${Date.now()}`,
    name,
    category,
    level,
    startedAt: new Date().toISOString(),
    lastPracticed: new Date().toISOString(),
    milestones: []
  };

  data.skills.push(skill);
  data.lastUpdated = new Date().toISOString();
  await writeJsonFile(growthFile, data);

  logger.section('🌱 新技能已添加');
  logger.info(`技能: ${skill.name}`);
  logger.info(`分类: ${skill.category}`);
  logger.info(`等级: ${skill.level}/10`);

  return skill;
}

export async function updateSkillLevel(
  dataDir: string,
  skillId: string,
  newLevel: number,
  milestone?: string
): Promise<SkillNode> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    throw new Error('成长数据未初始化');
  }

  const skillIndex = data.skills.findIndex(s => s.id === skillId);
  if (skillIndex === -1) {
    throw new Error('技能未找到');
  }

  const skill = data.skills[skillIndex];
  skill.level = Math.min(10, Math.max(1, newLevel));
  skill.lastPracticed = new Date().toISOString();
  
  if (milestone) {
    skill.milestones.push(milestone);
  }

  data.lastUpdated = new Date().toISOString();
  await writeJsonFile(growthFile, data);

  return skill;
}

export async function addMilestone(
  dataDir: string,
  title: string,
  description: string,
  category: Milestone['category'] = 'technical'
): Promise<Milestone> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    throw new Error('成长数据未初始化');
  }

  const milestone: Milestone = {
    id: `milestone_${Date.now()}`,
    title,
    date: new Date().toISOString().split('T')[0],
    description,
    category
  };

  data.milestones.push(milestone);
  data.lastUpdated = new Date().toISOString();
  await writeJsonFile(growthFile, data);

  logger.section('🏆 里程碑已记录');
  logger.info(`标题: ${milestone.title}`);
  logger.info(`分类: ${milestone.category}`);

  return milestone;
}

export async function updateCapabilities(
  dataDir: string,
  capabilities: Partial<CapabilityRadar>
): Promise<CapabilityRadar> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    throw new Error('成长数据未初始化');
  }

  data.capabilities = {
    ...data.capabilities,
    ...capabilities
  };
  data.lastUpdated = new Date().toISOString();
  await writeJsonFile(growthFile, data);

  return data.capabilities;
}

export async function generateGrowthReport(dataDir: string): Promise<string> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    return '成长数据未初始化';
  }

  let report = '## 🌟 成长旅程报告\n\n';

  // Skills section
  report += '### 📚 技能树\n\n';
  if (data.skills.length === 0) {
    report += '尚未添加技能。开始记录你的技能成长吧！\n\n';
  } else {
    const categories: Record<string, SkillNode[]> = {};
    for (const skill of data.skills) {
      if (!categories[skill.category]) categories[skill.category] = [];
      categories[skill.category].push(skill);
    }

    for (const [category, skills] of Object.entries(categories)) {
      report += `**${category}**\n`;
      for (const skill of skills) {
        const bar = '█'.repeat(skill.level) + '░'.repeat(10 - skill.level);
        report += `- ${skill.name}: ${bar} ${skill.level}/10\n`;
        if (skill.milestones.length > 0) {
          report += `  - 里程碑: ${skill.milestones.join(', ')}\n`;
        }
      }
      report += '\n';
    }
  }

  // Milestones timeline
  report += '### 🏆 里程碑时间线\n\n';
  if (data.milestones.length === 0) {
    report += '尚未记录里程碑。庆祝你的每一个成就！\n\n';
  } else {
    const sorted = data.milestones.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    for (const milestone of sorted.slice(0, 10)) {
      report += `- **${milestone.date}**: ${milestone.title}\n`;
      report += `  ${milestone.description}\n\n`;
    }
  }

  // Capability radar
  report += '### 🎯 能力雷达\n\n';
  const caps = data.capabilities;
  report += `- 技术能力: ${caps.technical}/10\n`;
  report += `- 问题解决: ${caps.problemSolving}/10\n`;
  report += `- 沟通协作: ${caps.communication}/10\n`;
  report += `- 领导力: ${caps.leadership}/10\n`;
  report += `- 创造力: ${caps.creativity}/10\n`;
  report += `- 学习能力: ${caps.learning}/10\n\n`;

  // Growth insights for INFJ
  report += '### 💭 成长洞察\n\n';
  const totalSkills = data.skills.length;
  const avgLevel = totalSkills > 0 
    ? (data.skills.reduce((sum, s) => sum + s.level, 0) / totalSkills).toFixed(1)
    : '0';
  
  report += `- 技能总数: ${totalSkills}\n`;
  report += `- 平均等级: ${avgLevel}/10\n`;
  report += `- 里程碑数: ${data.milestones.length}\n\n`;

  report += '**INFJ 成长提示**:\n';
  report += '- 成长不是线性的，允许自己有起伏\n';
  report += '- 每个小进步都值得庆祝\n';
  report += '- 关注过程，而不仅仅是结果\n';
  report += '- 你的独特视角是最大的优势\n';

  return report;
}

export async function getGrowthTimeline(dataDir: string, months: number = 6): Promise<Milestone[]> {
  const growthDir = await initGrowthJourney(dataDir);
  const growthFile = path.join(growthDir, 'data.json');

  const data = await readJsonFile<GrowthData>(growthFile);
  if (!data) {
    return [];
  }

  const cutoffDate = new Date();
  cutoffDate.setMonth(cutoffDate.getMonth() - months);

  return data.milestones
    .filter(m => new Date(m.date) >= cutoffDate)
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}
