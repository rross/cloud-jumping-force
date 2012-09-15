public with sharing class IncentivePayController 
{
	public Proxy__c proxy { get; set; }
	public List<Weekly_Temp_Calc__c> results { get; set; }
	public Boolean haveResults { get { return results.size() > 0; } }
	public Boolean preparedData { get; set; }
	public Boolean calculatedResults { get; set; }
	
	private IncentivePayManager incentivePayMgr; 
	
	public IncentivePayController()
	{
		results = new List<Weekly_Temp_Calc__c>();
		proxy = new Proxy__c();
		proxy.Week_Starting_Date__c = getPriorSunday();
		preparedData = false;
		calculatedResults = false;		
	}
	
	public PageReference prepareData()
	{
		try
		{
			incentivePayMgr = new IncentivePayManager(proxy.Incentive_Plan__c, proxy.Week_Starting_Date__c);
			incentivePayMgr.prepareData();
			
			preparedData = true;
		}
		catch(Exception ex)
		{
			System.debug('There was a problem calculating the incentive pay. '+ex.getMessage());
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'An error occurred while processing your request. '+ex.getMessage()+'\n'+ex.getStackTraceString()));
		}
		 			
		return null;		
	}
	
	public PageReference calculate()
	{
		try
		{
			incentivePayMgr.calculateIncentivePay();
			
			calculatedResults = true;
		
			results = [SELECT w.Week_Start_Date__c, w.Unique_ID__c, w.Total_Wages__c, w.Total_Bonus__c, w.Name, w.Id, w.Employee__c, w.Data__c, w.Calculation_Status__c, w.Calculation_Error_Message__c 
			  			 FROM Weekly_Temp_Calc__c w
			 			WHERE w.Week_Start_Date__c = :proxy.Week_Starting_Date__c];
		}
		catch(Exception ex)
		{
			System.debug('There was a problem calculating the incentive pay. '+ex.getMessage());
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'An error occurred while processing your request. '+ex.getMessage()+'\n'+ex.getStackTraceString()));
		}
		 			
		return null;
	}
	
	private Date getPriorSunday()
	{
		Date aDate = Date.today();
		// note this is locale specific
		// US locales will return a Sunday. 
		// European Locales will return a Monday.
		return aDate.toStartOfWeek();
	}
}