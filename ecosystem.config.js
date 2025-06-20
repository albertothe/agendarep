//b3brain/ecosystem.config.js
module.exports = {
    apps: [
        {
            name: 'b3b-backend',
            cwd: './backend',
            script: 'node_modules/ts-node/dist/bin.js',
            args: 'src/index.ts',
            env: {
                NODE_ENV: 'production'
            }
        },
        {
            name: 'b3b-frontend',
            cwd: './frontend',
            interpreter: 'node',
            script: '../node_modules/serve/build/main.js',
            args: ['-s', 'dist', '-l', '9500', '--single'],
            env: {
                NODE_ENV: 'production'
            }
        }


    ]
}
