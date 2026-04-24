import fs from 'fs';
import path from 'path';
export async function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}
export async function readJsonFile(filePath) {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }
        const content = fs.readFileSync(filePath, 'utf-8');
        return JSON.parse(content);
    }
    catch (error) {
        console.error(`Error reading JSON file ${filePath}:`, error);
        return null;
    }
}
export async function writeJsonFile(filePath, data) {
    try {
        const dir = path.dirname(filePath);
        await ensureDir(dir);
        const content = JSON.stringify(data, null, 2);
        fs.writeFileSync(filePath, content, 'utf-8');
    }
    catch (error) {
        console.error(`Error writing JSON file ${filePath}:`, error);
        throw error;
    }
}
export async function readFile(filePath) {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }
        return fs.readFileSync(filePath, 'utf-8');
    }
    catch (error) {
        console.error(`Error reading file ${filePath}:`, error);
        return null;
    }
}
export async function writeFile(filePath, content) {
    try {
        const dir = path.dirname(filePath);
        await ensureDir(dir);
        fs.writeFileSync(filePath, content, 'utf-8');
    }
    catch (error) {
        console.error(`Error writing file ${filePath}:`, error);
        throw error;
    }
}
//# sourceMappingURL=fs.js.map