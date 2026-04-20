let docTree = [];

// Load document tree
async function loadDocTree() {
    const response = await fetch('/api/docs');
    docTree = await response.json();
    renderTree(docTree, document.getElementById('docTree'));
}

// Search documents
async function searchDocs(query) {
    if (!query.trim()) {
        document.getElementById('searchResults').style.display = 'none';
        document.getElementById('docTree').style.display = 'block';
        return;
    }
    
    const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
    const results = await response.json();
    
    displaySearchResults(results);
}

// Display search results
function displaySearchResults(results) {
    const container = document.getElementById('searchResults');
    const treeContainer = document.getElementById('docTree');
    
    treeContainer.style.display = 'none';
    container.style.display = 'block';
    
    if (results.length === 0) {
        container.innerHTML = '<div style="padding: 20px; color: #a0a0a0;">未找到匹配的文章</div>';
        return;
    }
    
    container.innerHTML = results.map(result => `
        <div class="search-result" onclick="loadDoc('${escapeJs(result.path)}')">
            <div class="search-result-title">${escapeHtml(result.title)}</div>
            <div class="search-result-source">${escapeHtml(result.source)}</div>
            <div class="search-result-excerpt">${escapeHtml(result.excerpt)}</div>
        </div>
    `).join('');
}

// Render tree
function renderTree(items, container, level = 0) {
    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'tree-item';
        
        if (item.type === 'source') {
            div.innerHTML = `
                <div class="tree-folder source-root" onclick="toggleFolder(this)" style="font-weight: bold; color: #3498db;">
                    <span>📚 ${escapeHtml(item.name)}</span>
                </div>
                <div class="tree-children" style="display: block; padding-left: 10px;">
                </div>
            `;
            const childrenContainer = div.querySelector('.tree-children');
            renderTree(item.children, childrenContainer, level + 1);
        } else if (item.type === 'directory') {
            div.innerHTML = `
                <div class="tree-folder" onclick="toggleFolder(this)">
                    <span>${escapeHtml(item.name)}</span>
                </div>
                <div class="tree-children" style="display: none; padding-left: 15px;">
                </div>
            `;
            const childrenContainer = div.querySelector('.tree-children');
            renderTree(item.children, childrenContainer, level + 1);
        } else {
            div.innerHTML = `
                <div class="tree-file" onclick="loadDoc('${escapeJs(item.path)}')" data-path="${escapeHtml(item.path)}">
                    ${escapeHtml(item.name)}
                </div>
            `;
        }
        
        container.appendChild(div);
    });
}

// Escape HTML
function escapeHtml(text) {
    if (!text) return '';
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// Escape JS string
function escapeJs(text) {
    if (!text) return '';
    return text.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '\\"');
}

// Toggle folder
function toggleFolder(folder) {
    const children = folder.nextElementSibling;
    children.style.display = children.style.display === 'none' ? 'block' : 'none';
}

// Load document
async function loadDoc(path) {
    // Update active state
    document.querySelectorAll('.tree-file').forEach(f => f.classList.remove('active'));
    document.querySelector(`[data-path="${CSS.escape(path)}"]`)?.classList.add('active');
    
    const response = await fetch(`/api/doc/${encodeURIComponent(path)}`);
    const doc = await response.json();
    
    const contentDiv = document.getElementById('docContent');
    
    let metaHtml = '';
    if (doc.title || doc.project || doc.status) {
        metaHtml = '<div class="doc-meta">';
        if (doc.title) metaHtml += `<span>📋 ${escapeHtml(doc.title)}</span>`;
        if (doc.project) metaHtml += `<span>🏷️ ${escapeHtml(doc.project)}</span>`;
        if (doc.status) metaHtml += `<span>📊 ${escapeHtml(doc.status)}</span>`;
        if (doc.author) metaHtml += `<span>👤 ${escapeHtml(doc.author)}</span>`;
        if (doc.created) metaHtml += `<span>📅 ${escapeHtml(doc.created)}</span>`;
        if (doc.progress !== undefined) {
            metaHtml += `
                <span>
                    📈 进度: ${doc.progress}%
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${doc.progress}%"></div>
                    </div>
                </span>
            `;
        }
        metaHtml += '</div>';
    }
    
    let tagsHtml = '';
    if (doc.tags && doc.tags.length > 0) {
        tagsHtml = '<div style="margin-top: 10px;">' + 
            doc.tags.map(tag => `<span class="tag">${escapeHtml(tag)}</span>`).join('') +
            '</div>';
    }
    
    contentDiv.innerHTML = `
        <div class="doc-header">
            <h1>${escapeHtml(doc.title || doc.fileName)}</h1>
            ${metaHtml}
            ${tagsHtml}
        </div>
        <div class="doc-content">
            ${doc.content}
        </div>
    `;
    
    // Add copy buttons to code blocks
    addCopyButtons();
}

// Add copy buttons to code blocks
function addCopyButtons() {
    const codeBlocks = document.querySelectorAll('.doc-content pre');
    codeBlocks.forEach(pre => {
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.textContent = '复制';
        button.onclick = function() {
            const code = pre.querySelector('code')?.textContent || pre.textContent;
            navigator.clipboard.writeText(code).then(() => {
                button.textContent = '已复制!';
                setTimeout(() => button.textContent = '复制', 2000);
            });
        };
        pre.appendChild(button);
    });
}

// Initialize
loadDocTree();
