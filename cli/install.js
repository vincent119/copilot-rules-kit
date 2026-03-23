#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 顏色定義
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function detectIDE() {
  const cwd = process.cwd();
  const homeDir = require('os').homedir();

  // 檢查是否在專案目錄中
  if (fs.existsSync(path.join(cwd, '.kiro'))) {
    return { name: 'kiro', defaultPath: '.kiro/skills' };
  }

  if (fs.existsSync(path.join(cwd, '.cursor'))) {
    return { name: 'cursor', defaultPath: '.cursor/skills' };
  }

  if (fs.existsSync(path.join(cwd, '.vscode'))) {
    return { name: 'vscode', defaultPath: '.agent_agy' };
  }

  // 檢查是否有全域 Kiro 配置
  if (fs.existsSync(path.join(homeDir, '.kiro'))) {
    return { name: 'kiro-global', defaultPath: path.join(homeDir, '.kiro/skills') };
  }

  // 預設為 VS Code
  return { name: 'vscode', defaultPath: '.agent_agy' };
}

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    path: null,
    mode: 'full', // full, core-only, skills-only
    skills: null,
    ide: null,
    help: false,
    debug: false
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    switch (arg) {
      case '--help':
      case '-h':
        options.help = true;
        break;
      case '--debug':
        options.debug = true;
        break;
      case '--vscode':
        options.ide = 'vscode';
        options.path = '.agent_agy';
        break;
      case '--cursor':
        options.ide = 'cursor';
        options.path = '.cursor/skills';
        break;
      case '--kiro':
        options.ide = 'kiro';
        options.path = '.kiro/skills';
        break;
      case '--kiro-global':
        options.ide = 'kiro-global';
        const homeDir = require('os').homedir();
        options.path = path.join(homeDir, '.kiro/skills');
        break;
      case '--path':
        options.path = args[++i];
        break;
      case '--core-only':
        options.mode = 'core-only';
        break;
      case '--skills-only':
        options.mode = 'skills-only';
        break;
      case '--skills':
        options.skills = args[++i];
        break;
    }
  }

  return options;
}

function showHelp() {
  console.log(`
${colors.blue}╔══════════════════════════════════════════════════════╗${colors.reset}
${colors.blue}║     Go Copilot Rules 安裝器                          ║${colors.reset}
${colors.blue}║     專注於 Go 開發的 Copilot Skills 集合             ║${colors.reset}
${colors.blue}╚══════════════════════════════════════════════════════╝${colors.reset}

${colors.yellow}用法：${colors.reset}
    npx @vincent119/go-copilot-rules [選項]

${colors.yellow}選項：${colors.reset}
    --vscode            安裝到 VS Code 預設位置 (.agent_agy/)
    --cursor            安裝到 Cursor 預設位置 (.cursor/skills/)
    --kiro              安裝到 Kiro 專案位置 (.kiro/skills/)
    --kiro-global       安裝到 Kiro 全域位置 (~/.kiro/skills/)
    --path <dir>        安裝到自訂路徑
    --core-only         只安裝核心規範（不包含 Skills）
    --skills-only       只安裝 Skills（不包含核心規範）
    --skills <list>     只安裝特定 Skills（逗號分隔）
    --debug             顯示詳細的除錯資訊
    --help, -h          顯示此幫助訊息

${colors.yellow}範例：${colors.reset}
    # 自動偵測並安裝（預設）
    npx @vincent119/go-copilot-rules

    # 安裝到 VS Code
    npx @vincent119/go-copilot-rules --vscode

    # 安裝到 Cursor
    npx @vincent119/go-copilot-rules --cursor

    # 安裝到 Kiro （專案）
    npx @vincent119/go-copilot-rules --kiro

    # 安裝到 Kiro （全域）
    npx @vincent119/go-copilot-rules --kiro-global

    # 只安裝特定 Skills
    npx @vincent119/go-copilot-rules --skills "go-ddd,go-grpc,go-observability"

    # 安裝到自訂路徑
    npx @vincent119/go-copilot-rules --path ~/.my-copilot-rules

${colors.yellow}支援的 Skills：${colors.reset}
    go-ddd                  DDD 架構設計
    go-grpc                 gRPC 完整規範
    go-testing-advanced     進階測試策略
    go-database             Database Migration
    go-observability        日誌與可觀測性
    go-graceful-shutdown    優雅關機模式
    go-http-advanced        HTTP 進階實作
    go-api-design           API 設計與版本管理
    go-dependency-injection 依賴注入模式
    go-configuration        設定管理
    go-ci-tooling           CI/CD 與工具配置
    go-domain-events        Domain Events 實作
    go-examples             實作範例庫

${colors.cyan}更多資訊：${colors.reset}
    https://github.com/vincent119/copilot-rules-kit
`);
}

function copyRecursive(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();

  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(childItemName => {
      copyRecursive(
        path.join(src, childItemName),
        path.join(dest, childItemName)
      );
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

function findSourceDir() {
  // 嘗試多種路徑來找到 .agent_agy 目錄
  const candidates = [
    // 1. 相對於 cli/ 目錄（本地開發）
    path.join(__dirname, '..', '.agent_agy'),
    // 2. 相對於執行目錄（npm link）
    path.join(process.cwd(), '.agent_agy'),
    // 3. 相對於腳本路徑的上層（npx 可能的位置）
    path.join(path.dirname(__dirname), '.agent_agy'),
    // 4. node_modules 內（npx 安裝後）
    path.join(__dirname, '..', '..', '@vincent119', 'go-copilot-rules', '.agent_agy'),
    // 5. 檢查是否在 package 根目錄
    path.join(__dirname, '.agent_agy'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      // 確認是否包含 skills 目錄
      const skillsDir = path.join(candidate, 'skills');
      if (fs.existsSync(skillsDir)) {
        return candidate;
      }
    }
  }

  return null;
}

function install(options) {
  const sourceDir = findSourceDir();

  if (options.debug) {
    log('', 'reset');
    log('🔍 Debug 資訊：', 'cyan');
    log(`   __dirname: ${__dirname}`, 'reset');
    log(`   __filename: ${__filename}`, 'reset');
    log(`   process.cwd(): ${process.cwd()}`, 'reset');
    log(`   sourceDir: ${sourceDir || '(未找到)'}`, 'reset');
    log('', 'reset');
  }

  // 檢查來源目錄是否存在
  if (!sourceDir) {
    log('', 'reset');
    log('❌ 錯誤：找不到 .agent_agy 目錄', 'red');
    log('', 'reset');
    log('🔍 嘗試過的位置：', 'yellow');
    log(`   1. ${path.join(__dirname, '..', '.agent_agy')}`, 'reset');
    log(`   2. ${path.join(process.cwd(), '.agent_agy')}`, 'reset');
    log(`   3. ${path.join(path.dirname(__dirname), '.agent_agy')}`, 'reset');
    log('', 'reset');
    log('💡 可能的原因：', 'cyan');
    log('   1. Package 尚未正確安裝', 'reset');
    log('   2. 檔案結構不完整', 'reset');
    log('', 'reset');
    log('🔧 解決方案：', 'cyan');
    log('   使用手動安裝方式：', 'reset');
    log('   git clone https://github.com/vincent119/copilot-rules-kit.git /tmp/copilot-rules-kit', 'blue');
    log('   mkdir -p .kiro/skills', 'blue');
    log('   cp -r /tmp/copilot-rules-kit/.agent_agy/skills/* .kiro/skills/', 'blue');
    log('', 'reset');
    log('📖 完整安裝指南：', 'cyan');
    log('   https://github.com/vincent119/copilot-rules-kit/blob/main/.agent_agy/INSTALLATION.md', 'blue');
    process.exit(1);
  }

  // 如果沒有指定路徑，自動偵測
  if (!options.path) {
    const detected = detectIDE();
    options.path = detected.defaultPath;
    log(`ℹ️  偵測到 ${detected.name}，使用路徑: ${options.path}`, 'cyan');
  }

  const targetDir = path.resolve(process.cwd(), options.path);

  log('', 'reset');
  log('╔══════════════════════════════════════════════════════╗', 'blue');
  log('║     Go Copilot Rules 安裝器                          ║', 'blue');
  log('╚══════════════════════════════════════════════════════╝', 'blue');
  log('', 'reset');

  log('📋 安裝配置：', 'blue');
  log(`   • 模式: ${options.mode}`, 'green');
  log(`   • 目標: ${targetDir}`, 'green');
  if (options.skills) {
    log(`   • Skills: ${options.skills}`, 'green');
  }
  log('', 'reset');

  // 備份現有目錄
  if (fs.existsSync(targetDir)) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const backupDir = `${targetDir}.backup.${timestamp}`;
    log(`⚠️  目標目錄已存在，備份到 ${backupDir}`, 'yellow');
    fs.renameSync(targetDir, backupDir);
  }

  // 建立目標目錄
  fs.mkdirSync(targetDir, { recursive: true });

  // 根據模式複製檔案
  log('📦 安裝檔案...', 'blue');

  switch (options.mode) {
    case 'full':
      log('   複製完整規範（核心 + 所有 Skills）', 'cyan');
      copyRecursive(sourceDir, targetDir);
      break;

    case 'core-only':
      log('   複製核心規範', 'cyan');
      const rulesDir = path.join(targetDir, 'rules');
      fs.mkdirSync(rulesDir, { recursive: true });
      copyRecursive(path.join(sourceDir, 'rules'), rulesDir);

      // 複製 README
      const readmeSrc = path.join(sourceDir, 'README.md');
      if (fs.existsSync(readmeSrc)) {
        fs.copyFileSync(readmeSrc, path.join(targetDir, 'README.md'));
      }
      break;

    case 'skills-only':
      log('   複製所有 Skills', 'cyan');
      const skillsDir = path.join(targetDir, 'skills');
      fs.mkdirSync(skillsDir, { recursive: true });
      copyRecursive(path.join(sourceDir, 'skills'), skillsDir);
      break;
  }

  // 如果指定了特定 Skills
  if (options.skills) {
    log('📋 複製選定的 Skills...', 'blue');
    const skillsDir = path.join(targetDir, 'skills');
    fs.mkdirSync(skillsDir, { recursive: true });

    const skillList = options.skills.split(',').map(s => s.trim());
    skillList.forEach(skill => {
      const skillSrc = path.join(sourceDir, 'skills', skill);
      if (fs.existsSync(skillSrc)) {
        const skillDest = path.join(skillsDir, skill);
        copyRecursive(skillSrc, skillDest);
        log(`   • ${skill}`, 'green');
      } else {
        log(`   • ${skill} (不存在，跳過)`, 'red');
      }
    });
  }

  // 複製文件
  ['INSTALLATION.md', 'SKILLS_INDEX.md'].forEach(file => {
    const src = path.join(sourceDir, file);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, path.join(targetDir, file));
    }
  });

  // 統計安裝結果
  log('', 'reset');
  log('✅ 安裝完成！', 'green');
  log('', 'reset');

  // 顯示已安裝內容
  if (options.mode !== 'skills-only') {
    const rulesPath = path.join(targetDir, 'rules');
    if (fs.existsSync(rulesPath)) {
      const coreFiles = fs.readdirSync(rulesPath).filter(f => f.endsWith('.md'));
      log(`📊 核心規範: ${coreFiles.length} 個檔案`, 'green');
    }
  }

  if (options.mode !== 'core-only') {
    const skillsPath = path.join(targetDir, 'skills');
    if (fs.existsSync(skillsPath)) {
      log('📊 已安裝的 Skills：', 'green');
      const skills = fs.readdirSync(skillsPath).filter(f => {
        return fs.statSync(path.join(skillsPath, f)).isDirectory();
      });
      skills.forEach(skill => {
        log(`   • ${skill}`, 'green');
      });
    }
  }

  // 下一步提示
  log('', 'reset');
  log('💡 下一步：', 'yellow');

  if (options.ide === 'cursor') {
    log('   1. 重新啟動 Cursor', 'reset');
    log('   2. 在 Chat 輸入: @go-ddd 如何設計 Aggregate Root？', 'blue');
  } else {
    log('   1. 打開 VS Code / Cursor', 'reset');
    log('   2. 在 Copilot Chat 輸入: \'這個專案有哪些 Skills？\'', 'blue');
    log('   3. 測試觸發: \'如何實作 DDD Aggregate Root？\'', 'blue');
  }

  log('', 'reset');
  log(`📚 查看完整文件: ${targetDir}/INSTALLATION.md`, 'cyan');
  log('', 'reset');
}

// 主程式
function main() {
  const options = parseArgs();

  if (options.help) {
    showHelp();
    process.exit(0);
  }

  try {
    install(options);
  } catch (error) {
    log('', 'reset');
    log('❌ 安裝失敗', 'red');
    log(`錯誤: ${error.message}`, 'red');
    log('', 'reset');
    log('如需協助，請訪問: https://github.com/vincent119/copilot-rules-kit/issues', 'cyan');
    process.exit(1);
  }
}

main();
