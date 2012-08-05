public with sharing class MockRemoteCalcEngine implements IRemoteCalcEngine
{
	public enum MockResult { ReturnSuccess, ReturnFailure, ThrowAnException }

	private MockResult returnWhat;
	private String response;

	public MockRemoteCalcEngine(MockResult returnWhat, String returnValueIfSuccessOrMessageIfFailure)
	{
		this.returnWhat = returnWhat;
		this.response = returnValueIfSuccessOrMessageIfFailure;	
	}

	public Boolean isRunning()
	{
		if (this.returnWhat == MockResult.ThrowAnException)
			throw new MockSimulatedException('Simulated testing exception in isRunning'); 

		return this.returnWhat == MockResult.ReturnSuccess;
	}

	public String calculate(String formula)
	{
		if (this.returnWhat == MockResult.ThrowAnException)
			throw new MockSimulatedException('Simulated testing exception in isRunning');

	    if (this.returnWhat == MockResult.ReturnFailure)
	    	return buildErrorResponse(this.response);

		return buildSuccessResponse(this.response);

	}

	private static String buildErrorResponse(String message)
	{
		RemoteCalcEngineResponse cr = new RemoteCalcEngineResponse();
		cr.result = 'false';
		cr.errorMessage = message;
		cr.answer = '';

		return JSON.serialize(cr);			
	}

	private static String buildSuccessResponse(String answer)
	{
		RemoteCalcEngineResponse cr = new RemoteCalcEngineResponse();
		cr.result = 'true';
		cr.errorMessage = '';
		cr.answer = answer;

		return JSON.serialize(cr);		
	}
}