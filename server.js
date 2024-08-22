const http = require('http');
const os = require('os');

const interfaces = os.networkInterfaces();

const requestListener = function (req, res) {
  let ipAddress;

  for (const interfaceName in interfaces) {
    for (const iface of interfaces[interfaceName]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ipAddress = iface.address;
        break;
      }
    }
    if (ipAddress) break;
  }

  res.writeHead(200);
  res.end(`Hello, World! This is a simple Node.js server running on ${ipAddress}`);
}

const server = http.createServer(requestListener);

server.listen(8080);
