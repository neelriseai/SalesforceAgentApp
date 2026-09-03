/** BR-STRATEGIC-DISCOUNT; Apex integration substitute for native Flow tests. */
@IsTest
private class StrategicDiscountFlowTest {
    @TestSetup
    static void setupLimitedIdentity() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1];
        User sales = new User(Alias='sdfsales', LastName='Synthetic Flow Sales',
            Email='sales@example.invalid', Username='sdf.' + UserInfo.getOrganizationId() + '.' + System.now().getTime() + '@example.invalid',
            ProfileId=profile.Id, TimeZoneSidKey='Asia/Kolkata', LocaleSidKey='en_IN',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        // Setup-only test fixtures deliberately use system mode. No persistent user is created.
        insert as system sales;
        PermissionSet access = [SELECT Id FROM PermissionSet WHERE Name='Strategic_Deal_User' WITH SYSTEM_MODE LIMIT 1];
        insert as system new PermissionSetAssignment(AssigneeId=sales.Id, PermissionSetId=access.Id);
    }

    private static Opportunity deal(String suffix, Decimal amount, Decimal discount, Boolean strategic, Id approver) {
        OpportunityStage stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false WITH SYSTEM_MODE ORDER BY SortOrder LIMIT 1];
        return new Opportunity(Name='SYN-FLOW-' + suffix, StageName=stage.MasterLabel,
            CloseDate=Date.today().addDays(30), Amount=amount, Discount__c=discount,
            Strategic_Deal__c=strategic, Regional_VP_Approver__c=approver);
    }

    private static Opportunity outcome(Id recordId) {
        return [SELECT Approval_Status__c, Approval_Reason__c, Policy_Rule_Version__c,
            Policy_Evaluated_At__c FROM Opportunity WHERE Id=:recordId WITH SYSTEM_MODE];
    }

    private static List<Strategic_Deal_Evaluation__c> evaluations(Id recordId) {
        return [SELECT Opportunity__c, Amount_INR__c, Discount_Percent__c, Strategic_Deal__c,
            Approver_Present__c, Approval_Required__c, Outcome__c, Reason__c, Rule_Version__c,
            Correlation_Id__c, Evaluation_Source__c, Evaluated_At__c, Input_Hash__c
            FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:recordId WITH SYSTEM_MODE
            ORDER BY CreatedDate, Id];
    }

    private static void assertSingle(Id recordId, String expected, Boolean required) {
        Opportunity current = outcome(recordId);
        List<Strategic_Deal_Evaluation__c> rows = evaluations(recordId);
        System.assertEquals(1, rows.size(), 'OBL-FLOW-IDEMPOTENT: one evaluation, no recursion duplicate');
        System.assertEquals(expected, current.Approval_Status__c, 'Opportunity status');
        System.assertEquals('baseline-15', current.Policy_Rule_Version__c, 'Applied rule');
        System.assertEquals(expected, rows[0].Outcome__c, 'Evidence matches outcome');
        System.assertEquals(required, rows[0].Approval_Required__c, 'Approval obligation');
        System.assertEquals(current.Approval_Reason__c, rows[0].Reason__c, 'Reason correlation');
        System.assertEquals(current.Policy_Evaluated_At__c, rows[0].Evaluated_At__c, 'Timestamp correlation');
        System.assertEquals('baseline-15', rows[0].Rule_Version__c, 'Evidence version');
        System.assertEquals('Flow', rows[0].Evaluation_Source__c, 'Real Flow path');
        System.assert(!String.isBlank(rows[0].Correlation_Id__c), 'Interview correlation');
        System.assertEquals(64, rows[0].Input_Hash__c.length(), 'Input hash');
    }

    @IsTest static void exactAmountBoundary() {
        Opportunity value=deal('amount', 50000000, 20, true, UserInfo.getUserId());
        insert as system value;
        assertSingle(value.Id, 'Not Required', false);
    }

    @IsTest static void exactDiscountBoundary() {
        Opportunity value=deal('discount', 50000000.01, 15, true, UserInfo.getUserId());
        insert as system value;
        assertSingle(value.Id, 'Not Required', false);
    }

    @IsTest static void aboveBoundaryAndSnapshot() {
        Opportunity value=deal('above', 50000000.01, 15.01, true, UserInfo.getUserId());
        insert as system value;
        assertSingle(value.Id, 'Pending Regional VP', true);
        Strategic_Deal_Evaluation__c row=evaluations(value.Id)[0];
        System.assertEquals(50000000.01, row.Amount_INR__c, 'Amount snapshot');
        System.assertEquals(15.01, row.Discount_Percent__c, 'Percent snapshot');
        System.assertEquals(true, row.Approver_Present__c, 'Only approver presence');
        System.assertEquals(true, row.Strategic_Deal__c, 'Strategic snapshot');
    }

    @IsTest static void missingApproverFailsClosed() {
        Opportunity value=deal('missing', 60000000, 20, true, null);
        insert as system value;
        assertSingle(value.Id, 'Configuration Error', true);
        System.assertEquals(false, evaluations(value.Id)[0].Approver_Present__c, 'Missing approver snapshot');
    }

    @IsTest static void nullDiscountDoesNotRequireApproval() {
        Opportunity value=deal('null', 60000000, null, true, null);
        insert as system value;
        assertSingle(value.Id, 'Not Required', false);
    }

    @IsTest static void unrelatedAndOutputOnlyChangesDoNotEvaluate() {
        Opportunity value=deal('irrelevant', 60000000, 20, true, UserInfo.getUserId());
        insert as system value;
        Datetime evaluatedAt=outcome(value.Id).Policy_Evaluated_At__c;
        update as system new Opportunity(Id=value.Id, Description='Synthetic unrelated change');
        System.assertEquals(1, evaluations(value.Id).size(), 'No evidence for unrelated edit');
        // Mimics future native approval's system-owned status transition, not a sales-user edit.
        update as system new Opportunity(Id=value.Id, Approval_Status__c='Approved');
        System.assertEquals(1, evaluations(value.Id).size(), 'No evidence for output-only re-entry');
        System.assertEquals('Approved', outcome(value.Id).Approval_Status__c, 'Do not reset a completed approval on unrelated edits');
        System.assertEquals(evaluatedAt, outcome(value.Id).Policy_Evaluated_At__c, 'No false latest evaluation');
    }

    @IsTest static void changedInputSameOutcomeStillCreatesEvidence() {
        Opportunity value=deal('same-outcome', 60000000, 20, true, UserInfo.getUserId());
        insert as system value;
        String firstHash=evaluations(value.Id)[0].Input_Hash__c;
        update as system new Opportunity(Id=value.Id, Discount__c=21);
        List<Strategic_Deal_Evaluation__c> rows=evaluations(value.Id);
        System.assertEquals(2, rows.size(), 'Same status still requires new input evidence');
        Set<String> hashes=new Set<String>(); Set<String> correlations=new Set<String>();
        for (Strategic_Deal_Evaluation__c row: rows) { hashes.add(row.Input_Hash__c); correlations.add(row.Correlation_Id__c); }
        System.assertEquals(2, hashes.size(), 'Two distinct snapshots');
        System.assertEquals(2, correlations.size(), 'Two distinct Flow interviews');
        System.assert(hashes.contains(firstHash), 'Original evidence preserved');
        System.assertEquals('Pending Regional VP', outcome(value.Id).Approval_Status__c, 'Same decision');
    }

    @IsTest static void everyRelevantInputTriggersReevaluation() {
        Opportunity value=deal('changes', 60000000, 20, true, UserInfo.getUserId());
        insert as system value;
        update as system new Opportunity(Id=value.Id, Amount=50000000);
        System.assertEquals('Not Required', outcome(value.Id).Approval_Status__c, 'Amount changed');
        update as system new Opportunity(Id=value.Id, Amount=60000000, Strategic_Deal__c=false);
        System.assertEquals('Not Required', outcome(value.Id).Approval_Status__c, 'Strategic changed');
        update as system new Opportunity(Id=value.Id, Strategic_Deal__c=true, Regional_VP_Approver__c=null);
        System.assertEquals('Configuration Error', outcome(value.Id).Approval_Status__c, 'Approver removed');
        update as system new Opportunity(Id=value.Id, Regional_VP_Approver__c=UserInfo.getUserId());
        System.assertEquals('Pending Regional VP', outcome(value.Id).Approval_Status__c, 'Approver restored');
        System.assertEquals(5, evaluations(value.Id).size(), 'One row for each relevant DML action');
    }

    @IsTest static void bulkCreateHasNoDuplicateEvidence() {
        List<Opportunity> values=new List<Opportunity>();
        Opportunity template=deal('bulk', 60000000, 20, true, UserInfo.getUserId());
        for (Integer i=0; i<200; i++) {
            Opportunity value=template.clone(false, false, false, false);
            value.Name='SYN-FLOW-bulk-' + i;
            value.Strategic_Deal__c=Math.mod(i,2)==0;
            values.add(value);
        }
        Test.startTest(); insert as system values; Test.stopTest();
        Set<Id> ids=new Map<Id,Opportunity>(values).keySet();
        System.assertEquals(200, [SELECT COUNT() FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c IN :ids WITH SYSTEM_MODE], 'Exactly 200 rows');
        System.assertEquals(100, [SELECT COUNT() FROM Opportunity WHERE Id IN :ids AND Approval_Status__c='Pending Regional VP' WITH SYSTEM_MODE], 'Half require approval');
        System.assertEquals(100, [SELECT COUNT() FROM Opportunity WHERE Id IN :ids AND Approval_Status__c='Not Required' WITH SYSTEM_MODE], 'Half do not');
    }

    @IsTest static void salesUserCanEvaluateButCannotForgeEvidenceOrOutcome() {
        User sales=[SELECT Id FROM User WHERE Alias='sdfsales' WITH SYSTEM_MODE LIMIT 1];
        System.runAs(sales) {
            System.assertEquals(true, Opportunity.Discount__c.getDescribe().isUpdateable(), 'Sales can edit discount');
            for (Schema.SObjectField field : new List<Schema.SObjectField>{Opportunity.Approval_Status__c, Opportunity.Approval_Reason__c, Opportunity.Policy_Rule_Version__c, Opportunity.Policy_Evaluated_At__c}) {
                System.assertEquals(false, field.getDescribe().isUpdateable(), 'Outcomes are read only');
            }
            System.assertEquals(false, Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isCreateable(), 'No direct evidence creation');
            System.assertEquals(false, Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isAccessible(), 'No unsafe lookup-based evidence read');
            System.assertEquals(false, Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isUpdateable(), 'No evidence editing');
            System.assertEquals(false, Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isDeletable(), 'No evidence deletion');
            Opportunity value=deal('limited', 60000000, 20, true, sales.Id);
            insert as user value;
            Opportunity visible=[SELECT Approval_Status__c FROM Opportunity WHERE Id=:value.Id WITH USER_MODE];
            System.assertEquals('Pending Regional VP', visible.Approval_Status__c, 'System Flow updates derived output for limited user');
            Boolean rejected=false;
            try { update as user new Opportunity(Id=value.Id, Approval_Status__c='Approved'); }
            catch (DmlException expected) { rejected=true; }
            System.assertEquals(true, rejected, 'OBL-PERMISSION-BYPASS: forbidden outcome write rejected');
            assertSingle(value.Id, 'Pending Regional VP', true);
        }
    }

    @IsTest static void permissionSetDefinitionsMatchContract() {
        Set<String> names=new Set<String>{'Strategic_Deal_User','Regional_VP_Approver','Change_Assurance_Integration','Strategic_Deal_UI_Runner'};
        Map<Id,PermissionSet> access=new Map<Id,PermissionSet>([SELECT Id, Name, PermissionsApiEnabled,
            PermissionsModifyAllData, PermissionsViewAllData FROM PermissionSet WHERE Name IN :names WITH SYSTEM_MODE]);
        System.assertEquals(4, access.size(), 'All four personas deployed');
        for (PermissionSet permission : access.values()) {
            System.assertEquals(false, permission.PermissionsModifyAllData, 'No global write elevation');
            System.assertEquals(false, permission.PermissionsViewAllData, 'No global read elevation');
            System.assertEquals(permission.Name=='Change_Assurance_Integration', permission.PermissionsApiEnabled, 'Only API persona grants API');
        }
        List<ObjectPermissions> objects=[SELECT ParentId, SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
            PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions
            WHERE ParentId IN :access.keySet() WITH SYSTEM_MODE];
        System.assertEquals(8, objects.size(), 'Opportunity and read-only Account navigation grants');
        for (ObjectPermissions permission : objects) {
            Boolean writer=permission.SObjectType=='Opportunity' && access.get(permission.ParentId).Name!='Regional_VP_Approver';
            System.assert(new Set<String>{'Opportunity','Account'}.contains(permission.SObjectType), 'No direct evaluation-object permissions');
            System.assertEquals(true, permission.PermissionsRead, 'All personas read Opportunity');
            System.assertEquals(writer, permission.PermissionsCreate, 'Persona create rights');
            System.assertEquals(writer, permission.PermissionsEdit, 'Persona edit rights');
            System.assertEquals(false, permission.PermissionsDelete, 'No deletes');
            System.assertEquals(false, permission.PermissionsViewAllRecords, 'Respect record sharing');
            System.assertEquals(false, permission.PermissionsModifyAllRecords, 'No all-record writes');
        }
        for (FieldPermissions permission : [SELECT Field, PermissionsEdit FROM FieldPermissions WHERE ParentId IN :access.keySet()
            AND Field IN ('Opportunity.Approval_Status__c','Opportunity.Approval_Reason__c','Opportunity.Policy_Rule_Version__c','Opportunity.Policy_Evaluated_At__c') WITH SYSTEM_MODE]) {
            System.assertEquals(false, permission.PermissionsEdit, 'Nobody can forge an outcome via these grants');
        }
    }
}
