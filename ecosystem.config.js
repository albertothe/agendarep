module.exports = {
    apps: [
        {
            name: 'agendarep-backend',
            cwd: './backend',
            script: './node_modules/.bin/ts-node.cmd',
            args: 'src/index.ts',
            interpreter: 'cmd.exe',
            env: {
                NODE_ENV: 'production'
            }
        },
        {
            name: 'agendarep-frontend',
            cwd: './frontend',
            script: '../node_modules/serve/build/main.js',
            interpreter: 'node',
            args: ['-s', 'dist', '-l', '8500', '--single'],
            env: {
                NODE_ENV: 'production'
            }
        }
    ]
}
