const fs = require('fs');
const path = require('path');

const exactReplacements = {
  'LucideIcons.shoppingCart_outlined': 'LucideIcons.shoppingCart',
  'LucideIcons.user_outline_rounded': 'LucideIcons.user',
  'LucideIcons.user_search_rounded': 'LucideIcons.userCheck',
  'LucideIcons.ticket_outlined': 'LucideIcons.ticket',
  'LucideIcons.ticketPercent': 'LucideIcons.ticket',
  'LucideIcons.ticketPercent_outlined': 'LucideIcons.ticket',
  'LucideIcons.triangleAlert_amber_rounded': 'LucideIcons.alertTriangle',
  'LucideIcons.printerer': 'LucideIcons.printer',
  'LucideIcons.plus_a_photo_rounded': 'LucideIcons.camera',
  'LucideIcons.stars_rounded': 'LucideIcons.star',
  'LucideIcons.user_add_rounded': 'LucideIcons.userPlus',
  'LucideIcons.eye_off': 'LucideIcons.eyeOff',
  'LucideIcons.triangleAlert': 'LucideIcons.alertTriangle',
  'LucideIcons.receiptText': 'LucideIcons.receipt',
  'LucideIcons.minus_circle': 'LucideIcons.minusCircle',
  'LucideIcons.lock_open_rounded': 'LucideIcons.unlock',
  'LucideIcons.plus_circle_outline_rounded': 'LucideIcons.plusCircle',
  'LucideIcons.notebookText': 'LucideIcons.fileText',
  'LucideIcons.coffee_outlined': 'LucideIcons.coffee',
  'LucideIcons.lock_outline_rounded': 'LucideIcons.lock',
  'LucideIcons.eyeOff_rounded': 'LucideIcons.eyeOff',
  'LucideIcons.ticket_outlined': 'LucideIcons.ticket',
};

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

    for (let key in exactReplacements) {
      if (content.includes(key)) {
        content = content.split(key).join(exactReplacements[key]);
      }
    }

    if (content !== original) {
      fs.writeFileSync(filePath, content, 'utf8');
      count++;
      console.log(`Fixed compile error in: ${filePath}`);
    }
  }
});
console.log(`Total files fixed: ${count}`);
