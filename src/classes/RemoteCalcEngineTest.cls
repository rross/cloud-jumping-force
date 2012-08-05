@isTest
private class RemoteCalcEngineTest {
	private static final String API_ENDPIONT = 'http://foo.com';
	
	static testMethod void testCalcEngineWithoutCustomSettings()
	{
		try
		{
			RemoteCalcEngine calcEngine = new RemoteCalcEngine();
			// no custom setting, should throw an exception
			System.assert(false);
		}
		catch(CalculationException ce)
		{
			// expected
			System.assert(true);
		}
	}
	
    static testMethod void testCalcEngineSuccess() 
    {
    	addCustomSetting(API_ENDPIONT);
    	
    	RemoteCalcEngine.CALLOUT = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ReturnSuccess, '10');

		RemoteCalcEngine calcEngine = new RemoteCalcEngine();
		System.assert(calcEngine.isRunning());

		String formula = 'function calc() { return 10; }';
		String response = calcEngine.calculate(formula);
		System.assert(response != null);
		System.assertEquals('10', response);
    }
    
    static testMethod void testCalcEngineFailure()
    {
    	addCustomSetting(API_ENDPIONT);
    	
    	RemoteCalcEngine.CALLOUT = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ReturnFailure, 'an error occurred');

		RemoteCalcEngine calcEngine = new RemoteCalcEngine();
		System.assert(!calcEngine.isRunning());

		String formula = 'function calc() { return 10; }';
		try
		{
			String response = calcEngine.calculate(formula);
			System.assert(false);
		}
		catch(Exception e)
		{
			System.assert(true);
		}
    }
    
    static testMethod void testCalcEngineException()
    {
    	addCustomSetting(API_ENDPIONT);
    	
    	RemoteCalcEngine.CALLOUT = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ThrowAnException, 'Blamo Exception!');

		RemoteCalcEngine calcEngine = new RemoteCalcEngine();
		try
		{
			calcEngine.isRunning();
			System.assert(false);
		}
		catch(Exception e)
		{
			System.assert(true);
		}

		String formula = 'function calc() { return 10; }';

		try
		{
			String response = calcEngine.calculate(formula);
			System.assert(false);
		}
		catch(Exception e)
		{
			System.assert(true);
		}  	
    }
    
    private static void addCustomSetting(String apiEndpoint)
    {
    	User thisUser = [SELECT Id FROM User where Id = :UserInfo.getUserId() ];
    	System.runAs(thisUser)
    	{
    		RemoteCalcEngineCustomSettings__c rcecs = new RemoteCalcEngineCustomSettings__c();
    		rcecs.API_Endpoint__c = apiEndpoint;
    		
    		insert rcecs;	
    	}
    }
}