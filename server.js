const http = require('http');
const os = require('os');

const interfaces = os.networkInterfaces();

const requestListener = function (req, res) {
  let ipAddresses = [];

  for (const interfaceName in interfaces) {
    for (const iface of interfaces[interfaceName]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ipAddresses.push(`Interface: ${interfaceName}, Address: ${iface.address}`);
      }
    }
  }

  const responseText = `Hello, World! This is a simple Node.js server.\n\nIP Addresses:\n${ipAddresses.join('\n')}\n`;

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(responseText);
}

const server = http.createServer(requestListener);

server.listen(8080);
