package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
	"github.com/Azure/go-amqp"
)

func getOrdersFromQueue() ([]Order, error) {
	ctx := context.Background()

	var orders []Order

	// Get queue name from environment variable
	orderQueueName := os.Getenv("ORDER_QUEUE_NAME")
	if orderQueueName == "" {
		log.Printf("ORDER_QUEUE_NAME is not set")
		return nil, errors.New("ORDER_QUEUE_URI is not set")
	}

	// check if USE_WORKLOAD_IDENTITY_AUTH is set
	useWorkloadIdentityAuth := os.Getenv("USE_WORKLOAD_IDENTITY_AUTH")
	if useWorkloadIdentityAuth == "" {
		useWorkloadIdentityAuth = "false"
	}

	orderQueueHostName := os.Getenv("AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE")
	if orderQueueHostName == "" {
		orderQueueHostName = os.Getenv("ORDER_QUEUE_HOSTNAME")
	}

	if orderQueueHostName != "" && useWorkloadIdentityAuth == "true" {
		cred, err := azidentity.NewDefaultAzureCredential(nil)
		if err != nil {
			log.Printf("failed to obtain a workload identity credential: %v", err)
			return nil, err
		}

		client, err := azservicebus.NewClient(orderQueueHostName, cred, nil)
		if err != nil {
			log.Printf("failed to obtain a service bus client with workload identity credential: %v", err)
			return nil, err
		} else {
			fmt.Println("successfully created a service bus client with workload identity credentials")
		}

		receiver, err := client.NewReceiverForQueue(orderQueueName, nil)
		if err != nil {
			log.Printf("failed to create receiver: %v", err)
			return nil, err
		}
		defer receiver.Close(context.TODO())

		messages, err := receiver.ReceiveMessages(context.TODO(), 10, nil)
		if err != nil {
			log.Printf("failed to receive messages: %v", err)
			return nil, err
		}

		for _, message := range messages {
			log.Printf("message received: %s\n", string(message.Body))

			// First, unmarshal the JSON data into a string
			var jsonStr string
			err = json.Unmarshal(message.Body, &jsonStr)
			if err != nil {
				// Poison message: log loudly, drop it (complete) so it does
				// not redeliver-loop every fetch, and keep processing the rest.
				log.Printf("dropping poison message that failed to deserialize: %s", err)
				if cerr := receiver.CompleteMessage(context.TODO(), message, nil); cerr != nil {
					log.Printf("failed to complete poison message: %v", cerr)
				}
				continue
			}

			// Then, unmarshal the string into an Order
			order, err := unmarshalOrderFromQueue([]byte(jsonStr))
			if err != nil {
				log.Printf("dropping poison message that failed to unmarshal: %v", err)
				if cerr := receiver.CompleteMessage(context.TODO(), message, nil); cerr != nil {
					log.Printf("failed to complete poison message: %v", cerr)
				}
				continue
			}

			// Add order to []order slice
			orders = append(orders, order)

			err = receiver.CompleteMessage(context.TODO(), message, nil)
			if err != nil {
				// At-least-once: the message will redeliver and may insert a
				// duplicate order on the next fetch - logged, never fatal.
				log.Printf("failed to complete message (will redeliver): %v", err)
			}
		}
	} else {
		// Get order queue connection string from environment variable
		orderQueueUri := os.Getenv("ORDER_QUEUE_URI")
		if orderQueueUri == "" {
			log.Printf("ORDER_QUEUE_URI is not set")
			return nil, errors.New("ORDER_QUEUE_URI is not set")
		}

		// Get queue username from environment variable
		orderQueueUsername := os.Getenv("ORDER_QUEUE_USERNAME")
		if orderQueueName == "" {
			log.Printf("ORDER_QUEUE_USERNAME is not set")
			return nil, errors.New("ORDER_QUEUE_USERNAME is not set")
		}

		// Get queue password from environment variable
		orderQueuePassword := os.Getenv("ORDER_QUEUE_PASSWORD")
		if orderQueuePassword == "" {
			log.Printf("ORDER_QUEUE_PASSWORD is not set")
			return nil, errors.New("ORDER_QUEUE_PASSWORD is not set")
		}

		// Connect to order queue
		conn, err := amqp.Dial(ctx, orderQueueUri, &amqp.ConnOptions{
			SASLType: amqp.SASLTypePlain(orderQueueUsername, orderQueuePassword),
		})
		if err != nil {
			log.Printf("%s: %s", "failed to connect to order queue", err)
			return nil, err
		}
		defer conn.Close()

		session, err := conn.NewSession(ctx, nil)
		if err != nil {
			log.Printf("unable to create a new session")
		}

		{
			// create a receiver
			receiver, err := session.NewReceiver(ctx, orderQueueName, nil)
			if err != nil {
				log.Printf("creating receiver link: %s", err)
				return nil, err
			}
			defer func() {
				ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
				receiver.Close(ctx)
				cancel()
			}()

			for {
				log.Printf("getting orders")

				ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
				defer cancel()

				// receive next message
				msg, err := receiver.Receive(ctx, nil)
				if err != nil {
					if err.Error() == "context deadline exceeded" {
						log.Printf("no more orders for you: %v", err.Error())
						break
					} else {
						return nil, err
					}
				}

				messageBody := string(msg.GetData())
				log.Printf("message received: %s\n", messageBody)

				order, err := unmarshalOrderFromQueue(msg.GetData())
				if err != nil {
					// Poison message: accept (drop) it so it does not
					// redeliver-loop every fetch, and keep draining the rest.
					log.Printf("dropping poison message that failed to unmarshal: %s", err)
					if aerr := receiver.AcceptMessage(context.TODO(), msg); aerr != nil {
						log.Printf("failure accepting poison message: %s", aerr)
					}
					continue
				}

				// Add order to []order slice
				orders = append(orders, order)

				// accept message
				if err = receiver.AcceptMessage(context.TODO(), msg); err != nil {
					log.Printf("failure accepting message: %s", err)
					// remove the order from the slice so that we pick it up on the next run
					orders = orders[:len(orders)-1]
				}
			}
		}
	}
	return orders, nil
}

func unmarshalOrderFromQueue(data []byte) (Order, error) {
	var order Order

	err := json.Unmarshal(data, &order)
	if err != nil {
		log.Printf("failed to unmarshal order: %v\n", err)
		return Order{}, err
	}

	// add orderkey to order: nanosecond timestamp - unique without collisions
	// (the old rand.Intn(100000) wrapped and duplicated IDs at demo load),
	// still numeric so the Atoi sanitize paths in getOrder/updateOrder work.
	order.OrderID = strconv.FormatInt(time.Now().UnixNano(), 10)

	// set the status to pending
	order.Status = Pending

	return order, nil
}
