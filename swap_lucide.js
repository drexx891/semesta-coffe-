const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

let count = 0;
walkDir('lib', function(filePath) {
  if (filePath.endsWith('.dart')) {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    content = content.replace(/package:lucide_icons\/lucide_icons\.dart/g, 'package:flutter_lucide/flutter_lucide.dart');

    if (content !== original) {
      fs.writeFileSync(filePath, content, 'utf8');
      count++;
      console.log(`Updated imports in: ${filePath}`);
    }
  }
});
console.log(`Total files updated: ${count}`);
