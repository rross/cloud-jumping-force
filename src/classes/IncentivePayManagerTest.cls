@isTest
private class IncentivePayManagerTest 
{
	private static final String API_ENDPOINT = 'unittestendpoint';
	
    static testMethod void testWithSingleResult() 
    {
    	String mockReturnValueAsString = '10';
    	Decimal mockReturnValueAsDecimal = Decimal.valueOf(mockReturnValueAsString);
    	
    	// set up the MockCalcEngine
    	TestDataHelper.addCustomSetting(API_ENDPOINT);
    	RemoteCalcEngine.CALLOUT = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ReturnSuccess, mockReturnValueAsString);
    	
    	// create an incentive plan	
    	Incentive_Plan__c ip = TestDataHelper.createIncentivePlan();
    	Date weekStartingDate = Date.valueOf('2222-01-05');
    	
    	// create some data..
    	Employee__c emp1 = TestDataHelper.createEmployee('UNIT1', 'TEST1', 100, 1);
		createEmpChildData(emp1.Id, weekStartingDate);
    	
    	Employee__c emp2 = TestDataHelper.createEmployee('UNIT2', 'TEST2', 200, 2);
    	createEmpChildData(emp2.Id, weekStartingDate);
    	
    	IncentivePayManager ipm = new IncentivePayManager(ip.Id, weekStartingDate);
    	ipm.prepareData();
    	ipm.calculateIncentivePay();
    	
    	// now verify the results
    	List<Weekly_Temp_Calc__c> answers = 
		    	[SELECT w.Week_Start_Date__c, w.Unique_ID__c, w.Total_Bonus__c, w.Name, w.Id, w.Employee__c, w.Data__c, w.Calculation_Status__c, w.Calculation_Error_Message__c 
		    	  FROM Weekly_Temp_Calc__c w
		    	 WHERE w.Week_Start_Date__c = :weekStartingDate];
		    	 
		System.assertEquals(2, answers.size());
		
		for(Weekly_Temp_Calc__c wtc : answers)
		{
			System.assertEquals('Calculated', wtc.Calculation_Status__c);
			System.assertEquals(mockReturnValueAsDecimal, wtc.Total_Bonus__c);
		}
		
    }
    
    static testMethod void testWithJsonResult()
    {
    	String mockReturnValueAsString = '[{"Calculation_Error_Message__c":null,"Calculation_Status__c":null,"Data__c":{"daily_performance__r_number_of_escalated_calls__c":45,"daily_performance__r_total_number_of_calls__c":1500,"weekly_performance__r_customer_satisfaction_percentage__c":98.3},"Employee__c":"a00E0000003wkibIAA","Total_Bonus__c":10,"Unique_ID__c":"01/05/2222-1","Week_Start_Date__c":"2222-02-05T00:00:00Z"},{"Calculation_Error_Message__c":null,"Calculation_Status__c":null,"Data__c":{"daily_performance__r_number_of_escalated_calls__c":45,"daily_performance__r_total_number_of_calls__c":1500,"weekly_performance__r_customer_satisfaction_percentage__c":98.3},"Employee__c":"a00E0000003wkicIAA","Total_Bonus__c":10,"Unique_ID__c":"01/05/2222-2","Week_Start_Date__c":"2222-02-05T00:00:00Z"}]';
    	Decimal expectedResult = 10.0;
    	
    	// set up the MockCalcEngine
    	TestDataHelper.addCustomSetting(API_ENDPOINT);
    	RemoteCalcEngine.CALLOUT = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ReturnSuccess, mockReturnValueAsString);
    	
    	// create an incentive plan	
    	Incentive_Plan__c ip = TestDataHelper.createIncentivePlan();
    	Date weekStartingDate = Date.valueOf('2222-01-05');
    	
    	// create some data..
    	Employee__c emp1 = TestDataHelper.createEmployee('UNIT1', 'TEST1', 100, 1);
		createEmpChildData(emp1.Id, weekStartingDate);
    	
    	Employee__c emp2 = TestDataHelper.createEmployee('UNIT2', 'TEST2', 200, 2);
    	createEmpChildData(emp2.Id, weekStartingDate);
    	
    	IncentivePayManager ipm = new IncentivePayManager(ip.Id, weekStartingDate);
    	ipm.prepareData();
    	ipm.calculateIncentivePay();
    	
    	// now verify the results
    	List<Weekly_Temp_Calc__c> answers = 
		    	[SELECT w.Week_Start_Date__c, w.Unique_ID__c, w.Total_Bonus__c, w.Name, w.Id, w.Employee__c, w.Data__c, w.Calculation_Status__c, w.Calculation_Error_Message__c 
		    	  FROM Weekly_Temp_Calc__c w
		    	 WHERE w.Week_Start_Date__c = :weekStartingDate];
		    	 
		System.assertEquals(2, answers.size());
		
		for(Weekly_Temp_Calc__c wtc : answers)
		{
			System.assertEquals('Calculated', wtc.Calculation_Status__c);
			System.assertEquals(expectedResult, wtc.Total_Bonus__c);
		}
    	
    }
    
    private static void createEmpChildData(Id empId, Date weekStartingDate)
    {
    	// create some child data records
    	Weekly_Performance__c weeklyPerf1 = TestDataHelper.createWeeklyPerformance(empId, weekStartingDate, 98.3);
    	for(Integer i=1;i<6;i++)
    	{
    		Daily_Performance__c dailyPerf = TestDataHelper.createDailyPerformance(empId, weekStartingDate+i, 3*i, 100*i);
    	}
    }
}