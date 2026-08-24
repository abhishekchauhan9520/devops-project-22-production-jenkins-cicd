const http = require('http');

const port = Number(process.env.PORT || 3000);
const version = process.env.APP_VERSION || 'dev';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', version }));
    return;
  }

  if (req.url === '/ready') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ready', version }));
    return;
  }

  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ message: 'Project 22 Jenkins CI/CD demo', version }));
});

server.listen(port, '0.0.0.0', () => {
  console.log(`server listening on ${port}`);
});
