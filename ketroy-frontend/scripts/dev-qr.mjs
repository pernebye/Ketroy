import { spawn } from 'child_process';
import { networkInterfaces } from 'os';
import qrcode from 'qrcode-terminal';

// Получаем локальный IP адрес
function getLocalIP() {
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Пропускаем не IPv4 и internal (loopback) адреса
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

const PORT = 3000;
const localIP = getLocalIP();
const networkUrl = `http://${localIP}:${PORT}`;

console.log('\n');
console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║                    🚀 KETROY ADMIN DEV                     ║');
console.log('╠════════════════════════════════════════════════════════════╣');
console.log(`║  Local:    http://localhost:${PORT}                          ║`);
console.log(`║  Network:  ${networkUrl.padEnd(45)}║`);
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('\n📱 Отсканируйте QR-код для доступа с телефона:\n');

// Генерируем QR-код
qrcode.generate(networkUrl, { small: true }, (qr) => {
  console.log(qr);
  console.log(`\n🔗 ${networkUrl}\n`);
  console.log('━'.repeat(60));
  console.log('\n');
});

// Запускаем Nuxt dev с --host для доступа по сети
const nuxt = spawn('npx', ['nuxt', 'dev', '--dotenv', '.env.development', '--host', '0.0.0.0', '--port', PORT.toString()], {
  stdio: 'inherit',
  shell: true,
  cwd: process.cwd()
});

nuxt.on('close', (code) => {
  process.exit(code);
});

// Обработка сигналов завершения
process.on('SIGINT', () => {
  nuxt.kill('SIGINT');
});

process.on('SIGTERM', () => {
  nuxt.kill('SIGTERM');
});







