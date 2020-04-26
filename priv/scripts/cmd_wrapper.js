const {spawn} = require('child_process');

const command = spawn('cat');

command.on("close", code => process.exit(code));

process.stdin.pipe(command.stdin);
command.stdout.pipe(process.stdout);
command.stderr.pipe(process.stderr);

process.stdin.on('end', () => {
  command.kill('SIGKILL');
  process.exit(1);
});
