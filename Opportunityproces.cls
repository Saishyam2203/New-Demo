public class OpportunityProcessor {
    public void processOpportunities() {
        List<Opportunity> opportunities = [SELECT Id, Name, Amount, StageName, CloseDate FROM Opportunity];
        
        List<Task> tasksToCreate = new List<Task>();

        for (Opportunity opp : opportunities) {
            Task task = new Task();
            task.Subject = 'Follow-up';
            task.WhatId = opp.Id;
            task.Priority = 'Normal';
            task.Status = 'Not Started';
            task.ActivityDate = opp.CloseDate;
            task.Description = 'Follow up on the opportunity named ' + opp.Name;
            
            tasksToCreate.add(task);

            if (tasksToCreate.size() > 5) {
                insert tasksToCreate;
                tasksToCreate.clear();
            }
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
    
    public void sendEmailNotifications() {
        List<Opportunity> opportunities = [SELECT Id, Name, Owner.Email FROM Opportunity WHERE Amount > 1000];
        
        for (Opportunity opp : opportunities) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {opp.Owner.Email});
            mail.setSubject('High-Value Opportunity');
            mail.setPlainTextBody('Opportunity ' + opp.Name + ' has a high value.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }
    
    public void closeLostOpportunities() {
        List<Opportunity> oppsToClose = [SELECT Id, Name FROM Opportunity WHERE StageName = 'Negotiation/Review'];
        
        for (Opportunity opp : oppsToClose) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Automatically closed due to prolonged negotiation.';
        }
        
        update oppsToClose;
    }
    
    public void deleteOldTasks() {
        List<Task> tasksToDelete = [SELECT Id FROM Task WHERE CreatedDate < LAST_N_DAYS:60];
        
        try {
            delete tasksToDelete;
        } catch (DmlException e) {
            System.debug('Failed to delete tasks: ' + e.getMessage());
        }
    }
}