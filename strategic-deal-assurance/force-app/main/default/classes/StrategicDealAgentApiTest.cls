@IsTest
private class StrategicDealAgentApiTest {
    @TestSetup static void setup() {
        Id profileId=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1].Id;
        List<User> users=new List<User>();
        for(String alias:new List<String>{'sdaapi','sdanoapi'}) users.add(new User(Alias=alias,LastName='Synthetic '+alias,
            Email=alias+'@example.invalid',Username=alias+'.'+UserInfo.getOrganizationId()+'.'+System.now().getTime()+'@example.invalid',
            ProfileId=profileId,TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US'));
        insert as system users;
        Id permissionId=[SELECT Id FROM PermissionSet WHERE Name='Strategic_Deal_User' WITH SYSTEM_MODE LIMIT 1].Id;
        insert as system new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=permissionId);
    }
    private static User allowed(){return [SELECT Id FROM User WHERE Alias='sdaapi' WITH SYSTEM_MODE LIMIT 1];}
    private static User denied(){return [SELECT Id FROM User WHERE Alias='sdanoapi' WITH SYSTEM_MODE LIMIT 1];}
    private static Opportunity deal(){
        String stage=[SELECT MasterLabel FROM OpportunityStage WHERE IsActive=true AND IsClosed=false WITH SYSTEM_MODE ORDER BY SortOrder LIMIT 1].MasterLabel;
        Opportunity row=new Opportunity(Name='SYN-API-Policy',StageName=stage,CloseDate=Date.today().addDays(30),
            Amount=60000000,Discount__c=20,Strategic_Deal__c=true,Regional_VP_Approver__c=UserInfo.getUserId());
        insert as user row; return row;
    }
    private static Map<String,Object> invoke(Id id,String limitValue){
        RestRequest request=new RestRequest();request.httpMethod='GET';
        request.requestURI='/services/apexrest/sda/v1/policy/'+String.valueOf(id);
        if(limitValue!=null)request.params.put('limit',limitValue);
        RestContext.request=request;RestContext.response=new RestResponse();
        StrategicDealAgentApi.getPolicy();
        return (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
    }
    @IsTest static void authorizedParentReturnsBoundedPrivateHistory(){
        System.runAs(allowed()){
            Opportunity row=deal();update as user new Opportunity(Id=row.Id,Discount__c=21);
            Map<String,Object> body=invoke(row.Id,'1');
            System.assertEquals(200,RestContext.response.statusCode);
            System.assertEquals('no-store',RestContext.response.headers.get('Cache-Control'));
            System.assertEquals(1,((List<Object>)body.get('history')).size());
            System.assertEquals(1,body.get('historyLimit'));
            System.assertEquals('USD',((Map<String,Object>)body.get('opportunity')).get('currencyCode'));
            System.assertEquals(21,((Map<String,Object>)((List<Object>)body.get('history'))[0]).get('discountPercent'));
            System.assertEquals(false,Strategic_Deal_Evaluation__c.SObjectType.getDescribe().isAccessible());
            System.assert(!RestContext.response.responseBody.toString().contains(String.valueOf(UserInfo.getUserId())));
        }
    }
    @IsTest static void inaccessibleParentIsUniformNotFound(){
        Id rowId;System.runAs(allowed()){rowId=deal().Id;}
        System.runAs(denied()){
            Map<String,Object> body=invoke(rowId,null);
            System.assertEquals(404,RestContext.response.statusCode);System.assertEquals('NOT_FOUND',body.get('code'));
            System.assert(!RestContext.response.responseBody.toString().contains(String.valueOf(rowId)));
        }
    }
    @IsTest static void malformedIdsAndLimitsAreBadRequests(){
        RestRequest request=new RestRequest();request.httpMethod='GET';request.requestURI='/services/apexrest/sda/v1/policy/not-an-id';
        RestContext.request=request;RestContext.response=new RestResponse();StrategicDealAgentApi.getPolicy();
        System.assertEquals(400,RestContext.response.statusCode);
        System.runAs(allowed()){
            Opportunity row=deal();Map<String,Object> body=invoke(row.Id,'51');
            System.assertEquals(400,RestContext.response.statusCode);System.assertEquals('INVALID_REQUEST',body.get('code'));
        }
    }
}
