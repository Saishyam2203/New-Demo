public class AccountTriggerHandler {
    public void processAccountTrigger(List<Account> accounts) {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        List<Quote> quotesToInsert = new List<Quote>();
        List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();

        List<Product2> products = [SELECT Id, Name, Family, StandardPrice FROM Product2 WHERE Family = 'Hardware'];

        Map<Id, Opportunity> accountOpportunityMap = new Map<Id, Opportunity>();
        for (Account acc : accounts) {
            Opportunity opp = new Opportunity();
            opp.Name = acc.Name + ' Opportunity';
            opp.AccountId = acc.Id;
            opp.StageName = 'Prospecting';
            opp.CloseDate = System.today(); // Set close date to today
            opportunitiesToInsert.add(opp);
            accountOpportunityMap.put(acc.Id, opp);
        }
        insert opportunitiesToInsert;

        for (Opportunity opportunity : opportunitiesToInsert) {
            Account acc = accountOpportunityMap.get(opportunity.AccountId);
            Quote quote = new Quote();
            quote.Name = opportunity.Name + ' Quote';
            quote.OpportunityId = opportunity.Id;
            quote.AccountId = acc.Id;
            quote.Status = 'Draft';
            quotesToInsert.add(quote);
        }
        insert quotesToInsert;

        for (Quote q : quotesToInsert) {
            for (Product2 prod : products) {
                QuoteLineItem quoteLineItem = new QuoteLineItem();
                quoteLineItem.QuoteId = q.Id;
                quoteLineItem.Product2Id = prod.Id;
                quoteLineItem.UnitPrice = prod.StandardPrice;
                quoteLineItem.Quantity = 1;
                quoteLineItemsToInsert.add(quoteLineItem);
            }
        }
        insert quoteLineItemsToInsert;
    }
}