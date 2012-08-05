@isTest
private class JavascriptGeneratorTest {

	static testMethod void testCreateJavascriptNeedingJson()
	{
		JavascriptGenerator jsHelper = new JavascriptGenerator('Weekly_Temp_Calc__c', 'Total_Bonus__c', 'Data__c');		

	    List<SObject> dataObjects = new List<SObject>();

	    Weekly_Temp_Calc__c dynData = new Weekly_Temp_Calc__c();
	    dynData.Calculation_Error_Message__c = null;
	    dynData.Calculation_Status__c = null;
	    dynData.Unique_ID__c = '07/29/2222_1';
	    dynData.Data__c = 
				'{' + 
				'		\"some_relationship__r_some_field__c\": 6484,' + 
				'		\"some_relationship__r_another_field__c\": 77,' + 
				'	},';
		dynData.Employee__c = null;
		dynData.Week_Start_Date__c = Date.ValueOf('2222-04-15');
		dynData.Total_Bonus__c = 0;

	    dataObjects.add(dynData);

		// build the javascript
		String dataSection = jsHelper.buildData('records', dataObjects );

        System.debug('**** DATA SECTION ****');
		System.debug(dataSection);

		System.assertEquals( true, dataSection.contains('JSON.parse'));
		System.assertEquals( true, dataSection.contains('\\"'));
	}

    static testMethod void testCreateJavascriptClassFromSObjectByName() 
    {
        String classDef = JavascriptGenerator.createJavascriptClassFromSObjectByName('Weekly_Temp_Calc__c');
        System.assert(classDef != null);
        
        String expectedResult = 
        'function Weekly_Temp_Calc__c ()\n'+
		'{   this.Calculation_Error_Message__c = null;\n'+
		'   this.Calculation_Status__c = null;\n'+
		'   this.CreatedById = null;\n'+
		'   this.CreatedDate = null;\n'+
		'   this.Data__c = null;\n'+
		'   this.Employee__c = null;\n'+
		'   this.Id = null;\n'+
		'   this.IsDeleted = null;\n'+
		'   this.LastModifiedById = null;\n'+
		'   this.LastModifiedDate = null;\n'+
		'   this.Name = null;\n'+
		'   this.OwnerId = null;\n'+
		'   this.SystemModstamp = null;\n'+
		'   this.Total_Bonus__c = null;\n'+
		'   this.Unique_ID__c = null;\n'+
		'   this.Week_Start_Date__c = null;\n'+
		'}\n';
		        	
        System.assertEquals(expectedResult, classDef);
    }
    
    static testMethod void testCreateJavascriptClassFromSObject()
    {
    	Weekly_Temp_Calc__c wtc = new Weekly_Temp_Calc__c();
        String classDef = JavascriptGenerator.createJavascriptClassFromSObject(wtc);
        System.assert(classDef != null);
        
        String expectedResult = 
	        'function Weekly_Temp_Calc__c ()\n'+
			'{   this.Calculation_Error_Message__c = null;\n'+
			'   this.Calculation_Status__c = null;\n'+
			'   this.CreatedById = null;\n'+
			'   this.CreatedDate = null;\n'+
			'   this.Data__c = null;\n'+
			'   this.Employee__c = null;\n'+
			'   this.Id = null;\n'+
			'   this.IsDeleted = null;\n'+
			'   this.LastModifiedById = null;\n'+
			'   this.LastModifiedDate = null;\n'+
			'   this.Name = null;\n'+
			'   this.OwnerId = null;\n'+
			'   this.SystemModstamp = null;\n'+
			'   this.Total_Bonus__c = null;\n'+
			'   this.Unique_ID__c = null;\n'+
			'   this.Week_Start_Date__c = null;\n'+
			'}\n';        	
        System.assertEquals(expectedResult, classDef);    	
    }
    
    static testMethod void testBuildDataOneRecord()
    {
    	JavascriptGenerator jsHelper = new JavascriptGenerator('Weekly_Temp_Calc__c', 'Total_Bonus__c', 'Data__c');		
    	System.assert(jsHelper != null);
    	
    	List<SObject> records = new List<SObject>();
    	Weekly_Temp_Calc__c wtc = new Weekly_Temp_Calc__c();
    	wtc.Calculation_Error_Message__c = '';
    	wtc.Calculation_Status__c = '';
    	wtc.Data__c = '{ \"some_relationship__r.some_field__c\": 1234 }'; 
    	wtc.Employee__c = null;
    	wtc.Total_Bonus__c = 0;
    	wtc.Unique_ID__c = 'UTID1';
    	wtc.Week_Start_Date__c = Date.valueOf('2012-08-05');
    	
    	records.add(wtc);
    	
    	String recordDef = jsHelper.buildData('rec', records);
    	System.assert(recordDef != null);
		
		String expectedDef = 
			'function Weekly_Temp_Calc__c (calculationerrormessage, calculationstatus, data, employee, totalbonus, uniqueid, weekstartdate )\n'+
			'{\n'+
			'   this.Calculation_Error_Message__c = calculationerrormessage;\n'+
			'   this.Calculation_Status__c = calculationstatus;\n'+
			'   this.Data__c =  JSON.parse( data );\n'+
			'   this.Employee__c = employee;\n'+
			'   this.Total_Bonus__c = totalbonus;\n'+
			'   this.Unique_ID__c = uniqueid;\n'+
			'   this.Week_Start_Date__c = weekstartdate;\n'+
			'}\n'+
			'\n'+
			'var rec = new Weekly_Temp_Calc__c( "", "", "{ \\"some_relationship__r.some_field__c\\": 1234 }", null, 0, "UTID1", new Date(2012, 8, 5, 0, 0, 0, 0 ));\n\n'; 		

		System.debug('length of expected '+expectedDef.length());
		System.debug('length of actual '+recordDef.length());	
		System.assertEquals(expectedDef.trim(), recordDef.trim());    

		String fnCall = jsHelper.buildCallTheJavascriptFunction('calcTotalBonus');
		System.assertEquals('calcTotalBonus(rec);', fnCall); 	
    }
    
    static testMethod void testBuildDataTwoRecords()
    {
    	JavascriptGenerator jsHelper = new JavascriptGenerator('Weekly_Temp_Calc__c', 'Total_Bonus__c', 'Data__c');		
    	System.assert(jsHelper != null);
    	
    	List<SObject> records = new List<SObject>();
    	Weekly_Temp_Calc__c wtc = new Weekly_Temp_Calc__c();
    	wtc.Calculation_Error_Message__c = '';
    	wtc.Calculation_Status__c = '';
    	wtc.Data__c = '{ \"some_relationship__r.some_field__c\": 1234 }'; 
    	wtc.Employee__c = null;
    	wtc.Total_Bonus__c = 0;
    	wtc.Unique_ID__c = 'UTID1';
    	wtc.Week_Start_Date__c = Date.valueOf('2012-08-05');
    	
    	records.add(wtc);
    	
    	Weekly_Temp_Calc__c wtc2 = new Weekly_Temp_Calc__c();
    	wtc2.Calculation_Error_Message__c = '';
    	wtc2.Calculation_Status__c = '';
    	wtc2.Data__c = '{ \"some_relationship__r.some_field__c\": 1234 }'; 
    	wtc2.Employee__c = null;
    	wtc2.Total_Bonus__c = 0;
    	wtc2.Unique_ID__c = 'UTID2';
    	wtc2.Week_Start_Date__c = Date.valueOf('2012-08-12');
    	
    	records.add(wtc2);
    	
    	String recordDef = jsHelper.buildData('rec', records);
    	System.assert(recordDef != null);
    	
    	System.debug('\n'+recordDef);    	
    	
    	String expectedDef =
			'function Weekly_Temp_Calc__c (calculationerrormessage, calculationstatus, data, employee, totalbonus, uniqueid, weekstartdate )\n'+
			'{\n'+
			'   this.Calculation_Error_Message__c = calculationerrormessage;\n'+
			'   this.Calculation_Status__c = calculationstatus;\n'+
			'   this.Data__c =  JSON.parse( data );\n'+
			'   this.Employee__c = employee;\n'+
			'   this.Total_Bonus__c = totalbonus;\n'+
			'   this.Unique_ID__c = uniqueid;\n'+
			'   this.Week_Start_Date__c = weekstartdate;\n'+
			'}\n'+
			'\n'+
			'var rec = [];\n'+
			'\n'+
			'function xxxDataDefxxx0()\n'+
			'{\n'+
			'   rec[0] = new Weekly_Temp_Calc__c( "", "", "{ \\"some_relationship__r.some_field__c\\": 1234 }", null, 0, "UTID1", new Date(2012, 8, 5, 0, 0, 0, 0 )); \n'+ 
			'   rec[1] = new Weekly_Temp_Calc__c( "", "", "{ \\"some_relationship__r.some_field__c\\": 1234 }", null, 0, "UTID2", new Date(2012, 8, 12, 0, 0, 0, 0 )); \n'+
			'}\n\n';
    	
		System.debug('length of expected '+expectedDef.length());
		System.debug('length of actual '+recordDef.length());	

		System.assertEquals(expectedDef.trim(), recordDef.trim());    

		String fnCall = jsHelper.buildCallTheJavascriptFunction('calcTotalBonus');
		
		System.debug('\n'+fnCall);
		
		String expectedFnCall = 
			'function calcTotalBonusArrayHelper(recs)\n'+
			'{\n'+
			'   xxxDataDefxxx0();\n'+
			'   recs.forEach(function(x, idx)\n'+
			'   {\n'+
			'      x.Total_Bonus__c = calcTotalBonus(x);\n'+
			'   });\n'+
			'\n'+
			'   return recs;\n'+
			'}\n'+
			'\n'+
			'var XXfinalCalcResultXX = calcTotalBonusArrayHelper(rec);\n'+
			'\n'+
			'JSON.stringify(XXfinalCalcResultXX);\n';
		
    	System.assertEquals(expectedFnCall, fnCall); 
    }
    

/*    
    static testMethod void testBuildDataTwoRecords()
    {
    	JavascriptGenerator jsHelper = new JavascriptGenerator('FIP_Dynamic_Data__c', 'Total_Bonus__c', null);
    	System.assert(jsHelper != null);
    	
    	List<SObject> records = new List<SObject>();
    	FIP_Dynamic_Data__c fip = new FIP_Dynamic_Data__c();
   		fip.Calculation_Error_Message__c = '';
   		fip.Calculation_Status__c = ''; 
   		fip.Company__c = 'UTAPPLE';
   		fip.Composite_Key_ID__c = 'cs1';
   		fip.Data__c = '{ \"crn_call_data__r_acw_time__c\": 6484 }';
   		fip.Pay_Week_Ending_Date__c = Date.valueOf('2012-05-10');
   		fip.Ref_Num_Unit__c = 10;
   		fip.Title__c = 'UTTier 1 Advisor';
   		fip.Total_Bonus__c = 0;
    	
    	records.add(fip);
    	    	
    	FIP_Dynamic_Data__c fip2 = new FIP_Dynamic_Data__c();
   		fip2.Calculation_Error_Message__c = '';
   		fip2.Calculation_Status__c = ''; 
   		fip2.Company__c = 'UTAPPLE';
   		fip2.Composite_Key_ID__c = 'cs2';
   		fip2.Data__c = '{ \"crn_call_data__r_acw_time__c\": 6484 }';
   		fip2.Pay_Week_Ending_Date__c = Date.valueOf('2012-04-30');
   		fip2.Ref_Num_Unit__c = 10;
   		fip2.Title__c = 'UTTier 1 Advisor';
   		fip2.Total_Bonus__c = 0;    	
    	    	
    	records.add(fip2);    	
    	
    	String recordDef = jsHelper.buildData('rec', records);
    	System.assert(recordDef != null);
    	
    	String expectedDef = 
			'function FIP_Dynamic_Data__c (calculationerrormessage, calculationstatus, company, compositekeyid, data, employee, payweekendingdate, refnumunit, supervisor, title, totalbonus, unitsearned )\n' +
			'{\n' +
			'   this.Calculation_Error_Message__c = calculationerrormessage;\n' +
			'   this.Calculation_Status__c = calculationstatus;\n' +
			'   this.Company__c = company;\n' +
			'   this.Composite_Key_ID__c = compositekeyid;\n' +
			'   this.Data__c = data;\n' +
			'   this.Employee__c = employee;\n' +
			'   this.Pay_Week_Ending_Date__c = payweekendingdate;\n' +
			'   this.Ref_Num_Unit__c = refnumunit;\n' +
			'   this.Supervisor__c = supervisor;\n' +
			'   this.Title__c = title;\n' +
			'   this.Total_Bonus__c = totalbonus;\n' +
			'   this.Units_Earned__c = unitsearned;\n' +
			'}\n' +
			'\n' +
			'var rec = [];\n' +
			'\n' +
			'function xxxDataDefxxx0()\n' +
			'{\n' +
			'   rec[0] = new FIP_Dynamic_Data__c( "", "", "UTAPPLE", "cs1", "{ "crn_call_data__r_acw_time__c": 6484 }", null, new Date(2012, 5, 10, 0, 0, 0, 0 ), 10, null, "UTTier 1 Advisor", 0); \n' +
			'   rec[1] = new FIP_Dynamic_Data__c( "", "", "UTAPPLE", "cs2", "{ "crn_call_data__r_acw_time__c": 6484 }", null, new Date(2012, 4, 30, 0, 0, 0, 0 ), 10, null, "UTTier 1 Advisor", 0); \n' +
			'}\n\n';

		System.debug('length of expected '+expectedDef.length());
		System.debug('length of actual '+recordDef.length());	

		System.assertEquals(expectedDef.trim(), recordDef.trim());    

		String fnCall = jsHelper.buildCallTheJavascriptFunction('calcTotalBonus');

		String expectedFnCall =
			'function calcTotalBonusArrayHelper(recs)\n' +
			'{\n' +
			'   xxxDataDefxxx0();\n' +
			'   recs.forEach(function(x, idx)\n' +
			'   {\n' +
			'      x.Total_Bonus__c = calcTotalBonus(x);\n' +
			'   });\n' +
			'\n' +
			'   return recs;\n' +
			'}\n' +
			'\n' +
			'var XXfinalCalcResultXX = calcTotalBonusArrayHelper(rec);\n' +
			'\n' +
			'JSON.stringify(XXfinalCalcResultXX);\n';

		System.assertEquals(expectedFnCall, fnCall); 	
    }
    */
    
}