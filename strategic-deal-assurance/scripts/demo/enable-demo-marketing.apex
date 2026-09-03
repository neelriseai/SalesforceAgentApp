// User-approved prerequisite: only the current authorized administrative operator.
System.assertEquals('Developer Edition',[SELECT OrganizationType FROM Organization WITH USER_MODE LIMIT 1].OrganizationType,'Dedicated demo org only');
Id profileId=UserInfo.getProfileId();
System.assert([SELECT PermissionsModifyAllData FROM Profile WHERE Id=:profileId WITH USER_MODE].PermissionsModifyAllData,'Administrative operator only');
Id operatorId=UserInfo.getUserId();
User operator=[SELECT Id,UserPermissionsMarketingUser FROM User WHERE Id=:operatorId WITH USER_MODE];
if(!operator.UserPermissionsMarketingUser) update as user new User(Id=operatorId,UserPermissionsMarketingUser=true);
System.assert([SELECT UserPermissionsMarketingUser FROM User WHERE Id=:operatorId WITH USER_MODE].UserPermissionsMarketingUser,'Marketing setting not enabled');
System.debug('DEMO_MARKETING_ENABLED|currentOperatorOnly=true');
