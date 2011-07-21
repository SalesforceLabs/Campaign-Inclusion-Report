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
public with sharing class SelectableResults {

public List<CampaignResultWrapper> results {get;set;}
public ApexPages.Standardsetcontroller con {get;set;}
public Campaign_Report_Header__c crh {get;set;}
public CampaignMember camMember {get;set;}
public List<Campaign_Report_Result__c> crResults;

public SelectableResults()
{
	results = new List<CampaignResultWrapper>();
}

public SelectableResults(ApexPages.StandardController controller)
{
	crh = (Campaign_Report_Header__c)controller.getRecord();
	camMember = new CampaignMember();
	results = new List<CampaignResultWrapper>();
	
	crResults = [Select Id, First_Name__c,Last_Name__c, Lead__c, Contact__c,Email__c,Company__c FROM Campaign_Report_Result__c Order Where Campaign_Report_Header__c=:crh.Id Limit 1000];

	for (Campaign_Report_Result__c result  : crResults)
			results.add(new CampaignResultWrapper(result));

}



public PageReference save()
{
	List<CampaignMember> cmsToInsert = new List<CampaignMember>();
	CampaignMember cm = new CampaignMember();
			List<CampaignMember> currentCms = new List<CampaignMember>();
		
		currentCms = [Select Id, LeadId, ContactId From CampaignMember Where CampaignId=:camMember.CampaignId];

		Set<Id> existingContactsLeads = new Set<Id>();
		for (CampaignMember cam : currentCms)
		{
			if (cam.LeadId != null)
			{
				existingContactsLeads.add(cam.LeadId);
			}
			if (cam.ContactId != null)
			{
				existingContactsLeads.add(cam.ContactId);
			}
		}
	
	
	for (CampaignResultWrapper crw : results)
	{
		if (crw.checked == true)
		{
			if ((crw.cr.Lead__c != null && existingContactsLeads.contains(crw.cr.Lead__c) == false)
			    || (crw.cr.Contact__c != null && existingContactsLeads.contains(crw.cr.Contact__c) == false))
			{			
				cm = new CampaignMember();
				cm.CampaignId = camMember.CampaignId;
				cm.Status = camMember.Status;
				cm.ContactId = crw.cr.Contact__c;
				cm.LeadId = crw.cr.Lead__c;
				cmsToInsert.add(cm);
			}
		}
	}
	
	if (cmsToInsert.size() < 1 )
	{
		return cancel();
	}
	else
	{
		insert cmsToInsert;
		return new PageReference('/' + camMember.CampaignId);
	}
}

public PageReference cancel()
{
	return new PageReference('/' + crh.Id);
}

}