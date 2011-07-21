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
private class CampaignReportTest {

    static testMethod void reportTest() {
        // set up account
        Account acc = new Account();
        acc.BillingCountry = 'US';
        acc.ShippingCountry = 'US';
        acc.BillingState = 'IL';        
        acc.Name = 'Test Acc';
        insert acc;
        // set up campaigns (3)
        Campaign cam1 = new Campaign();
        cam1.Name = 'Test Cam 1';
        insert cam1;
        Campaign cam2 = new Campaign();
        cam2.Name = 'Test Cam 2';
        insert cam2;
        Campaign cam3 = new Campaign();
        cam3.Name = 'Test Cam 3';
        insert cam3;
        Campaign cam4 = new Campaign();
        cam4.Name = 'Test Cam 4';
        insert cam4;
        // set up contact
        Contact con1 = new Contact();
        con1.AccountId = acc.Id;
        con1.LastName = 'Davis';
        insert con1;
        // set up lead
        Lead lead1 = new Lead();
        lead1.LastName = 'TestJones';
        lead1.Company = 'Acme';
        lead1.Status = 'Open - Non Contacted';
        insert lead1;        
        // set up campaign members
        CampaignMember camMem1 = new CampaignMember();
        camMem1.ContactId = con1.Id;
        camMem1.CampaignId = cam1.Id;
        camMem1.Status = 'Sent';
        insert camMem1;
        CampaignMember camMem2 = new CampaignMember();
        camMem2.LeadId = lead1.Id;
        camMem2.CampaignId = cam1.Id;
        camMem2.Status = 'Sent';
        insert camMem2;
        CampaignMember camMem3 = new CampaignMember();
        camMem3.LeadId = lead1.Id;
        camMem3.CampaignId = cam2.Id;
        camMem2.Status = 'Sent';
        insert camMem3;
        
        // test searching
        Campaign_Report_Header__c crh = new Campaign_Report_Header__c();
        crh.Name = 'Test';
        insert crh;
        
       //first, check contacts 
       ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(crh);
       CampaignInclusionReportController circ = new CampaignInclusionReportController(con);
       circ.searchCampaigns();
       
       circ.campaignLines[0].includedExcluded = 'Included';
       circ.campaignLines[0].camMember.CampaignId = cam1.Id;
       circ.campaignLines[0].camMember.Status = 'Sent';
       circ.searchCampaigns();
       System.assertEquals(1, circ.crResults.size());
       
       //then just leads
       circ.leadOrContact = 'Leads';
       circ.searchCampaigns();
       System.assertEquals(1, circ.crResults.size());
       
       //then both
       circ.leadOrContact = 'Both';
       circ.searchCampaigns();
       System.assertEquals(2, circ.crResults.size());
       
       // test exclusion
       circ.addLine();
       circ.campaignLines[1].includedExcluded = 'Excluded';
       circ.campaignLines[1].camMember.CampaignId = cam2.Id;
       circ.searchCampaigns();
       System.assertEquals(1, circ.crResults.size());
        
       // test save options
       circ.removeLine();
       circ.searchCampaigns();
       circ.saveOption = 'Save search terms and results';
       circ.saveReport();
       List<Campaign_Report_Filter__c> filters = [select Id From Campaign_Report_Filter__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(1, filters.size());
       List<Campaign_Report_Result__c> results = [select Id From Campaign_Report_Result__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(2, results.size());
       
       //check to see that it reloaded the search terms properly
	   con = new ApexPages.Standardcontroller(crh);
       circ = new CampaignInclusionReportController(con);       
       circ.searchCampaigns();
       System.assertEquals(2, circ.crResults.size());
       
       circ.saveOption = 'Save search terms only';
       circ.saveReport();
       filters = [select Id From Campaign_Report_Filter__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(1, filters.size());
       results = [select Id From Campaign_Report_Result__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(0, results.size());       

	   con = new ApexPages.Standardcontroller(crh);
       circ = new CampaignInclusionReportController(con);
       System.assertEquals(1, circ.campaignLines.size());       
       circ.searchCampaigns();
       System.assertEquals(2, circ.crResults.size());
       
       circ.saveOption = 'Save search terms and add results to Campaign';
       circ.camMember.Status = 'Sent';
       circ.saveReport();
      
       circ.camMember.CampaignId = cam3.Id;
       circ.saveReport();
       
       filters = [select Id From Campaign_Report_Filter__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(1, filters.size());
       results = [select Id From Campaign_Report_Result__c Where Campaign_Report_Header__c=:crh.Id];
       System.assertEquals(0, results.size());          
       
       List<CampaignMember> camMembers = [select Id From CampaignMember where CampaignId=:cam3.Id];
       System.assertEquals(2, camMembers.size());
       
       //now test after leads are converted
		Database.LeadConvert ltc = new database.LeadConvert();
		LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		ltc.setLeadId(lead1.Id);
		ltc.setConvertedStatus(convertStatus.MasterLabel);
		leadsToConvert.add(ltc);
		List<Database.LeadConvertResult> lcr = Database.convertLead(leadsToConvert);
       
	   con = new ApexPages.Standardcontroller(crh);
       circ = new CampaignInclusionReportController(con);
       circ.searchCampaigns();
       
       circ.saveOption = 'Save search terms and add results to Campaign';
       circ.camMember.Status = 'Sent';
       circ.saveReport();
      
       circ.camMember.CampaignId = cam4.Id;
       circ.saveReport();       
       
		       
    }
}