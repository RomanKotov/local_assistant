process.stdin.on('data', console.log);
process.stdin.on('end', () => process.exit(0));
