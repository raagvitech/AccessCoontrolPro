/*
 Name: AccessSchedularClass
 Description: Schedule apex for revoke the access
 Created By : Cloud Avengers
 Date       : 9-Dec-2023
*/

@SuppressWarnings('PMD.AvoidGlobalModifier')
 
global class AccessSchedularClass implements Schedulable
{
    global String requesterId;
    global String requesterprofileId;
    global String requesterPermissionSetId;
    
    public AccessSchedularClass(String requesterId, String requesterprofileId, String requesterPermissionSetId)
    {
         this.requesterId = requesterId;
         this.requesterprofileId = requesterprofileId;
         this.requesterPermissionSetId = requesterPermissionSetId;
    }
    
    public void execute(SchedulableContext sc) 
    {
        if(requesterprofileId != null)
        {
            RequestForAccess.revoketheProfileAccess(requesterId, requesterprofileId);
        }
        if(requesterPermissionSetId != null)
        {
           RequestForAccess.revokethePermissionsetAccess(requesterId, requesterPermissionSetId);
        }
        else 
        {
            System.debug('Values are Not Selected');
        } 

    } 
    
}