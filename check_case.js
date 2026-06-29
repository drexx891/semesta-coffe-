const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  let list = fs.readdirSync(dir);
  list.forEach(function(file) {
    file = path.join(dir, file);
    let stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      results.push(file);
    }
  });
  return results;
}

let files = walk('lib');
let map = new Map();
files.forEach(f => {
  map.set(f.replace(/\\/g, '/').toLowerCase(), f);
});

let mismatchCount = 0;
files.filter(f => f.endsWith('.dart')).forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  let regex = /import\s+['"]([^'"]+)['"]/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    let imp = match[1];
    if (imp.startsWith('package:') || imp.startsWith('dart:')) continue;
    let fullPath = path.join(path.dirname(f), imp).replace(/\\/g, '/');
    let lower = fullPath.toLowerCase();
    
    if (map.has(lower) && map.get(lower).replace(/\\/g, '/') !== fullPath) {
      console.log('Case mismatch in ' + f + ':\n  Import: ' + imp + '\n  Real File: ' + map.get(lower));
      mismatchCount++;
    }
  }
});
if (mismatchCount === 0) console.log('No case mismatches found.');
