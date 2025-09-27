const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      contextIsolation: true,
    },
  });

  mainWindow.loadFile(path.join(__dirname, '../dist/zentoner/browser/index.html'));
}

app.whenReady().then(createWindow);
