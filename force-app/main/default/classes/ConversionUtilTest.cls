@isTest
public class ConversionUtilTest {
    public static final RecordType RTBUSINESS= getRT('Business Account',false);
    public static final RecordType RTHOUSEHOLD= getRT('Household',false);
    public static final RecordType RTCLIENT=getRT('Client',true);
    
    private static void setup() {
        
    }
    private static testmethod void test1() {
        // 1. Start with a business account + 2 contacts that represent a "family household"
        System.Debug('Step1');   
        Account family = new Account(name='Bear Family', RecordTypeId=RTBUSINESS.Id);
        insert family;

        List<Contact> theFamilyMembers = new List<Contact>();
        theFamilyMembers.add(new Contact(firstName='Papa',lastName='Bear',accountId=family.Id));
        theFamilyMembers.add(new Contact(firstName='Mama',lastName='Bear',accountId=family.Id));
        theFamilyMembers.add(new Contact(firstName='Baby',lastName='Bear',accountId=family.Id));
        insert theFamilyMembers;
        
        // 2. Create a new Household Account so we can create ACR's
        System.Debug('Step2');
        Account household = new Account(name='Bear Household',RecordTypeId=RTHOUSEHOLD.Id);
        insert household;
        
        // 3. Create ACR relationships to maintain the relationship between the Household and the Contact post-conversion
        System.Debug('Step3');
        List<AccountContactRelation> memberships = new List<AccountContactRelation>();
        for (Contact current : theFamilyMembers) {
            memberships.add(new AccountContactRelation(AccountId=household.Id,ContactId=current.Id));
        }
        insert memberships;
        
        // 4. Create 1 Account per member that will become the PersonAccount
        System.Debug('Step4');
        List<Account> futurePA = new List<Account>();
        for (Contact current : theFamilyMembers) {
            futurePA.add(new Account(name=current.Name+' PA',RecordTypeId=RTBUSINESS.Id));
        }
        insert futurePA;        
        // 5. Reparent the Contact in the new Account
        System.Debug('Step5');
        for (integer i=0; i< theFamilyMembers.size(); i++) {
            theFamilyMembers[i].AccountId=futurePA[i].Id;
        }
        update theFamilyMembers; 
        
        Test.StartTest();
        
        // 6. Convert the members into PersonAccounts 
        // -- In this Step the ONLY field you may update is the RecordTypeId
        // -- we now have 1 Account : 1 Contact
        System.Debug('Step6');
        List <Account> convertThese = new List<Account>();
        Set<Id> futurePAIds = new Map<Id,Account>(futurePA).keyset();

        // Must requery the Account records selecting ONLY the Id and RecordTypeId fields
        for (Account current : [Select Id, RecordTypeId From Account Where Id IN :futurePAIds]) {
            current.RecordTypeId=RTCLIENT.Id;
            convertThese.add(current);
        }
        update convertThese;
        
        Test.StopTest();
        
        // 3 Bears should be members of the new household
        System.AssertEquals([Select Id 
                             From AccountContactRelation 
                             Where AccountId=:household.Id].size(),3,'Members not correct');
        
        for(Account current : [Select Id, Name, IsPersonAccount From Account Where Id IN :futurePAIds]) {
            System.Assert(current.IsPersonAccount,'Experted this to be a personaccount recordtype');
        }
               
    }
    
    // Helper method
    private static RecordType getRT(String name,boolean isPA) {
        return [select id,name,isPersonType 
                from RecordType 
                where SObjectType='Account'
                and isPersonType=:isPA 
                and name=:name];
    }
}