// main.js – Electron entry point that runs the full setup workflow
const { app, BrowserWindow, dialog } = require('electron');
const path = require('path');
const { execSync } = require('child_process');

function runCmd(command, cwd) {
  console.log(`▶ ${command}`);
  execSync(command, { stdio: 'inherit', cwd });
}

function installPrereqs() {
  const script = path.join(__dirname, '..', 'scripts', 'install_prereqs.ps1');
  runCmd(`powershell -ExecutionPolicy Bypass -File "${script}"`);
}

function buildUI() {
  const uiPath = path.join(__dirname, '..', 'ui');
  runCmd('npm ci', uiPath);
  runCmd('npm run build', uiPath);
  runCmd('npm run pkg', uiPath);
}

function provisionCluster() {
  const vagrantPath = path.join(__dirname, '..', 'vagrant');
  runCmd('vagrant plugin install vagrant-vbguest', vagrantPath);
  runCmd('vagrant up', vagrantPath);
}

function registerService() {
  const script = path.join(__dirname, '..', 'scripts', 'register_service.ps1');
  runCmd(`powershell -ExecutionPolicy Bypass -File "${script}"`);
}

function createShortcut() {
  const script = path.join(__dirname, '..', 'scripts', 'create_shortcut.ps1');
  runCmd(`powershell -ExecutionPolicy Bypass -File "${script}"`);
}

function runSetupWizard() {
  try {
    installPrereqs();
    buildUI();
    provisionCluster();
    registerService();
    createShortcut();
    dialog.showMessageBoxSync({
      type: 'info',
      title: 'Orbit‑Cloud Setup Wizard',
      message: '✅ Setup completed successfully!\n\n' +
        '• UI runs as a Windows service and starts on boot.\n' +
        '• Open http://localhost:3000 to view the dashboard.\n' +
        '• Desktop shortcut also created.'
    });
  } catch (err) {
    dialog.showErrorBox('Setup Failed', `❌ ${err.message}`);
    console.error(err);
  }
}

function createWindow() {
  const win = new BrowserWindow({
    width: 500,
    height: 300,
    resizable: false,
    title: 'Orbit‑Cloud Setup Wizard',
    webPreferences: { preload: path.join(__dirname, 'preload.js') }
  });
  win.loadFile(path.join(__dirname, 'wizard.html'));
}

app.whenReady().then(() => {
  createWindow();
  setTimeout(runSetupWizard, 500);
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
