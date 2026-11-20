'use strict'

const fp = require('fastify-plugin')
const rhea = require('rhea')

// One shared AMQP 1.0 container + connection for all sends. Connecting per
// message (3600/hr at demo load) burns a TCP+SASL handshake every time;
// links (senders) are still opened/closed per message, which is cheap.
const container = rhea.create_container()
let sharedConnection = null

container.on('disconnected', function () {
  console.log('message queue connection lost, will reconnect on next send')
  sharedConnection = null
})

function getConnection() {
  if (sharedConnection && sharedConnection.is_open()) {
    return sharedConnection
  }
  const connectOptions = {
    hostname: process.env.ORDER_QUEUE_HOSTNAME,
    host: process.env.ORDER_QUEUE_HOSTNAME,
    port: process.env.ORDER_QUEUE_PORT,
    username: process.env.ORDER_QUEUE_USERNAME,
    password: process.env.ORDER_QUEUE_PASSWORD,
    reconnect_limit: process.env.ORDER_QUEUE_RECONNECT_LIMIT || 0
  }

  if (process.env.ORDER_QUEUE_TRANSPORT !== undefined) {
    connectOptions.transport = process.env.ORDER_QUEUE_TRANSPORT
  }

  sharedConnection = container.connect(connectOptions)
  return sharedConnection
}

module.exports = fp(async function (fastify, opts) {
  fastify.decorate('sendMessage', function (message) {
    const body = message.toString()
    if (process.env.ORDER_QUEUE_USERNAME && process.env.ORDER_QUEUE_PASSWORD) {
      console.log(`sending message ${body} to ${process.env.ORDER_QUEUE_NAME} on ${process.env.ORDER_QUEUE_HOSTNAME} using local auth credentials`)

      const amqp_message = container.message
      const connection = getConnection()

      const sender = connection.open_sender(process.env.ORDER_QUEUE_NAME)
      sender.once('sendable', function () {
        sender.send({
          body: amqp_message.data_section(Buffer.from(body, 'utf8'))
        })
        sender.close()
      })
      sender.once('error', function (err) {
        console.log(`message queue sender error: ${err}`)
      })
    } else if (process.env.USE_WORKLOAD_IDENTITY_AUTH === 'true') {
      const { ServiceBusClient } = require("@azure/service-bus");
      const { DefaultAzureCredential } = require("@azure/identity");

      const fullyQualifiedNamespace = process.env.ORDER_QUEUE_HOSTNAME || process.env.AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE;

      console.log(`sending message ${body} to ${process.env.ORDER_QUEUE_NAME} on ${fullyQualifiedNamespace} using Microsoft Entra ID Workload Identity credentials`);
      
      if (!fullyQualifiedNamespace) {
        console.log('no hostname set for message queue. exiting.');
        return;
      }
      
      const queueName = process.env.ORDER_QUEUE_NAME

      const credential = new DefaultAzureCredential();

      async function sendMessage() {
        const sbClient = new ServiceBusClient(fullyQualifiedNamespace, credential);
        const sender = sbClient.createSender(queueName);

        try {
          await sender.sendMessages({ body: body });
        } finally {
          await sender.close();
          await sbClient.close();
        }
      }
      sendMessage().catch(console.error);
    } else {
      console.log('no credentials set for message queue. exiting.')
      return
    }
  })
})
