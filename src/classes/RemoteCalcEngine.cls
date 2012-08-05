public with sharing class RemoteCalcEngine 
{
	public static IRemoteCalcEngine CALLOUT;
	
	private String endpoint;
	
	public RemoteCalcEngine()
	{
		loadProperties();
		if (CALLOUT == null)
		{
			System.debug(LoggingLevel.INFO, '*** NOTE: Callout NOT specified. Using real callout with endpoint of '+this.endPoint);
			RemoteCalcEngineApi api = new RemoteCalcEngineApi(this.endPoint);
			CALLOUT = api;
		}
	}
	
	public Boolean isRunning()
	{
		return CALLOUT.isRunning();
	}
	
	public String calculate(String formula)
	{
		
		System.debug(LoggingLevel.DEBUG, '**** TRACE: formula: '+formula);
		
		String jsonResponse = CALLOUT.calculate(formula);
		
		System.debug(LoggingLevel.INFO, '**** TRACE: RAW response: '+jsonREsponse);

		RemoteCalcEngineResponse calcResponse = (RemoteCalcEngineResponse) JSON.deserialize(jsonREsponse, RemoteCalcEngineResponse.class);

		System.debug('**** TRACE: results: '+calcResponse.displayAsString());

		if (!calcResponse.calculationResult())
		{
			throw new CalculationException(calcResponse.errorMessage);
		}

		return calcResponse.answer;
	}
	
	private void loadProperties()
	{
		RemoteCalcEngineCustomSettings__c rce = RemoteCalcEngineCustomSettings__c.getOrgDefaults();
		if (rce.API_Endpoint__c  == null || rce.API_Endpoint__c == '')
		{
			throw new CalculationException('FATAL: Missing Org Defaults for Calculation Engine');
		}

		System.debug('Using the following CalculationEngine Settings');
		System.debug('API EndPoint: '+rce.API_Endpoint__c);

		endPoint = rce.API_Endpoint__c;
	}
}