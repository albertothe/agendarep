module.exports = {
    apps: [
        {
            name: 'agendarep-backend',
            cwd: './backend',
            script: 'dist/server.js', // não use ts-node, use o build!
            interpreter: 'node',
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
