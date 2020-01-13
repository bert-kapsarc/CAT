General Idea concerning "the bin" and pricing mechanics
    We may need to have some sort of generalized Supply and Demand function that tracks the gold in the system
    If we can stack the stampers from cheapest to most expensive, and the gold they have available, we can line it up against the level of demand for gold and determine the marginal price that everyone would pay at that particular moment.
    So, something like (pseudocode):
    uint demand = x;
    uint supply = 0;
    uint price = 0;
    while (supply<demand){
        find next cheapest stamper;
        supply += stampergold;
        price = stamperprice;
    }
    return current gold price;
    
    This would also allow us to ensure the cheapest stampers are always favored and get a good price.
    It would inccrease the number of tranzactions, however, as it would mean one big order would be spread across many many stampers. Not sure how to optimize that at the moment.
