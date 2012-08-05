public with sharing class RemoteCalcEngineController 
{
	public String formula { get; set; }
	public Boolean isRunning { get; set; }
	public String response { get; set; }
	
	public PageReference calculateFormula()
	{
		RemoteCalcEngine rce = new RemoteCalcEngine();
		this.isRunning = rce.isRunning();	
		this.response = rce.calculate(this.formula);
		
		return null;
	}
	
	
}