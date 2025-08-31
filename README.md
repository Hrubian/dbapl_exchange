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

If, on a given contract, there is a buy order and sell order 
and the price of the buy order is the same or lower than the price of the sell order,
a trade is created with a quantity equal to the min of the quantities of the two orders 
and the quantities of the order are decreased by this quantity.
If the order reaches zero quantity, it is deactivated (same as if it was cancelled).
If the order quantity reached zero by a trade, we say that the order was **fully filled**.
If the order quantity was partially decreased by a trade, we say that the order was **partially filled**.

The position of a participant on a given contract is the difference of sum of quantities of buy trades 
and sum of quantities of sell trades.

The PNL (profit and loss) on a given contract is given by the formula 
PNL = sum_over_buy_orders(price * quantity) - sum_over_sell_orders(price * quantity) + position * settlement_price.

The settlement price is set upon closing the contract.

PNL for a product is a sum of all PNLs over all closed contracts for the associated product.

Each user has assigned buy and sell limits.
The user can never go over these limits.
Sum of all buy trades and all active buy orders cannot be higher than buy limit (on a single contract).
The same applies for sell orders.

### Creation
The scripts for the DB creation can be found in the creation/ directory. 
First execute the scripts in Tables.sql, then Views.sql, then all the Packages.

### Statistics
Scripts for creation and deletion of statistics can be found in the stats/ directory.

### Testing
Go over the Tests.sql file and run the statements with explanatory comments one by one. 
The tests can be run only once after the creation of the database as there are assumptions 
about IDs and sequences.
If you want to run the tests again, drop the whole database using the Deletion.sql script.

### Packages
There are three packages

#### Admin package
Used for administration purposes.
You can create product, contract, user, close a contract (and assign a settlement price).

#### Orders package
Used for trading.
There are procedures for manipulating (creation, modification and cancellation) orders.
The package also includes the order matching logic in the MatchOrders procedure (probably the most interesting part of the project).

#### Trading Statistics package
Provides useful trading statistics - PNL reports for product and Positions for contracts.

### Views
There are the following views defined:
- ActiveOrders - filters out already fully-filled and cancelled orders
- l1 - also called best prices, summarizes the prices of the best buy and sell orders for each contract.
- ActiveParticipants - view of all participants with non-zero limits on at least one product (they can trade something).
- UsersTradedVolume - the total traded volume (sum of quantities) over all trades grouped by product (for all users together).
- TradesWithParticipants - quantities, prices, timestamps together with the buyer and seller's legal name.




