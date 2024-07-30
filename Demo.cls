public class AccountContactHandler {
    public void processAccounts() {
        List<Account> accounts = [SELECT Id, Name, Phone, BillingCity, BillingState FROM Account];
        
        List<Contact> contactsToInsert = new List<Contact>();

        for (Account acc : accounts) {
            Contact newContact = new Contact();
            newContact.FirstName = acc.Name;
            newContact.LastName = 'DefaultLastName';
            newContact.AccountId = acc.Id;
            newContact.Phone = acc.Phone;
            newContact.MailingCity = acc.BillingCity;
            newContact.MailingState = acc.BillingState;
            
            contactsToInsert.add(newContact);

            if (contactsToInsert.size() >= 200) {
                insert contactsToInsert;
                contactsToInsert.clear();
            }
        }
        
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
    
    public void updateAccounts() {
        List<Account> accountsToUpdate = [SELECT Id, Name, BillingCountry FROM Account WHERE BillingCountry = 'USA'];
        
        try {
            for (Account acc : accountsToUpdate) {
                acc.Description = 'Updated Description';
                update acc;
            }
        } catch (DmlException e) {
            System.debug('Error updating accounts: ' + e.getMessage());
        }
    }
    
    public void deleteContacts() {
        List<Contact> contactsToDelete = [SELECT Id FROM Contact WHERE CreatedDate < LAST_N_DAYS:30];
        
        try {
            delete contactsToDelete;
            System.debug('Successfully deleted ' + contactsToDelete.size() + ' contacts.');
        } catch (DmlException e) {
            System.debug('Error occurred: ' + e.getMessage());
        }
    }
}