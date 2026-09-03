// Explicitly authorized one-time demo user provisioning; run only as the caip-dev administrator.
// No password is set or read. Salesforce sends setup instructions to the current user's inbox.
System.assertEquals('Developer Edition',[SELECT OrganizationType FROM Organization WITH USER_MODE LIMIT 1].OrganizationType);
Id operatorId=UserInfo.getUserId();
User operatorUser=[SELECT Email,Profile.PermissionsModifyAllData FROM User WHERE Id=:operatorId WITH USER_MODE];
System.assert(operatorUser.Profile.PermissionsModifyAllData,'Administrator required');
String alias='sdademvp';
System.assertEquals(0,[SELECT COUNT() FROM User WHERE Alias=:alias WITH USER_MODE],'Demo VP already exists; inspect instead of creating a duplicate');
Id minimumProfile=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' WITH USER_MODE LIMIT 1].Id;
String suffix=EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0,12);
User vp=new User(FirstName='Synthetic',LastName='Regional VP',Alias=alias,Email=operatorUser.Email,
    Username='sda.regionalvp.'+suffix+'@example.invalid',CommunityNickname='sda_vp_'+suffix,
    ProfileId=minimumProfile,TimeZoneSidKey='Asia/Kolkata',LocaleSidKey='en_US',LanguageLocaleKey='en_US',EmailEncodingKey='UTF-8',IsActive=true);
Database.DMLOptions options=new Database.DMLOptions(); options.EmailHeader.triggerUserEmail=true;
Database.SaveResult result=Database.insert(vp,options);
System.assert(result.isSuccess(),'User creation failed');
Id permissionId=[SELECT Id FROM PermissionSet WHERE Name='Regional_VP_Approver' WITH USER_MODE LIMIT 1].Id;
insert as user new PermissionSetAssignment(AssigneeId=vp.Id,PermissionSetId=permissionId);
System.debug(LoggingLevel.ERROR,'DEMO_VP_CREATED|'+JSON.serialize(new Map<String,Object>{'username'=>vp.Username,'profile'=>'Minimum Access - Salesforce','permissionSet'=>'Regional_VP_Approver','activationEmailRequested'=>true}));
