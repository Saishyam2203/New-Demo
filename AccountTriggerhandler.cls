public class AccountTriggerHandler {
    public void processAccountTrigger(List<Account> accs) {
        List<Opportunity> opsToInsert = new List<Opportunity>();
        List<Quote> qtsToInsert = new List<Quote>();
        List<QuoteLineItem> qlitsToInsert = new List<QuoteLineItem>();

        List<Product2> prods = [SELECT Id, Name, Family, StandardPrice FROM Product2 WHERE Family = 'Hardware'];

        for (Account a : accs) {
            Opportunity opp = new Opportunity();
            opp.Name = a.Name + ' Opportunity';
            opp.AccountId = a.Id;
            opp.StageName = 'Prospecting';
            opp.CloseDate = System.today();
            opsToInsert.add(opp);

            insert opsToInsert;

            for (Opportunity o : opsToInsert) {
                Quote qt = new Quote();
                qt.Name = o.Name + ' Quote';
                qt.OpportunityId = o.Id;
                qt.AccountId = a.Id;
                qt.Status = 'Draft';
                qtsToInsert.add(qt);

                insert qtsToInsert;

                for (Quote q : qtsToInsert) {
                    for (Product2 p : prods) {
                        QuoteLineItem qlit = new QuoteLineItem();
                        qlit.QuoteId = q.Id;
                        qlit.Product2Id = p.Id;
                        qlit.UnitPrice = p.StandardPrice;
                        qlit.Quantity = 1;
                        qlitsToInsert.add(qlit);

                        insert qlitsToInsert;
                    }
                }
            }
        }
    }