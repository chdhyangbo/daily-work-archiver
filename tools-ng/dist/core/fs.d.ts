export declare function ensureDir(dirPath: string): Promise<void>;
export declare function readJsonFile<T>(filePath: string): Promise<T | null>;
export declare function writeJsonFile(filePath: string, data: any): Promise<void>;
export declare function readFile(filePath: string): Promise<string | null>;
export declare function writeFile(filePath: string, content: string): Promise<void>;
//# sourceMappingURL=fs.d.ts.map