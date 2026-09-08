/** Narrow, read-only external API for parent-authorized strategic-deal policy evidence. */
@RestResource(urlMapping='/sda/v1/policy/*')
global with sharing class StrategicDealAgentApi {
    private static final Integer DEFAULT_LIMIT=20;
    private static final Integer MAX_LIMIT=50;
    private static final String ROUTE='/sda/v1/policy/';

    @HttpGet
    global static void getPolicy() {
        RestResponse response=RestContext.response;
        response.addHeader('Content-Type','application/json');
        response.addHeader('Cache-Control','no-store');
        try {
            Id opportunityId=parseOpportunityId(RestContext.request.requestURI);
            Integer rowLimit=parseLimit(RestContext.request.params.get('limit'));
            List<Opportunity> parents=[SELECT Approval_Status__c,Approval_Reason__c,
                Policy_Rule_Version__c,Policy_Evaluated_At__c,Amount,Discount__c
                FROM Opportunity WHERE Id=:opportunityId WITH USER_MODE LIMIT 1];
            if(parents.isEmpty()) { notFound(); return; }
            Opportunity parent=parents[0];
            Map<String,Object> result=new Map<String,Object>{
                'schemaVersion'=>'1.0.0',
                'objectApiName'=>'Opportunity',
                'opportunity'=>new Map<String,Object>{
                    'approvalStatus'=>parent.Approval_Status__c,
                    'approvalReason'=>parent.Approval_Reason__c,
                    'appliedRuleVersion'=>parent.Policy_Rule_Version__c,
                    'evaluatedAt'=>parent.Policy_Evaluated_At__c,
                    'amount'=>parent.Amount,
                    'discountPercent'=>parent.Discount__c,
                    'currencyCode'=>'USD'
                },
                'activePolicy'=>activePolicy(),
                'history'=>new AuthorizedHistoryReader().read(opportunityId,rowLimit),
                'historyLimit'=>rowLimit
            };
            response.statusCode=200;
            response.responseBody=Blob.valueOf(JSON.serialize(result));
        } catch(InvalidRequestException ignored) {
            error(400,'INVALID_REQUEST','Use GET /services/apexrest/sda/v1/policy/{OpportunityId}?limit=1..50.');
        } catch(Exception ignored) {
            notFound();
        }
    }

    private static Id parseOpportunityId(String uri) {
        Integer marker=uri==null?-1:uri.indexOf(ROUTE);
        if(marker<0) throw new InvalidRequestException();
        String raw=uri.substring(marker+ROUTE.length());
        Integer queryAt=raw.indexOf('?'); if(queryAt>=0) raw=raw.substring(0,queryAt);
        if(String.isBlank(raw)||raw.contains('/')) throw new InvalidRequestException();
        Id value;
        try { value=Id.valueOf(raw); } catch(Exception ignored) { throw new InvalidRequestException(); }
        if(value.getSObjectType()!=Opportunity.SObjectType) throw new InvalidRequestException();
        return value;
    }
    private static Integer parseLimit(String raw) {
        if(String.isBlank(raw)) return DEFAULT_LIMIT;
        Integer value;
        try { value=Integer.valueOf(raw); } catch(Exception ignored) { throw new InvalidRequestException(); }
        if(value<1||value>MAX_LIMIT) throw new InvalidRequestException();
        return value;
    }
    private static Map<String,Object> activePolicy() {
        Strategic_Discount_Rule__mdt rule=Strategic_Discount_Rule__mdt.getInstance('Default');
        return new Map<String,Object>{
            'active'=>rule!=null&&rule.Active__c==true,
            'ruleVersion'=>rule==null?null:rule.Rule_Version__c,
            'minimumAmount'=>rule==null?null:rule.Minimum_Amount_INR__c,
            'discountThresholdPercent'=>rule==null?null:rule.Discount_Threshold_Percent__c,
            'currencyCode'=>'USD'
        };
    }
    private static void notFound() { error(404,'NOT_FOUND','Policy information is unavailable or you do not have access.'); }
    private static void error(Integer status,String code,String message) {
        RestContext.response.statusCode=status;
        RestContext.response.responseBody=Blob.valueOf(JSON.serialize(new Map<String,Object>{'code'=>code,'message'=>message}));
    }
    private class InvalidRequestException extends Exception {}

    // Deliberate narrow elevation, reachable only after the parent USER_MODE read succeeds.
    private without sharing class AuthorizedHistoryReader {
        public List<Map<String,Object>> read(Id opportunityId,Integer rowLimit) {
            List<Map<String,Object>> result=new List<Map<String,Object>>();
            for(Strategic_Deal_Evaluation__c row:[SELECT Name,Outcome__c,Reason__c,Rule_Version__c,
                Evaluated_At__c,Amount_INR__c,Discount_Percent__c,Strategic_Deal__c,
                Approval_Required__c,Approver_Present__c,Evaluation_Source__c,Input_Hash__c,Correlation_Id__c
                FROM Strategic_Deal_Evaluation__c WHERE Opportunity__c=:opportunityId
                WITH SYSTEM_MODE ORDER BY Evaluated_At__c DESC,CreatedDate DESC,Id DESC LIMIT :rowLimit]) {
                result.add(new Map<String,Object>{
                    'evaluationNumber'=>row.Name,'outcome'=>row.Outcome__c,'reason'=>row.Reason__c,
                    'ruleVersion'=>row.Rule_Version__c,'evaluatedAt'=>row.Evaluated_At__c,
                    'amount'=>row.Amount_INR__c,'discountPercent'=>row.Discount_Percent__c,
                    'strategicDeal'=>row.Strategic_Deal__c,'approvalRequired'=>row.Approval_Required__c,
                    'approverPresent'=>row.Approver_Present__c,'source'=>row.Evaluation_Source__c,
                    'inputHash'=>row.Input_Hash__c,'correlationId'=>row.Correlation_Id__c
                });
            }
            return result;
        }
    }
}
