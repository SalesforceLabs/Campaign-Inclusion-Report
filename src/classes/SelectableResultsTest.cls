/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
@isTest
private class SelectableResultsTest {

    static testMethod void selectableResultTest() {
        // set up header, results, campaign, contacts
        Campaign_Report_Header__c crh  = new Campaign_Report_Header__c();
        crh.Name = 'Test Header';
        insert crh;
        
        Campaign cam1 = new Campaign();
        cam1.Name = 'Test Cam 1';
        insert cam1;
        
        Campaign cam2 = new Campaign();
        cam2.Name = 'Test Cam 2';
        insert cam2;
                
        
       Lead lead1 = new Lead();
        lead1.LastName = 'TestJones';
        lead1.Company = 'Acme';
        lead1.Status = 'Open - Non Contacted';
        insert lead1;
        
        Lead lead2 = new Lead();
        lead2.LastName = 'TestDavis';
        lead2.Company = 'Acme';
        lead2.Status = 'Open - Non Contacted';
        insert lead2;
 
        Lead lead3 = new Lead();
        lead3.LastName = 'TestDavisson';
        lead3.Company = 'Acme';
        lead3.Status = 'Open - Non Contacted';
        insert lead3;
        
        Campaign_Report_Result__c crr1 = new Campaign_Report_Result__c();
        crr1.Lead__c = lead1.Id;
        crr1.Campaign_Report_Header__c = crh.Id;
        insert crr1;
        
        Campaign_Report_Result__c crr2 = new Campaign_Report_Result__c();
        crr2.Lead__c = lead2.Id;
        crr2.Campaign_Report_Header__c = crh.Id;
        insert crr2;
   
        
        CampaignMember cm = new CampaignMember();
        cm.LeadId = lead3.Id;
        cm.CampaignId = cam2.Id;
        cm.Status = 'Sent';
        insert cm;  
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(crh);
        SelectableResults srCon = new SelectableResults(con);
        System.assertEquals(2,srCon.results.size());
        srCon.camMember.CampaignId = cam2.Id;
        srCon.camMember.Status = 'Sent';
        srCon.save();
        
        List<CampaignMember> camMembers = [Select Id From CampaignMember where CampaignId=:cam2.Id];
        System.assertEquals(1, camMembers.size());
        
        con = new ApexPages.Standardcontroller(crh);
        srCon = new SelectableResults(con);
        System.assertEquals(2,srCon.results.size());
        srCon.results[0].checked = true;
        srCon.camMember.CampaignId = cam2.Id;
        srCon.camMember.Status = 'Sent';
        srCon.save();
        
        camMembers = [Select Id From CampaignMember where CampaignId=:cam2.Id];
        System.assertEquals(2, camMembers.size());
        
    }
    
    static testmethod void campaignWrapperTest()
    {
    	CampaignResultWrapper crw = new CampaignResultWrapper();
    	System.assertEquals(false, crw.checked);
    }
}