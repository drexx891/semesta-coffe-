const puppeteer = require('puppeteer');
const http = require('http');
const fs = require('fs');
const path = require('path');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.wasm': 'application/wasm'
};

const server = http.createServer((req, res) => {
  let filePath = path.join(__dirname, 'build/web', req.url === '/' ? 'index.html' : req.url);
  let extname = String(path.extname(filePath)).toLowerCase();
  if (!fs.existsSync(filePath)) {
    filePath = path.join(__dirname, 'build/web', 'index.html');
    extname = '.html';
  }
  const contentType = MIME_TYPES[extname] || 'application/octet-stream';
  fs.readFile(filePath, (error, content) => {
    if (error) {
      res.writeHead(500);
      res.end('Error: ' + error.code + ' ..\n');
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(8080, async () => {
  console.log('Server running at http://127.0.0.1:8080/');
  try {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.setViewport({ width: 375, height: 812, isMobile: true });
    
    page.on('console', msg => console.log('PAGE LOG:', msg.text()));
    page.on('pageerror', error => console.log('PAGE ERROR:', error.message));
    
    console.log('Navigating to app...');
    await page.goto('http://127.0.0.1:8080/');
    
    await new Promise(r => setTimeout(r, 6000));
    
    console.log('Clicking Lainnya...');
    await page.mouse.click(338, 782);
    
    await new Promise(r => setTimeout(r, 2000));
    
    console.log('Clicking Shift...');
    await page.mouse.click(100, 600);
    
    await new Promise(r => setTimeout(r, 3000));
    console.log('Done testing.');

    await browser.close();
    server.close();
    process.exit(0);
  } catch (err) {
    console.error(err);
    server.close();
    process.exit(1);
  }
});
