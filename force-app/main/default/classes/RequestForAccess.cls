/*
 Name: RequestForAccess
 Description: Get the Request and upgrade the access and schedule apex for revoke the access
 Created By : Cloud Avengers
 Date       : 9-Dec-2023
*/

@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexCRUDViolation')

global with sharing class RequestForAccess{
    
    public static void accessTriggerController(List<Access__c> access)
    {
           for(Access__c obj : access)
           {
               if (Obj.Status__c == 'Approved') 
                {  
                    String recordId=obj.Id;
                    RequestForAccess.upgradeAccess(recordId);
                }
           }
    }
 
    public static Access__c getAccessDetails(String currentRecordId){
    Access__c access = [SELECT Id, Name, Profile_to_Update__c, Permission_to_Update__c, Request_For_Profile__c, Request_For_Permission_Set__c,
                        Access_Expire_Date__c,Access_Expire_Time__c,Email__c,Phone_Number__c
                        FROM Access__c
                        WHERE Id =: currentRecordId
                        WITH USER_MODE ];
    return access;
    }
    @future
    global static void upgradeAccess(String recordId){
        
        Access__c access = RequestForAccess.getAccessDetails(recordId);
        
        Profile profiles;
        String requesterOriginalProfileId;
        String permissionSetId;
        String currentRecordId = recordId;
        List<PermissionSet> permissionSets = new List<PermissionSet>{};
        
        String schedulejobName = access.Name; 
        String profileToBeUpdate = access.Profile_to_Update__c;
        String permissionSetToBeUpdate = access.Permission_to_Update__c;
        Boolean profileCheck = access.Request_For_Profile__c;
        Boolean permissionCheck = access.Request_For_Permission_Set__c;
        Date estimatedDate = access.Access_Expire_Date__c; 
        Time estimatedTime = access.Access_Expire_Time__c; 
      
        Integer hour = EstimatedTime.hour();
        Integer min = EstimatedTime.minute();
        Datetime scheduledTime = Datetime.newInstanceGmt(EstimatedDate.year(), EstimatedDate.month(), EstimatedDate.day(), 0, 0, 0);
        
        String cronExpression = 0 + ' ' + min + ' ' + hour + ' ' + ScheduledTime.day() + ' ' + ScheduledTime.month() + ' ? ' + ScheduledTime.year();
        String userId = UserInfo.getUserId();
        
        String requesterUserId = [SELECT Id, ProcessInstance.SubmittedBy.Id 
                                  FROM ProcessInstanceStep
                                  WHERE StepStatus = 'Approved' AND ActorId =:userId 
                                  ORDER BY CreatedDate DESC LIMIT 1].ProcessInstance.SubmittedBy.Id;
        User requestedUser = [SELECT Id, firstname, lastname, IsActive, ProfileId, UserType 
                              FROM User 
                              WHERE Id = :requesterUserId
                              WITH USER_MODE];
        
        if(permissionCheck){
           permissionSets = [SELECT Id 
                             FROM PermissionSet 
                             WHERE Label = :  permissionSetToBeUpdate 
                             WITH USER_MODE LIMIT 1];
           if (!permissionSets.isEmpty()) {
                permissionSetId = permissionSets[0].Id;
                try {
                    PermissionSetAssignment newAssignment = new PermissionSetAssignment( 
                                            AssigneeId = RequesterUserId,
                                            PermissionSetId = permissionSetId
                    );
                    INSERT newAssignment;
                }catch (Exception e) {
                    System.debug('Error Message: ' + e.getMessage());
                    throw e;
                }
            } 
        }
        if(ProfileCheck){
            RequesterOriginalProfileId = requestedUser.ProfileId;
            profiles = [SELECT Id, Name FROM profile WHERE Name =: ProfileToBeUpdate WITH USER_MODE];
            requestedUser.ProfileId = profiles.Id;
            try{
                UPDATE requestedUser; 
            } catch(Exception e){
              System.debug('Error Message: '+ e.getMessage());
            }
        }

        AccessSchedularClass scheduledJob = new AccessSchedularClass(RequesterUserId, RequesterOriginalProfileId, permissionSetId);
        System.schedule( SchedulejobName, cronExpression , scheduledJob);
    }
    
     global static void revoketheProfileAccess(String requesterUserId, String requesterOriginalProfileId){
         
         User requestedUser = [SELECT Id, firstname, lastname, email,  IsActive, ProfileId, UserType 
                               FROM User  
                               WHERE Id = :RequesterUserId
                               WITH USER_MODE];
         
         Profile oldProfile = [SELECT Id, Name 
                               FROM profile 
                               WHERE id=: RequesterOriginalProfileId
                               WITH USER_MODE];

         requestedUser.ProfileId = OldProfile.Id;
         
         UPDATE requestedUser;
     } 
    
    global static void revokethePermissionsetAccess(String requesterId, String requesterPermissionSetId){ 

        PermissionSetAssignment existingAssignment = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = : RequesterId
            AND PermissionSetId = : RequesterPermissionSetId
            WITH USER_MODE
            LIMIT 1
        ];
        
        if (existingAssignment != null) 
        {
            DELETE existingAssignment;
        }else{
            System.debug('Permission Set is not Assigned to the User');
        }
    } 
}