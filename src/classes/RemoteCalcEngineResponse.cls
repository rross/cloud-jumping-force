public with sharing class RemoteCalcEngineResponse {
	
	// needs to be a string because Apex doesn't know how to parse "true" (surrounded by quotes)
	public String  result { get; set; }
	public String  errorMessage { get; set; }
	public String  answer { get; set; }

	public Boolean calculationResult()
	{
		return Boolean.valueOf(result);
	}

	public String displayAsString()
	{
		return 'result: '+result+' errorMessage: '+errorMessage+' answer: '+answer;
	}	
}