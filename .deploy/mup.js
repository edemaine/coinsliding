module.exports = {
  servers: {
    one: {
      host: 'coinsliding.erikdemaine.org',
      username: 'ubuntu',
      pem: "/afs/csail/u/e/edemaine/.ssh/private/id_rsa"
      // pem:
      // password:
      // or leave blank for authenticate from ssh-agent
    }
  },

  // Meteor server
  meteor: {
    name: 'coinsliding',
    path: '/afs/csail/u/e/edemaine/Projects/coinsliding',
    servers: {
      one: {}
    },
    docker: {
      image: 'abernix/meteord:node-8.4.0-base', 
    },
    buildOptions: {
      serverOnly: true,
      buildLocation: '/scratch/coinsliding-build'
    },
    env: {
      ROOT_URL: 'https://coinsliding.erikdemaine.org',
      MONGO_URL: 'mongodb://mongodb/meteor',
      MONGO_OPLOG_URL: 'mongodb://mongodb/local'
    },
    deployCheckWaitTime: 200,
  },

  // Mongo server
  mongo: {
    oplog: true,
    port: 27017,
    servers: {
      one: {},
    },
  },

  // Reverse proxy for SSL
  proxy: {
    domains: 'coinsliding.erikdemaine.org,coinsliding.csail.mit.edu',
    ssl: {
      forceSSL: true,
      letsEncryptEmail: 'edemaine@mit.edu',
    },
    clientUploadLimit: '0', // disable upload limit
    //nginxServerConfig: '../.proxy.config',
  },

  // Run 'npm install' before deploying, to ensure packages are up-to-date
  hooks: {
    'pre.deploy': {
      localCommand: 'npm install'
    }
  },
};
