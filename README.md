Gekko
=

## What Gekko is
Gekko is intended to become a high-performance in-memory trade order matching engine. It works by a having an EventMachine-based network listener running along with one matching process per currency pair.

## What Gekko is not
Gekko is not intended to maintain an accounting database, it just matches trade orders associated to accounts, and returns the necessary data for an accounting system to record the trades (usually against some sort of RDBMS).

Gekko expects to be instructed with the account margins in order to not trade more than what is allowed. In other words the accounting system should instruct Gekko with the amount that may not be withdrawn against accounts.

## How does Gekko work ?
Gekko works by spawning a networ listener process that accepts regular TCP connections over which clients input their orders.

This flow is de-multiplexed and fed into relevant Redis queues, on the other side of the queue a matching process pops orders sequentially and matches them against its order book. It returns the results through Redis to the network listener that streams them to the relevant clients.

## What features will it have ?
The following things are on the roadmap :

* Advanced orders (stops, trailing stops, discretionary, multi-legged etc.)
* FIX interface
* Websocket interface
* Flexible fee calculation scheme
* ...

