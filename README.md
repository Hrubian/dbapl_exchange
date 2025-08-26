# Simple Commodity Exchange
Homework for the Database Applications subject at MFF - simple commodity exchange.

### Business logic

In the commodity exchange, one can trade various **Products**, such as Wheat, Gold, Coffee, Sugar etc.

Each Product can be traded in different **Contracts** with different trading start 
(corresponding to for example Sugar for August or September).
The Contract is active from the trading start until it is manually set as expired.
Once the Contract reaches its lifetime, it expires.

The user of the exchange who is trading the goods is called Market **Participant**.
The participant has set (by the exchange) the limits of how much of a given good they can buy or sell
(see ParticipantAllowedProducts table).

Each user can create an **Order** on any active contract within the user limit.
by placing on Order in the order-book, they say "I would like to sell/buy {quantity} of {product} for {price}."
The user can later modify their order by changing its price or quantity or cancel the order, signifying that
he no longer has interest in the deal.

// TODO: explain trades, PNL, position. settlement price

### Creation
The scripts for the DB creation can be found in the creation/ directory. 
First execute the scripts in Tables.sql, the all the others.

### Testing
There is a script InitDataInsert.sql which inserts some default data - products, contracts
and users with non-zero limits.

Then all the testing scripts are in the tests/ directory.
