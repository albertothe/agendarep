//b3brain/ecosystem.config.js
module.exports = {
    apps: [
        {
            name: 'agendarep-backend',
            cwd: './backend',
            script: 'node_modules/ts-node/dist/bin.js',
            args: 'src/index.ts',
            env: {
                NODE_ENV: 'production'
            }
        },
        {
            name: 'agendarep-frontend',
            cwd: './frontend',
            interpreter: 'node',
            script: '../node_modules/serve/build/main.js',
            args: ['-s', 'dist', '-l', '8500', '--single'],
            env: {
                NODE_ENV: 'production'
            }
        }


    ]
}
