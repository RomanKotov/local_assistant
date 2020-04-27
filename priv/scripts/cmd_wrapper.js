const {spawn} = require('child_process');

const [program, ...args] = process.argv.slice(2);
const command = spawn(program, args);

command.on("close", code => process.exit(code));

process.stdin.pipe(command.stdin);
command.stdout.pipe(process.stdout);
command.stderr.pipe(process.stderr);

process.stdin.on('end', () => {
  command.kill('SIGKILL');
  process.exit(1);
});
