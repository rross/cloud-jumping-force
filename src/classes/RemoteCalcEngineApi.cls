public with sharing class RemoteCalcEngineApi implements IRemoteCalcEngine 
{
	private static final String ENCODING_SCHEME  = 'UTF-8';
	private static final String ACCEPT_HEADER_NAME = 'Accept';
	private static final String TEXT_HTML = 'text/html';
	private static final String APPLICATION_JSON = 'application/json';
	private static final String SCRIPT_FORM_PREFIX = 'script=';

	private String apiEndpoint;

	public RemoteCalcEngineApi(String endPoint)
	{
		apiEndpoint = endPoint;
	}

	public Boolean isRunning()
	{
        try
        {       
            Http httpProtocol = new Http();
                
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setHeader('Accept', 'text/plain');
            request.setMethod('GET');
            // in milliseconds
            request.setTimeout(60000);
            
            HttpResponse httpResponse = httpProtocol.send(request);
            
            String response = httpResponse.getBody();
            
            System.debug('**** TRACE: The response was '+response);
            
            return true;          
        }
        catch(Exception ex)
        {
            System.debug(LoggingLevel.ERROR, '**** ERROR: An unexpected error occured while checking if the service is running: '+apiEndpoint);
            System.debug(LoggingLevel.ERROR, '**** ERROR: Exception: '+ex.getMessage());
            return false;
        }	
	}

	public String calculate(String formula)
	{
        try
        {       
            Http httpProtocol = new Http();
                
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiEndpoint);
            request.setHeader('Accept', 'application/json');
            request.setMethod('POST');
            request.setBody(buildBodyMessage(formula));
            
            HttpResponse httpResponse = httpProtocol.send(request);
            
            String response = httpResponse.getBody();
            
            System.debug('**** TRACE: The response for calculating ' + formula + ' was '+response);
            
            return response;          
        }
        catch(Exception ex)
        {
        	String errorMsg = 'An unexpected error occured while calculating a formula ';
            System.debug(LoggingLevel.ERROR, '**** ERROR: '+errorMsg);
            System.debug(LoggingLevel.ERROR, '**** ERROR: Exception: '+ex.getMessage());
            System.debug(LoggingLevel.ERROR, '**** ERROR: Stack Trace: '+ex.getStackTraceString());
            throw new CalculationException(errorMsg,ex);
        }	
	}

	private string buildBodyMessage(String formula)
	{
		return SCRIPT_FORM_PREFIX + EncodingUtil.urlEncode(formula, ENCODING_SCHEME);
	}
}