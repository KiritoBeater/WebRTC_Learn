const WebSocket = require('ws');
const uuidv1 = require('uuid/v1');
const wss = new WebSocket.Server({port: 8080});

var members = {};

function handleMessage(message) {
  let jsObject = JSON.parse(message)
  console.log(jsObject)
  let memberId = jsObject.memberId
  let ws = members[memberId].ws
  if (jsObject.type === 'Offer') {
    
  } else if (jsObject.type === 'Ansser') {

  } else if (jsObject.type === 'IceCandidate') {

  } else if (jsObject.type === 'Close') {

  }
}

wss.on('connection', function connection(ws) {
  let memberId = uuidv1()
  members[memberId] = {ws: ws};
  let response = JSON.stringify({type: 'JoinRoom', data: {id: memberId, otherId: []}})
  let buf = Buffer.from(response, 'utf8')
  ws.send(buf)

  ws.on('message', function incoming(message) {
    handleMessage(message)
  })
});