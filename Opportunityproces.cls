public class OpportunityProcessor {
    // Custom labels for hardcoded values
    public static final String TASK_SUBJECT = Label.Task_Subject;
    public static final String TASK_PRIORITY = Label.Task_Priority;
    public static final String TASK_STATUS = Label.Task_Status;
    public static final Integer BATCH_SIZE = 5;
    public static final Integer HIGH_VALUE_AMOUNT = 1000;
    public static final Integer OLD_TASK_DAYS = 60;

    /**
     * Processes opportunities and creates follow-up tasks.
     */
    public void processOpportunities() {
        List<Opportunity> opportunities = [SELECT Id, Name, Amount, StageName, CloseDate FROM Opportunity];
        List<Task> tasksToCreate = new List<Task>();

        for (Opportunity opp : opportunities) {
            Task task = new Task();
            task.Subject = TASK_SUBJECT;
            task.WhatId = opp.Id;
            task.Priority = TASK_PRIORITY;
            task.Status = TASK_STATUS;
            task.ActivityDate = opp.CloseDate;
            task.Description = 'Follow up on the opportunity named ' + opp.Name;
            
            tasksToCreate.add(task);

            if (tasksToCreate.size() >= BATCH_SIZE) {
                insert tasksToCreate;
                tasksToCreate.clear();
            }
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }

    /**
     * Sends email notifications for high-value opportunities.
     */
    public void sendEmailNotifications() {
        List<Opportunity> opportunities = [SELECT Id, Name, Owner.Email FROM Opportunity WHERE Amount > :HIGH_VALUE_AMOUNT];
        
        for (Opportunity opp : opportunities) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {opp.Owner.Email});
            mail.setSubject('High-Value Opportunity');
            mail.setPlainTextBody('Opportunity ' + opp.Name + ' has a high value.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }

    /**
     * Closes opportunities that are in the 'Negotiation/Review' stage for too long.
     */
    public void closeLostOpportunities() {
        List<Opportunity> oppsToClose = [SELECT Id, Name FROM Opportunity WHERE StageName = 'Negotiation/Review'];
        
        for (Opportunity opp : oppsToClose) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Automatically closed due to prolonged negotiation.';
        }
        
        update oppsToClose;
    }

    /**
     * Deletes tasks that are older than a specified number of days.
     */
    public void deleteOldTasks() {
        List<Task> tasksToDelete = [SELECT Id FROM Task WHERE CreatedDate < LAST_N_DAYS:OLD_TASK_DAYS];
        
        try {
            delete tasksToDelete;
        } catch (DmlException e) {
            System.debug('Failed to delete tasks: ' + e.getMessage());
        }
    }
}
