const express = require('express');
const fs = require('fs');
const path = require('path');
const { marked } = require('marked');
const matter = require('gray-matter');

const app = express();
const PORT = 3456;

// Middleware to parse JSON
app.use(express.json());

// Multiple document sources
const DOC_SOURCES = [
  { name: '工作归档', path: path.join(__dirname, '..', 'work-archive') },
  { name: '技术概设', path: 'D:\\work\\概设' },
  { name: '前端笔记', path: 'D:\\study\\前端笔记\\pages' }
];

// Serve static files
app.use('/static', express.static(path.join(__dirname, 'public')));

// Weekly reports directory
const weeklyReportsDir = path.join(__dirname, '..', 'work-archive', 'reports', 'weekly');

// Function to get current ISO week
function getCurrentWeek() {
  const now = new Date();
  const oneJan = new Date(now.getFullYear(), 0, 1);
  const numberOfDays = Math.floor((now - oneJan) / (24 * 60 * 60 * 1000));
  const weekNumber = Math.ceil((now.getDay() + 1 + numberOfDays) / 7);
  return {
    year: now.getFullYear(),
    week: weekNumber,
    formatted: `${now.getFullYear()}-W${String(weekNumber).padStart(2, '0')}`
  };
}

// Dashboard route
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// Overview route - Unified data display center
app.get('/overview', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'overview.html'));
});

// Goals management route
app.get('/goals', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'goals.html'));
});

// Weekly report API - returns current week's report
app.get('/api/reports/latest-weekly', (req, res) => {
  const currentWeek = getCurrentWeek();
  const weeklyFile = path.join(weeklyReportsDir, `${currentWeek.formatted}.md`);
  
  if (fs.existsSync(weeklyFile)) {
    res.sendFile(weeklyFile);
  } else {
    // Try previous week if current week doesn't exist
    const prevWeek = currentWeek.week > 1 ? currentWeek.week - 1 : 52;
    const prevYear = currentWeek.week > 1 ? currentWeek.year : currentWeek.year - 1;
    const prevWeekFormatted = `${prevYear}-W${String(prevWeek).padStart(2, '0')}`;
    const prevWeeklyFile = path.join(weeklyReportsDir, `${prevWeekFormatted}.md`);
    
    if (fs.existsSync(prevWeeklyFile)) {
      res.sendFile(prevWeeklyFile);
    } else {
      res.status(404).json({ error: 'No weekly report found', currentWeek: currentWeek.formatted });
    }
  }
});

// Weekly report page
app.get('/report/weekly', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'weekly-report.html'));
});

// Daily report page
app.get('/report/daily', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'daily-report.html'));
});

// Monthly report page
app.get('/report/monthly', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'monthly-report.html'));
});

// Growth report page
app.get('/report/growth', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'growth-report.html'));
});

// Health report page
app.get('/report/health', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'health-report.html'));
});

// Achievements route
app.get('/achievements', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'achievements.html'));
});

// Quality metrics pages
app.get('/metrics/commit-message', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'metrics-commit-message.html'));
});

app.get('/metrics/bug-fix', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'metrics-bug-fix.html'));
});

app.get('/metrics/commit-size', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'metrics-commit-size.html'));
});

app.get('/metrics/work-consistency', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'metrics-work-consistency.html'));
});

// API: Get quality metrics data
app.get('/api/quality-metrics.json', (req, res) => {
  try {
    const dashboardDataPath = path.join(__dirname, 'public', 'dashboard-data.json');
    if (fs.existsSync(dashboardDataPath)) {
      const dashboardData = JSON.parse(fs.readFileSync(dashboardDataPath, 'utf-8'));
      if (dashboardData.qualityMetrics) {
        res.json(dashboardData.qualityMetrics);
      } else {
        res.status(404).json({ error: 'No quality metrics data found. Run dashboard command first.' });
      }
    } else {
      res.status(404).json({ error: 'Dashboard data not found. Run dashboard command first.' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to load quality metrics data' });
  }
});

// API routes for overview page
const apiDir = path.join(__dirname, 'public', 'api');
const reportsDir = path.join(__dirname, '..', 'work-archive', 'reports', 'daily');

app.get('/api/quality-report.json', (req, res) => {
  const filePath = path.join(apiDir, 'quality-report.json');
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'Quality report not found. Run: cd tools-ng && npx tsx src/index.ts quality -d 30' });
  }
});

app.get('/api/growth-report.json', (req, res) => {
  const filePath = path.join(apiDir, 'growth-report.json');
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'Growth report not found. Run: cd tools-ng && npx tsx src/index.ts growth -m 12' });
  }
});

app.get('/api/health-report.json', (req, res) => {
  const filePath = path.join(apiDir, 'health-report.json');
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'Health report not found. Run: cd tools-ng && npx tsx src/index.ts health' });
  }
});

// Smart reports
app.get('/api/reports/latest-weekly', (req, res) => {
  try {
    const files = fs.readdirSync(weeklyReportsDir)
      .filter(f => f.endsWith('.md'))
      .sort()
      .reverse();
    
    if (files.length > 0) {
      const latestFile = path.join(weeklyReportsDir, files[0]);
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(latestFile);
    } else {
      res.status(404).json({ error: 'No weekly reports found' });
    }
  } catch (e) {
    res.status(404).json({ error: 'No weekly reports found' });
  }
});

// Weekly report by specific week
app.get('/api/reports/weekly', (req, res) => {
  try {
    const week = req.query.week;
    if (!week) {
      return res.status(400).json({ error: 'Week parameter is required' });
    }
    
    const weeklyFile = path.join(weeklyReportsDir, `${week}.md`);
    
    if (fs.existsSync(weeklyFile)) {
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(weeklyFile);
    } else {
      res.status(404).json({ error: `No weekly report found for ${week}` });
    }
  } catch (e) {
    res.status(404).json({ error: 'Weekly report not found' });
  }
});

app.get('/api/reports/latest-daily', (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const dailyFile = path.join(reportsDir, today.substring(0, 7), `${today}.md`);
    
    if (fs.existsSync(dailyFile)) {
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(dailyFile);
      return;
    }
    
    // Fallback: find the most recent daily report
    const monthDirs = fs.readdirSync(reportsDir)
      .filter(d => fs.statSync(path.join(reportsDir, d)).isDirectory())
      .sort()
      .reverse();
    
    for (const monthDir of monthDirs) {
      const monthPath = path.join(reportsDir, monthDir);
      const files = fs.readdirSync(monthPath)
        .filter(f => f.endsWith('.md'))
        .sort()
        .reverse();
      
      if (files.length > 0) {
        const latestFile = path.join(monthPath, files[0]);
        res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
        res.sendFile(latestFile);
        return;
      }
    }
    
    res.status(404).json({ error: 'No daily report found' });
  } catch (e) {
    res.status(404).json({ error: 'No daily report found' });
  }
});

// Daily report by specific date
app.get('/api/reports/daily', (req, res) => {
  try {
    const date = req.query.date;
    if (!date) {
      return res.status(400).json({ error: 'Date parameter is required' });
    }
    
    const monthStr = date.substring(0, 7); // YYYY-MM
    const dailyFile = path.join(reportsDir, monthStr, `${date}.md`);
    
    if (fs.existsSync(dailyFile)) {
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(dailyFile);
    } else {
      res.status(404).json({ error: `No daily report found for ${date}` });
    }
  } catch (e) {
    res.status(404).json({ error: 'Daily report not found' });
  }
});

app.get('/api/reports/latest-monthly', (req, res) => {
  try {
    const now = new Date();
    const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const monthlyFile = path.join(reportsDir, `${monthStr}-monthly.md`);
    
    if (fs.existsSync(monthlyFile)) {
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(monthlyFile);
    } else {
      res.status(404).json({ error: 'No monthly report for this month' });
    }
  } catch (e) {
    res.status(404).json({ error: 'No monthly report found' });
  }
});

// Monthly report by specific month
app.get('/api/reports/monthly', (req, res) => {
  try {
    const month = req.query.month;
    if (!month) {
      return res.status(400).json({ error: 'Month parameter is required' });
    }
    
    const monthlyFile = path.join(reportsDir, `${month}-monthly.md`);
    
    if (fs.existsSync(monthlyFile)) {
      res.setHeader('Content-Type', 'text/markdown; charset=UTF-8');
      res.sendFile(monthlyFile);
    } else {
      res.status(404).json({ error: `No monthly report found for ${month}` });
    }
  } catch (e) {
    res.status(404).json({ error: 'Monthly report not found' });
  }
});

// Achievements API
const achievementsDir = path.join(__dirname, '..', 'work-archive', 'data', 'achievements');
app.get('/api/achievements.json', (req, res) => {
  const filePath = path.join(achievementsDir, 'achievements.json');
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'Achievements data not found' });
  }
});

// Goals API
const goalsDir = path.join(__dirname, '..', 'work-archive', 'goals');
const goalsIndexFile = path.join(goalsDir, 'index.json');

// Ensure goals directory exists
if (!fs.existsSync(goalsDir)) {
  fs.mkdirSync(goalsDir, { recursive: true });
}

// Get all goals
app.get('/api/goals', (req, res) => {
  try {
    if (!fs.existsSync(goalsIndexFile)) {
      return res.json({ goals: [], stats: {} });
    }
    
    const data = JSON.parse(fs.readFileSync(goalsIndexFile, 'utf-8'));
    const goals = data.goals || [];
    
    // Calculate stats
    const active = goals.filter(g => g.status === 'active').length;
    const completed = goals.filter(g => g.status === 'completed').length;
    const avgProgress = goals.length > 0 
      ? Math.round(goals.reduce((sum, g) => sum + g.progress, 0) / goals.length)
      : 0;
    
    const now = new Date();
    const dueSoon = goals.filter(g => {
      if (g.status !== 'active') return false;
      const deadline = new Date(g.deadline);
      const daysLeft = Math.ceil((deadline.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      return daysLeft >= 0 && daysLeft <= 7;
    }).length;
    
    res.json({
      goals,
      stats: {
        active,
        completed,
        avgProgress,
        dueSoon
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to read goals data' });
  }
});

// Create new goal
app.post('/api/goals', (req, res) => {
  try {
    const { title, level, why, deadline, emotionalValue, description } = req.body;
    
    if (!title || !level || !why || !deadline) {
      return res.status(400).json({ error: 'Missing required fields: title, level, why, deadline' });
    }
    
    // Ensure directory exists
    if (!fs.existsSync(goalsDir)) {
      fs.mkdirSync(goalsDir, { recursive: true });
    }
    
    // Read existing data
    let data = { goals: [], lastReview: new Date().toISOString() };
    if (fs.existsSync(goalsIndexFile)) {
      data = JSON.parse(fs.readFileSync(goalsIndexFile, 'utf-8'));
    }
    
    // Create new goal
    const newGoal = {
      id: `goal_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      title,
      level,
      description: description || '',
      why,
      keyResults: [],
      progress: 0,
      deadline,
      emotionalValue: emotionalValue || 'growth',
      reminders: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'active'
    };
    
    data.goals.push(newGoal);
    fs.writeFileSync(goalsIndexFile, JSON.stringify(data, null, 2));
    
    res.status(201).json(newGoal);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create goal' });
  }
});

// Update goal progress
app.put('/api/goals/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { progress } = req.body;
    
    if (!fs.existsSync(goalsIndexFile)) {
      return res.status(404).json({ error: 'Goals data not found' });
    }
    
    const data = JSON.parse(fs.readFileSync(goalsIndexFile, 'utf-8'));
    const goalIndex = data.goals.findIndex(g => g.id === id);
    
    if (goalIndex === -1) {
      return res.status(404).json({ error: 'Goal not found' });
    }
    
    data.goals[goalIndex].progress = Math.min(100, Math.max(0, progress));
    data.goals[goalIndex].updatedAt = new Date().toISOString();
    
    if (data.goals[goalIndex].progress === 100 && data.goals[goalIndex].status === 'active') {
      data.goals[goalIndex].status = 'completed';
    }
    
    fs.writeFileSync(goalsIndexFile, JSON.stringify(data, null, 2));
    res.json(data.goals[goalIndex]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update goal' });
  }
});

// Delete goal
app.delete('/api/goals/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    if (!fs.existsSync(goalsIndexFile)) {
      return res.status(404).json({ error: 'Goals data not found' });
    }
    
    const data = JSON.parse(fs.readFileSync(goalsIndexFile, 'utf-8'));
    const goalIndex = data.goals.findIndex(g => g.id === id);
    
    if (goalIndex === -1) {
      return res.status(404).json({ error: 'Goal not found' });
    }
    
    // Remove the goal
    const deletedGoal = data.goals.splice(goalIndex, 1)[0];
    data.lastReview = new Date().toISOString();
    
    fs.writeFileSync(goalsIndexFile, JSON.stringify(data, null, 2));
    
    res.json({ 
      success: true, 
      message: '目标已删除',
      goal: deletedGoal
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete goal' });
  }
});

// Parse markdown with frontmatter
function parseMarkdown(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const parsed = matter(content);
    return {
      ...parsed.data,
      content: marked(parsed.content),
      rawContent: parsed.content,
      filePath: filePath,
      fileName: path.basename(filePath)
    };
  } catch (e) {
    return null;
  }
}

// Scan directory for markdown files
function scanDirectory(dirPath, basePath = '') {
  const results = [];
  
  try {
    const items = fs.readdirSync(dirPath);
    
    for (const item of items) {
      const fullPath = path.join(dirPath, item);
      const relativePath = path.join(basePath, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory()) {
        results.push({
          type: 'directory',
          name: item,
          path: relativePath,
          children: scanDirectory(fullPath, relativePath)
        });
      } else if (item.endsWith('.md')) {
        const parsed = parseMarkdown(fullPath);
        results.push({
          type: 'file',
          name: item,
          path: relativePath,
          meta: parsed
        });
      }
    }
  } catch (e) {
    console.error(`Error scanning ${dirPath}:`, e.message);
  }
  
  return results;
}

// Collect all documents for search
function collectAllDocs(dirPath, basePath = '', results = []) {
  try {
    const items = fs.readdirSync(dirPath);
    
    for (const item of items) {
      const fullPath = path.join(dirPath, item);
      const relativePath = path.join(basePath, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory()) {
        collectAllDocs(fullPath, relativePath, results);
      } else if (item.endsWith('.md')) {
        const parsed = parseMarkdown(fullPath);
        if (parsed) {
          results.push({
            path: fullPath,
            relativePath: relativePath,
            ...parsed
          });
        }
      }
    }
  } catch (e) {}
  
  return results;
}

// API: Search documents
app.get('/api/search', (req, res) => {
  const query = req.query.q?.toLowerCase() || '';
  if (!query) {
    return res.json([]);
  }
  
  const allDocs = [];
  DOC_SOURCES.forEach(source => {
    const docs = collectAllDocs(source.path);
    docs.forEach(doc => doc.source = source.name);
    allDocs.push(...docs);
  });
  
  const results = allDocs.filter(doc => {
    // Search in title
    if (doc.title?.toLowerCase().includes(query)) return true;
    // Search in content
    if (doc.rawContent?.toLowerCase().includes(query)) return true;
    // Search in filename
    if (doc.fileName?.toLowerCase().includes(query)) return true;
    // Search in tags
    if (doc.tags?.some(tag => tag.toLowerCase().includes(query))) return true;
    // Search in project
    if (doc.project?.toLowerCase().includes(query)) return true;
    return false;
  }).map(doc => ({
    path: doc.path,
    relativePath: doc.relativePath,
    title: doc.title || doc.fileName,
    source: doc.source,
    excerpt: doc.rawContent?.substring(0, 200).replace(/[#*`]/g, '') + '...'
  }));
  
  res.json(results);
});

// API: Get document tree from all sources
app.get('/api/docs', (req, res) => {
  const allTrees = DOC_SOURCES.map(source => ({
    type: 'source',
    name: source.name,
    path: source.path,
    children: scanDirectory(source.path)
  }));
  res.json(allTrees);
});

// API: Get specific document
app.get('/api/doc/*', (req, res) => {
  const docPath = req.params[0];
  
  // Find which source this path belongs to
  let fullPath = null;
  for (const source of DOC_SOURCES) {
    if (docPath.startsWith(source.path)) {
      fullPath = docPath;
      break;
    }
  }
  
  // If not a full path, try to find in any source
  if (!fullPath) {
    for (const source of DOC_SOURCES) {
      const testPath = path.join(source.path, docPath);
      if (fs.existsSync(testPath)) {
        fullPath = testPath;
        break;
      }
    }
  }
  
  if (!fullPath || !fs.existsSync(fullPath)) {
    return res.status(404).json({ error: 'Document not found' });
  }
  
  // Security check - must be within one of our sources
  const isValidPath = DOC_SOURCES.some(source => 
    fullPath.startsWith(source.path)
  );
  
  if (!isValidPath) {
    return res.status(403).json({ error: 'Access denied' });
  }
  
  const parsed = parseMarkdown(fullPath);
  if (!parsed) {
    return res.status(500).json({ error: 'Failed to parse document' });
  }
  
  res.json(parsed);
});

// HTML Template
const HTML_TEMPLATE = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>工作归档文档中心</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a2e;
            color: #eaeaea;
        }
        .container {
            display: flex;
            height: 100vh;
        }
        .sidebar {
            width: 300px;
            background: #16213e;
            color: #eaeaea;
            overflow-y: auto;
            padding: 20px;
            border-right: 1px solid #0f3460;
        }
        .sidebar h1 {
            font-size: 18px;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e94560;
            color: #eaeaea;
        }
        .search-box {
            width: 100%;
            padding: 10px;
            margin-bottom: 15px;
            background: #0f3460;
            border: 1px solid #0f3460;
            border-radius: 4px;
            color: #eaeaea;
            font-size: 14px;
        }
        .search-box:focus {
            outline: none;
            border-color: #e94560;
        }
        .search-box::placeholder {
            color: #a0a0a0;
        }
        .search-results {
            display: none;
        }
        .search-result {
            padding: 12px;
            margin: 5px 0;
            background: rgba(15, 52, 96, 0.5);
            border-radius: 4px;
            cursor: pointer;
            transition: background 0.2s;
        }
        .search-result:hover {
            background: rgba(233, 69, 96, 0.2);
        }
        .search-result-title {
            font-weight: bold;
            color: #eaeaea;
            margin-bottom: 4px;
        }
        .search-result-source {
            font-size: 12px;
            color: #e94560;
            margin-bottom: 4px;
        }
        .search-result-excerpt {
            font-size: 13px;
            color: #a0a0a0;
            overflow: hidden;
            text-overflow: ellipsis;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        }
        .copy-button {
            position: absolute;
            top: 8px;
            right: 8px;
            padding: 4px 12px;
            background: #e94560;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            opacity: 0;
            transition: opacity 0.2s;
        }
        .doc-content pre {
            position: relative;
        }
        .doc-content pre:hover .copy-button {
            opacity: 1;
        }
        .copy-button:hover {
            background: #ff6b6b;
        }
        .tree-item {
            margin: 5px 0;
        }
        .tree-folder {
            cursor: pointer;
            padding: 8px 10px;
            border-radius: 4px;
            display: flex;
            align-items: center;
            transition: background 0.2s;
            color: #a0a0a0;
        }
        .tree-folder:hover {
            background: rgba(233, 69, 96, 0.2);
            color: #eaeaea;
        }
        .tree-folder::before {
            content: "📁";
            margin-right: 8px;
        }
        .tree-file {
            cursor: pointer;
            padding: 6px 10px 6px 30px;
            border-radius: 4px;
            font-size: 14px;
            transition: background 0.2s;
            color: #a0a0a0;
        }
        .tree-file:hover {
            background: rgba(233, 69, 96, 0.2);
            color: #eaeaea;
        }
        .tree-file::before {
            content: "📄";
            margin-right: 8px;
        }
        .tree-file.active {
            background: #e94560;
            color: white;
        }
        .main-content {
            flex: 1;
            overflow-y: auto;
            padding: 30px;
            background: #1a1a2e;
        }
        .doc-header {
            background: #16213e;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #0f3460;
        }
        .doc-header h1 {
            font-size: 28px;
            margin-bottom: 15px;
            color: #eaeaea;
        }
        .doc-meta {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            color: #a0a0a0;
            font-size: 14px;
        }
        .doc-meta span {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .doc-content {
            background: #16213e;
            padding: 30px;
            border-radius: 8px;
            border: 1px solid #0f3460;
            color: #eaeaea;
        }
        .doc-content h1, .doc-content h2, .doc-content h3, .doc-content h4, .doc-content h5, .doc-content h6 {
            color: #eaeaea;
        }
        .doc-content a {
            color: #e94560;
        }
        .doc-content code {
            background: #0f3460;
            padding: 2px 6px;
            border-radius: 3px;
            color: #e94560;
        }
        .doc-content pre {
            background: #0f3460;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .doc-content pre code {
            background: transparent;
            color: #eaeaea;
        }
        .doc-content blockquote {
            border-left: 4px solid #e94560;
            padding-left: 15px;
            margin: 15px 0;
            color: #a0a0a0;
        }
        .doc-content table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        .doc-content th, .doc-content td {
            border: 1px solid #0f3460;
            padding: 10px;
            text-align: left;
        }
        .doc-content th {
            background: #0f3460;
        }
        .tag {
            display: inline-block;
            padding: 2px 8px;
            background: #e94560;
            color: white;
            border-radius: 12px;
            font-size: 12px;
            margin-right: 5px;
        }
        .progress-bar {
            width: 200px;
            height: 8px;
            background: #0f3460;
            border-radius: 4px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: #e94560;
            transition: width 0.3s;
        }
        .empty-state {
            padding: 100px;
            color: #a0a0a0;
        }
        .empty-state h2 {
            font-size: 24px;
            margin-bottom: 10px;
            color: #eaeaea;
        }
    </style>
</head>
<body>
    <div class="container">
        <aside class="sidebar">
            <h1>📚 工作归档文档</h1>
            <input type="text" class="search-box" id="searchBox" placeholder="🔍 搜索文章标题、内容、标签..." oninput="searchDocs(this.value)">
            <div id="searchResults" class="search-results"></div>
            <div id="docTree"></div>
        </aside>
        <main class="main-content">
            <div id="docContent" class="empty-state">
                <h2>👈 选择文档查看</h2>
                <p>从左侧目录选择要查看的文档，或使用搜索功能</p>
            </div>
        </main>
    </div>
    <script src="/static/app.js"></script>
</body>
</html>
`;

// Main page
app.get('/', (req, res) => {
  res.send(HTML_TEMPLATE);
});

// Start server
app.listen(PORT, () => {
  console.log(`📚 Work Archive Docs Server running at http://localhost:${PORT}`);
  console.log('📁 Serving documents from:');
  DOC_SOURCES.forEach(source => {
    console.log(`   - ${source.name}: ${source.path}`);
  });
});
