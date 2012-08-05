@isTest(SeeAllData=true)
private class RemoteCalcEngineControllerTest 
{
    static testMethod void testController() 
    {
    	String expectedResult = '4';
        // set the mock
        MockRemoteCalcEngine mcre = new MockRemoteCalcEngine( MockRemoteCalcEngine.MockResult.ReturnSuccess, expectedResult);
        
        RemoteCalcEngine.CALLOUT = mcre;
        
        RemoteCalcEngineController rcec = new RemoteCalcEngineController();
        rcec.formula = '2+2';
        PageReference pageRef = rcec.calculateFormula();
        System.assert(pageRef == null);
        
        System.assertEquals(expectedResult, rcec.response);
    }
}