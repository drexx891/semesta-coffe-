const fs = require('fs');
const path = require('path');

const iconMap = {
  'LucideIcons.trash2': 'LucideIcons.trash_2',
  'LucideIcons.shoppingCart': 'LucideIcons.shopping_cart',
  'LucideIcons.userCheck': 'LucideIcons.user_check',
  'LucideIcons.alertTriangle': 'LucideIcons.triangle_alert',
  'LucideIcons.checkCircle': 'LucideIcons.circle_check',
  'LucideIcons.layoutGrid': 'LucideIcons.layout_grid',
  'LucideIcons.logIn': 'LucideIcons.log_in',
  'LucideIcons.packageSearch': 'LucideIcons.package_search',
  'LucideIcons.userPlus': 'LucideIcons.user_plus',
  'LucideIcons.qrCode': 'LucideIcons.qr_code',
  'LucideIcons.creditCard': 'LucideIcons.credit_card',
  'LucideIcons.shieldCheck': 'LucideIcons.shield_check',
  'LucideIcons.eyeOff': 'LucideIcons.eye_off',
  'LucideIcons.calendarDays': 'LucideIcons.calendar_days',
  'LucideIcons.calendarCheck': 'LucideIcons.calendar_check',
  'LucideIcons.logOut': 'LucideIcons.log_out',
  'LucideIcons.fileText': 'LucideIcons.file_text',
  'LucideIcons.plusCircle': 'LucideIcons.circle_plus',
  'LucideIcons.minusCircle': 'LucideIcons.circle_minus',
  'LucideIcons.eye': 'LucideIcons.eye',
  'LucideIcons.unlock': 'LucideIcons.unlock',
  'LucideIcons.lock': 'LucideIcons.lock',
  'LucideIcons.coffee': 'LucideIcons.coffee',
  'LucideIcons.ticket': 'LucideIcons.ticket',
  'LucideIcons.alertCircle': 'LucideIcons.circle_alert',
  'LucideIcons.helpCircle': 'LucideIcons.circle_help',
  'LucideIcons.xCircle': 'LucideIcons.circle_x',
  'LucideIcons.info': 'LucideIcons.info',
  'LucideIcons.settings': 'LucideIcons.settings',
  'LucideIcons.users': 'LucideIcons.users',
  'LucideIcons.activity': 'LucideIcons.activity',
  'LucideIcons.fileOutput': 'LucideIcons.file_output',
  'LucideIcons.arrowDownCircle': 'LucideIcons.circle_arrow_down',
  'LucideIcons.arrowUpCircle': 'LucideIcons.circle_arrow_up',
  'LucideIcons.history': 'LucideIcons.history',
  'LucideIcons.fileDown': 'LucideIcons.file_down',
  'LucideIcons.percent': 'LucideIcons.percent',
  'LucideIcons.x': 'LucideIcons.x',
  'LucideIcons.chevronRight': 'LucideIcons.chevron_right',
  'LucideIcons.chevronLeft': 'LucideIcons.chevron_left',
  'LucideIcons.chevronDown': 'LucideIcons.chevron_down',
  'LucideIcons.chevronUp': 'LucideIcons.chevron_up',
  'LucideIcons.printer': 'LucideIcons.printer',
  'LucideIcons.check': 'LucideIcons.check',
  'LucideIcons.edit': 'LucideIcons.pencil', // edit was renamed to pencil? or maybe just edit?
  'LucideIcons.clock3': 'LucideIcons.clock_3',
  'LucideIcons.barChart': 'LucideIcons.chart_column_big', // or chart_bar
  'LucideIcons.fingerprint': 'LucideIcons.fingerprint_pattern',
  'LucideIcons.moreHorizontal': 'LucideIcons.ellipsis',
  'LucideIcons.unlock': 'LucideIcons.lock_open',
};

// Check actual available icons
const availableIconsStr = fs.readFileSync('lucide_icons_list.txt', 'utf8');
const availableIcons = new Set(availableIconsStr.split('\n').map(i => i.trim()).filter(Boolean));

function resolveIconName(target) {
  let mapped = iconMap[target];
  if (mapped) {
    let rawIcon = mapped.split('.')[1];
    if (availableIcons.has(rawIcon)) return mapped;
    if (availableIcons.has(rawIcon.replace(/_/g, ''))) return 'LucideIcons.' + rawIcon.replace(/_/g, '');
    return mapped; // hope for best
  }
  return null;
}

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    if (fs.statSync(dirPath).isDirectory()) {
      walkDir(dirPath, callback);
    } else {
      callback(path.join(dir, f));
    }
  });
}

let fixCount = 0;
walkDir('lib', function(filePath) {
  if (filePath.endsWith('.dart')) {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    // Convert all remaining LucideIcons.camelCase to snake_case if we missed it
    content = content.replace(/LucideIcons\.([a-zA-Z0-9_]+)/g, (match, p1) => {
      let resolved = resolveIconName('LucideIcons.' + p1);
      if (resolved) return resolved;
      
      // Auto convert camelCase to snake_case
      let snake = p1.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      if (availableIcons.has(snake)) {
        return `LucideIcons.${snake}`;
      }
      return match;
    });

    if (content !== original) {
      fs.writeFileSync(filePath, content, 'utf8');
      fixCount++;
      console.log(`Fixed icons in: ${filePath}`);
    }
  }
});
console.log(`Total files fixed: ${fixCount}`);
