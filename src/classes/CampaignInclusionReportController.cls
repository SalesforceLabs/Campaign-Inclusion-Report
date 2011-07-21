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
public with sharing class CampaignInclusionReportController {
 
public List<CampaignInclusionLine> campaignLines {get;set;}
public List<Contact> results {get;set;}
public List<SelectOption> leadOrContactOptions {get;set;}
public String leadOrContact {get;set;}
public List<SelectOption> saveOptions{get;set;}
public String saveOption {get;set;}
public List<Campaign_Report_Result__c> crResults {get;set;}
public List<Campaign_Report_Result__c> displayResults{get;set;}
public Campaign_Report_Header__c crh {get;set;}
public Boolean hasResults {get;set;}
public CampaignMember camMember {get;set;}
public String errorMessages {get;set;}

public CampaignInclusionReportController(ApexPages.StandardController controller)
{
	crh = (Campaign_Report_Header__c)controller.getRecord();
	crh = [Select Id, Report_Options__c from Campaign_Report_Header__c where Id=:crh.Id];
	
	campaignLines = new List<CampaignInclusionLine>();
	camMember = new CampaignMember();

	leadOrContactOptions = new List<SelectOption>();
	leadOrContactOptions.add(new SelectOption('Leads', 'Leads'));
	leadOrContactOptions.add(new SelectOption('Contacts', 'Contacts'));
	leadOrContactOptions.add(new SelectOption('Both', 'Both'));
	if (crh.Report_Options__c == null)
	{
		leadOrContact = 'Leads';
	}
	else	
	{
		leadOrContact = crh.Report_Options__c;
	}
	preLoadFilters();
	
	saveOptions = new List<SelectOption>();
	saveOptions.add(new SelectOption('Save search terms only','Save search terms only'));
	saveOptions.add(new SelectOption('Save search terms and results','Save search terms and results'));	
	saveOptions.add(new SelectOption('Save search terms and add results to Campaign','Save search terms and add results to Campaign'));
	saveOption = 'Save search terms only';
	
	List<Campaign_Report_Result__c> crResults = new List<Campaign_Report_Result__c>();
	hasResults=false;
	errorMessages = '';
}

private void preLoadFilters()
{
	List<Campaign_Report_Filter__c> filters = [select Id, Included_Or_Excluded__c, Campaign__c, Status__c From Campaign_Report_Filter__c where Campaign_Report_Header__c = :crh.Id];
	CampaignInclusionLine cLine = new CampaignInclusionLine();
	for (Campaign_Report_Filter__c filter : filters)
	{
		cLine = new CampaignInclusionLine();
		cLine.camMember.CampaignId = filter.Campaign__c;
		cLine.includedExcluded = filter.Included_Or_Excluded__c;
		cLine.camMember.Status = filter.Status__c;
		campaignLines.add(cLine);
	}
	if (campaignLines.size() == 0)
	{
		campaignLines.add(cLine);
	}
}

public void searchCampaigns()
{
	String contactSoql = 'SELECT LastName,FirstName,Id,Account.Name,Email FROM Contact WHERE ';
	String leadSoql = 'SELECT LastName,FirstName,Id,Company,Email FROM Lead WHERE ';

	String campaignIds = '';
	String notCampaignIds = '';
	hasResults = false;
	errorMessages = '';
	
	for (CampaignInclusionLine cLine : campaignLines)
	{
		if (cLine.camMember.CampaignId != null)
		{
			if (cLine.includedExcluded == 'included')
			{
				if (campaignIds != '')
				{
					campaignIds += ' and ';
				}		
				campaignIds +=  '(CampaignId = \'' + cLine.camMember.CampaignId +'\' and Status=\'' + cLine.camMember.Status + '\')';
			}
			else
			{
				if (notCampaignIds != '')
				{
					notCampaignIds += ' or ';
				}
				notCampaignIds += 'CampaignId = \'' + cLine.camMember.CampaignId + '\'';
			}
		}
	}
	if (notCampaignIds == '' && campaignIds == '')
	{
		errorMessages = 'Your search returned no records.';	
		return;		
	}
	
 	crResults = new List<Campaign_Report_Result__c>();
 	Integer numContacts = 0;
 	Integer numLeads = 0;
 	try
 	{
 		numContacts = database.countquery(getContactSoql(campaignIds, notCampaignIds,true));
 	}
 	catch(System.LimitException e)
 	{
 		numContacts = 50001;
 		errorMessages = 'Your search returned over 50,000 records.  Please select more search terms to narrow your search.';
 		
 	}
 	finally
 	{
 		try
 		{
 			numLeads = database.countquery(getLeadSoql(campaignIds,notCampaignIds,true));
 		}
 		catch (System.LimitException e)
 		{
 			numLeads = 50001;
 			errorMessages = 'Your search returned over 50,000 records.  Please select more search terms to narrow your search.';
 		
 		}
 		finally
 		{
		 	if (leadOrContact == 'Both')
			{
				if (numContacts + numLeads >= 50000)
				{
					errorMessages = 'Your search returned over 50,000 records.  Please select more search terms to narrow your search.';
			
					return;
				}
				if (numContacts + numLeads > 0)
				{
					hasResults = true;
				}
			}
			else if (leadOrContact == 'Leads')
			{
				if (numLeads >= 50000)
				{
					errorMessages = 'Your search returned over 50,000 records.  Please select more search terms to narrow your search.';
					return;
				}
				if (numLeads > 0)
				{
					hasResults = true;
				}
			}
			else if (leadOrContact == 'Contacts')
			{
				if (numContacts >= 50000)
				{
					errorMessages = 'Your search returned over 50,000 records.  Please select more search terms to narrow your search.';
					return;
				}
				if (numContacts > 0)
				{
					hasResults = true;
				}
			}
	
			if (hasResults == false)
			{
				errorMessages = 'Your search returned no records.';
				return;
			}
	
 			if (leadOrContact != 'Leads')
 			{
 				addContactsToResults(Database.Query(getContactSoql(campaignIds, notCampaignIds,false)));
 			}
 			if (leadOrContact != 'Contacts')
 			{
 				addLeadsToResults(Database.Query(getLeadSoql(campaignIds, notCampaignIds,false)));
 			}
 			makeDisplayResults();
 		}		
 	}
}

public String getContactSoql(String campaignIds, String notCampaignIds, Boolean getCount)
{
	String baseContactSoql = 'SELECT Name,LastName,FirstName,Id,Account.Name,Email FROM Contact WHERE ';
	String baseCountSoql = 'SELECT COUNT() FROM Contact WHERE ';
	String contactSoql = '';
	
	if (campaignIds != '')
	{
		contactSoql += 'Id in (SELECT ContactId From CampaignMember WHERE ' + campaignIds + ')';
	}
	if (notCampaignIds != '')
	{
		if (campaignIds != '')
		{
			contactSoql += ' AND ';
		}
		contactSoql += 'Id not in (SELECT ContactId From CampaignMember WHERE ' + notCampaignIds + ')';
	}	
	
	if (contactSOQL == '')
	{
		return contactSOQL;
	}
	else if (getCount == false)
	{
		return baseContactSOQL + contactSOQL + 'LIMIT 50000';
	}
	else
	{
		return baseCountSOQL + contactSOQL + 'LIMIT 50000';
	}
}

public String getLeadSoql(String campaignIds, String notCampaignIds, Boolean getCount)
{
	String baseLeadSoql = 'SELECT Name,LastName,FirstName,Id,Company,Email FROM Lead WHERE ';
	String baseCountSoql = 'SELECT COUNT() FROM Lead Where ';
	String leadSoql = '';
	
	if (campaignIds != '')
	{
		leadSoql += 'Id in (SELECT LeadId From CampaignMember WHERE ' + campaignIds + ' AND ContactId=\'\')';
	}
	if (notCampaignIds != '')
	{
		if (campaignIds != '')
		{
			leadSoql += ' AND ';
		}
		leadSoql += 'Id not in (SELECT LeadId From CampaignMember WHERE ' + notCampaignIds + ')';
	}	
	
	if (leadSOQL == '')
	{
		return leadSOQL;
	}
	else if (getCount == false)
	{
		return baseleadSOQL + leadSOQL + 'LIMIT 50000';
	}	
	else
	{
		return baseCountSoql + leadSOQL + 'LIMIT 50000';
	}
}

public void addLine()
{
	campaignLines.add(new CampaignInclusionLine());
}

public void removeLine()
{
	if (campaignLines.size() != 0)
	{
		campaignLines.remove(campaignLines.size() - 1);
	}
}

public void addContactsToResults(List<Contact> contactResults)
{
	Campaign_Report_Result__c cpr = new Campaign_Report_Result__c();
	for (Contact con : contactResults)
	{
		cpr = new Campaign_Report_Result__c();
		cpr.Contact__c = con.Id;
		cpr.First_Name__c = con.FirstName;
		cpr.Last_Name__c = con.LastName;	
		cpr.Campaign_Report_Header__c = crh.Id;
		cpr.Email__c = con.Email;
		cpr.Company__c = con.Account.Name;
		crResults.add(cpr);		
	}
}

public void addLeadsToResults(List<Lead> leadResults)
{
	Campaign_Report_Result__c cpr = new Campaign_Report_Result__c();
	for (Lead ld : leadResults)
	{
		cpr = new Campaign_Report_Result__c();
		cpr.Lead__c = ld.Id;
		cpr.First_Name__c = ld.FirstName;
		cpr.Last_Name__c = ld.LastName;	
		cpr.Campaign_Report_Header__c = crh.Id;
		cpr.Company__c = ld.Company;
		cpr.Email__c = ld.Email;
		crResults.add(cpr);		
	}	
}

public void makeDisplayResults()
{
	displayResults = new List<Campaign_Report_Result__c>();
	for (Integer i = 0; i < crResults.size() && i < 100; i++)
	{
		displayResults.add(crResults.get(i));
	}
}


public PageReference saveReport()
{
	if (saveOption == 'Save search terms and add results to Campaign' && camMember.CampaignId == null)
	{
		camMember.CampaignId.addError('Campaign is required for this option.');	
		PageReference curPage = ApexPages.currentPage();
		curPage.setRedirect(false);
		return curPage;
	}

	//delete all current filters and results
	
	List<Campaign_Report_Filter__c> oldFilters = [Select Id From Campaign_Report_Filter__c where Campaign_Report_Header__c=:crh.Id];
	List<Campaign_Report_Result__c> oldResults	= [Select Id From Campaign_Report_Result__c where Campaign_Report_Header__c=:crh.Id];
	if (oldFilters != null)
	{
		delete oldFilters;
	}
	if (oldResults != null)
	{
		delete oldResults;
	}
	//then, insert new ones
	
	List<Campaign_Report_Filter__c> filtersToBeInserted = new List<Campaign_Report_Filter__c>();
	Campaign_Report_Filter__c filter = new Campaign_Report_Filter__c();
	for (CampaignInclusionLine cil : campaignLines)
	{
		filter = new Campaign_Report_Filter__c();
		filter.Campaign_Report_Header__c = crh.Id;
		filter.Status__c = cil.camMember.Status;
		filter.Included_Or_Excluded__c = cil.includedExcluded;
		filter.Campaign__c = cil.camMember.CampaignId;
		filtersToBeInserted.add(filter);
	}
	insert filtersToBeInserted;
	
	crh.Report_Options__c = leadOrContact;
	update crh;
	
	if (saveOption == 'Save search terms and results' )
	{
		insert crResults;
	}
	else if (saveOption == 'Save search terms and add results to Campaign')
	{
		List<CampaignMember> cmsToInsert = new List<CampaignMember>();
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
		
		
		CampaignMember cm = new CampaignMember();
		for (Campaign_Report_Result__c crr : crResults)
		{
			if ((crr.Lead__c != null && existingContactsLeads.contains(crr.Lead__c) == false)
			    || (crr.Contact__c != null && existingContactsLeads.contains(crr.Contact__c) == false))
			{
				cm = new CampaignMember();
				cm.CampaignId = camMember.CampaignId;
				cm.Status = camMember.Status;
				cm.ContactId = crr.Contact__c;
				cm.LeadId = crr.Lead__c;
				cmsToInsert.add(cm);
			}
		}
		insert cmsToInsert;
		
		PageReference pageRef = new PageReference('/' + camMember.CampaignId);
		pageRef.setRedirect(false);
		return pageRef ;
	}
	
	PageReference pageRef1 = new PageReference('/' + crh.Id);
	pageRef1.setRedirect(false);
	
	return pageRef1;
}

public PageReference cancel()
{
	return new PageReference('/' + crh.Id);
}

}