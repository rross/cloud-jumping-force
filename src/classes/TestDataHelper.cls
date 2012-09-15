@isTest
public class TestDataHelper 
{
	
	public static void addCustomSetting(String apiEndpoint)
    {
    	User thisUser = [SELECT Id FROM User where Id = :UserInfo.getUserId() ];
    	System.runAs(thisUser)
    	{
    		RemoteCalcEngineCustomSettings__c rcecs = new RemoteCalcEngineCustomSettings__c();
    		rcecs.API_Endpoint__c = apiEndpoint;
    		
    		insert rcecs;	
    	}
    }
    
	public static Incentive_Plan__c createIncentivePlan()
	{ 
		Incentive_Plan__c ip = new Incentive_Plan__c();
		ip.Data_Field_Name__c = 'Data__c';
		ip.Employee_ID_Field_Name__c = 'Employee_ID__c';
		ip.Function__c = 'function calcBonus(weeklytempcalc) { return 10; }';
		ip.Function_Name__c = 'calcBonus';
		ip.Incentive_Plan_Name__c = 'UNIT TEST Incentive Plan';
		ip.Use_Data_From__c = 'Weekly_Temp_Calc__c';
		
		insert ip;
		
		return ip;
	}
	
	public static Employee__c createEmployee(String firstName, String lastName, Decimal wages, Decimal externalEmpId)
	{
		Employee__c emp = new Employee__c();
		emp.Employee_ID__c = externalEmpId;
		emp.First_Name__c = firstName;
		emp.Last_Name__c = lastName;
		emp.Total_Wages__c = wages;
		
		insert emp;
		
		return emp;
	}
	
	public static Weekly_Performance__c createWeeklyPerformance(Id empId, Date weekStartDate, Decimal custSatPct)
	{
		Weekly_Performance__c weekPerf = new Weekly_Performance__c();
		weekPerf.Employee__c = empId;
		weekPerf.Customer_Satisfaction_Percentage__c = custSatPct;
		weekPerf.Week_Start_Date__c = weekStartDate;
		
		insert weekPerf;
		
		return weekPerf;
	}
	
	public static Daily_Performance__c createDailyPerformance(Id empId, Date aDate, Decimal numEscalatedCalls, Decimal numTotalCalls)
	{
		Daily_Performance__c dailyPerf = new Daily_Performance__c();
		dailyPerf.Employee__c = empId;
		dailyPerf.Date__c = aDate;
		dailyPerf.Number_of_Escalated_Calls__c = numEscalatedCalls;
		dailyPerf.Total_Number_of_Calls__c = numTotalCalls;
		
		insert dailyPerf;
		
		return dailyPerf;
	}
}