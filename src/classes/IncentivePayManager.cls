public with sharing class IncentivePayManager 
{
	private static final String STATUS_ERROR = 'Error';
	private static final String STATUS_CALCULATED = 'Calculated';
	private static final String NO_ERROR_MESSAGE = '';
	
	private static final String UNIQUE_FIELD_NAME = 'Unique_ID__c';
	private static final String ANSWER_FIELD_NAME = 'Total_Bonus__c';
	private static final String STATUS_FIELD_NAME = 'Calculation_Status__c';
	private static final String ERROR_FIELD_NAME = 'Calculation_Error_Message__c';
	
	private Incentive_Plan__c incentivePlan;
	private Date weekStartingDate;
	private Date weekEndingDate;
	private String weekStartingDateAsString;
	private String query;
	private List<Weekly_Temp_Calc__c> recordsToCalc;
	private List<String> listOfIds;
	private Map<String, Map<String, Schema.SObjectField>> relationshipMap;
	private Map<String, Schema.SObjectField> fieldMap;
	
	public IncentivePayManager(Id planId, Date weekStartingDate)
	{
		incentivePlan = retrieveIncentivePlan(planId);
		this.weekStartingDate = weekStartingDate;
		this.weekEndingDate = weekStartingDate+6; // inclusive
		this.weekStartingDateAsString = formatDate(this.weekStartingDate);		
		
		this.relationshipMap = new Map<String, Map<String, Schema.SObjectField>>();
	}
	
	public void prepareData()
	{
		// first delete any data in the temporary object
		// Note that with a lot of data, this might blow up. 
		delete [SELECT Id 
		          FROM Weekly_Temp_Calc__c 
		         WHERE Week_Start_Date__c = :this.weekStartingDate];

		// run the query
		// with real data we would need to filter out employees to those who are active		         
		query = 
               'SELECT e.Total_Wages__c, e.Phone_Number__c, e.Name, e.Last_Name__c, e.Id, e.First_Name__c, e.Employee_ID__c, ' + 
			   '       (SELECT Id, Name, Customer_Satisfaction_Percentage__c, Week_Start_Date__c ' +
			   '          FROM Weekly_Performance__r ' +
			   '         WHERE Week_Start_Date__c = ' + formatSQLDate(this.weekStartingDate) + '), ' +
			   '       (SELECT Id, Name, Date__c, Total_Number_of_Calls__c, Number_of_Escalated_Calls__c ' + 
			   '          FROM Daily_Performance__r ' +
			   '         WHERE Date__c >= ' + formatSQLDate(this.weekStartingDate) +  
			   '           AND Date__c <= ' + formatSQLDate(this.weekEndingDate)  + ')' + 
			   '  FROM Employee__c e';
			   
		System.debug('The query is\n       '+query);
		List<Employee__c> employeeData = Database.query(query);		
		         
		/*
		List<Employee__c> employeeData = 
		               [SELECT e.Total_Wages__c, e.Phone_Number__c, e.Name, e.Last_Name__c, e.Id, e.First_Name__c, e.Employee_ID__c, 
						       (SELECT Id, Name, Customer_Satisfaction_Percentage__c, Week_Start_Date__c 
						          FROM Weekly_Performance__r
						         WHERE Week_Start_Date__c = :this.weekStartingDate), 
						       (SELECT Id, Name, Date__c, Total_Number_of_Calls__c, Number_of_Escalated_Calls__c 
						          FROM Daily_Performance__r
						         WHERE Date__c >= :this.weekStartingDate
						           AND Date__c <= :this.weekEndingDate) 
						  FROM Employee__c e];
		*/	
		
		System.debug('Found '+employeeData.size()+' records');
		
		buildResultTypeDataStructures(employeeData.get(0));
						  
		recordsToCalc = new List<Weekly_Temp_Calc__c>();
		
		
						  
		// loop through the employee data and create our temporary records
		for(Employee__c emp : employeeData)
		{
			Weekly_Temp_Calc__c wtc = new Weekly_Temp_Calc__c();
			wtc.Calculation_Status__c = 'Queued';
			wtc.Employee__c = emp.Id;
			wtc.Total_Wages__c = emp.Total_Wages__c;
			wtc.Total_Bonus__c = 0;
			wtc.Unique_ID__c = weekStartingDateAsString + '-' + emp.Employee_ID__c;
			wtc.Week_Start_Date__c = this.weekStartingDate;
			wtc.Data__c = buildChildRelationshipData( emp );
			
			recordsToCalc.add(wtc);
		}
		
		insert recordsToCalc;
	}

	public void calculateIncentivePay()
	{
		listOfIds = new List<String>();
		for(Weekly_Temp_Calc__c wtc : recordsToCalc)
		{
			listOfIds.add(wtc.Id);
		}
		
		String javascript = generateJavascript(incentivePlan.Use_Data_From__c, incentivePlan.Function__c, 
				ANSWER_FIELD_NAME, incentivePlan.Data_Field_Name__c, incentivePlan.Function_Name__c, 
				this.recordsToCalc);
		
		// send it to Heroku
		RemoteCalcEngine rce = new RemoteCalcEngine();
		// make sure the engine is running
		rce.isRunning();
		// send 
		String response = rce.calculate(javascript);
		
		handleResponse(response);	
	}
	
	private String generateJavascript(String datasource, String function, String answerField, String jsonFieldName, String functionName, List<SObject> dataObjects)
	{
		JavascriptGenerator jg = new JavascriptGenerator(datasource, answerField, jsonFieldName);
		
		// build the javascript
		String dataSection = jg.buildData('recs', dataObjects );
		String executeSection = jg.buildCallTheJavascriptFunction(functionName);

		return function + '\n\n' + dataSection + '\n\n' + executeSection;		
	}

	private void handleResponse(String response)
	{		
		String soqlQuery = buildUpdateQuery();
		List<SObject> records = Database.query(soqlQuery);

		// there are two scenarios we need to deal with here... 
		// one, there is a single decimal response
		// two, there is an array of responseTypes
		if (!response.startsWith('[{')) 
		{
			System.debug('We only have a single response');
			
			// we have a simple double repsonse
			Double value = (Double) JSON.deserialize( response, Double.class );

			// round the value
			value = roundToDecimals(value, 2);

			// theoretically there should only be one record...
			for(SObject rec: records)
			{
				updateRecordWithValue(rec, value, STATUS_CALCULATED, NO_ERROR_MESSAGE );
			}
			
			update records;

			return;
		}
		
		System.debug('We have a JSON response');

		// we have a json response
		// because salesforce is really particular the way it can deserialize JSON, 
		// we're going to loop through JSON oursevles just looking for the answer field this ourselves
		// you can't currently deserialize into an SObject either... argh...

		Map<String, SObject> externalIdMap = buildExternalIdMap(records);
		List<CalcResult> calcResults = parseResponseToCalcResults(response);
		System.debug('There are '+calcResults.size()+' answers to process');
		for(CalcResult cr : calcResults)
		{
			SObject sobj = externalIdMap.get(cr.externalId);
			updateRecordWithValue(sobj, cr.bonus, STATUS_CALCULATED, NO_ERROR_MESSAGE);
		}

		// finally.. after all of this, we can update our sobjects		
		update records;
	}
			
	private void buildResultTypeDataStructures(SObject aResult)
	{
		Schema.SObjectType sobjType = aResult.getSObjectType();
		System.debug('Building a relationship map for sObjecType of: '+sobjType);

		Schema.DescribeSObjectResult sobjResult = sobjType.getDescribe();

		this.fieldMap = sobjResult.fields.getMap();
		
		String queryLowerCase = query.toLowerCase();

		// get a map of all schema objects
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();		

		List<Schema.ChildRelationship> childRelationships = sobjResult.getChildRelationships();
		for(Schema.ChildRelationship relationship : childRelationships)
		{
			// Is the relationship name being used?
			String relationshipName = relationship.getRelationshipName();
			if (relationshipName != null && queryLowerCase.contains(relationshipName.toLowerCase()))
			{			
				System.debug('Found a relationship within the query: '+ relationshipName);	
				Schema.SObjectType childSObjType = relationship.getChildSObject();
				System.debug('Working with child sObjecType of: '+childSObjType);
				Schema.DescribeSObjectResult childSobjResult = childSObjType.getDescribe();

				Map<String, Schema.SObjectField> childFieldMap = childSobjResult.fields.getMap();

				Map<String, Schema.SObjectField> myChildFieldMap = new Map<String, Schema.SObjectField>();
				for(String key : childFieldMap.keySet())
				{
					myChildFieldMap.put(key, childFieldMap.get(key));
				}

				relationshipMap.put( relationshipName, myChildFieldMap );				
			} 			
		}		
	}
	

	private String buildChildRelationshipData(SObject aRecord)
	{		
		Map<String, Object> childData = new Map<String, Object>();

		for(String relationship : this.relationshipMap.keySet())
		{
			String relationshipLowerCase = relationship.toLowerCase();

			List<SObject> childRecords = aRecord.getSObjects(relationship);
			if (childRecords == null || childRecords.size() == 0)
				continue;

			Map<String, Schema.SObjectField> fieldMap = relationshipMap.get(relationship);

			List<String> fieldNames = new List<String>();
			fieldNames.addAll(fieldMap.keySet());
			fieldNames.sort();

			for(SObject childRec : childRecords)
			{
				for(String fieldName : fieldNames)
				{
					try
					{
						Object fieldValue = childRec.get(fieldName);
						if (fieldValue != null)
						{
							String fieldNameLowerCase = fieldName.toLowerCase();

							// NOTE: it is possible that two child relationships have the same field name
							//       so we're going to put the relationship name in front of the field name
							String fullyQualifiedFieldName = relationship.toLowerCase() + '_' + fieldName;

							Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
							Schema.SOAPType fieldType = fieldResult.getSOAPType();
							if (fieldType == Schema.SOAPType.Integer) 
							{
								Integer newValue = Integer.valueOf(fieldValue);
								if (childData.containsKey(fullyQualifiedFieldName))
								{
									Integer existingValue = (Integer) childData.get(fullyQualifiedFieldName);
									newValue = existingValue + newValue;
								}

								childData.put(fullyQualifiedFieldName, newValue);
							}
							if (fieldType == Schema.SOAPType.Double )
							{
								Double newValue = Double.valueOf(fieldValue);
								if (childData.containsKey(fullyQualifiedFieldName))
								{
									Double existingValue = (Double) childData.get(fullyQualifiedFieldName);
									newValue = existingValue + newValue;
								}
								childData.put(fullyQualifiedFieldName, newValue);
							}
						}	
					}
					catch(SObjectException soe)
					{
						// remove the field from the fieldMap so we don't encounter this exception in the future
						fieldMap.remove(fieldName);
					}
				} // every field name
			}	// every child record
		} // every relationship

		return jsonifyAMap(childData);
	}

	private String jsonifyAMap(Map<String, Object> aMap)	
	{
		String json = '{';
		String comma = '';

		List<String> keys = new List<String>();
		keys.addAll(aMap.keySet());
		keys.sort();

		for(String key : keys)
		{
			json = json + comma + ' ' + '"' + key + '": ' + aMap.get(key);
			comma = ','; 
		}

		json = json + '}';

		System.debug(LoggingLevel.INFO,'**** TRACE JSON RESULTS\n' + json);

		return json;		
	}
		
	private String buildUpdateQuery()
	{
		return 'SELECT Id, Calculation_Status__c, Calculation_Error_Message__c, Data__c, Total_Bonus__c, Unique_ID__c ' + 
		       ' FROM Weekly_Temp_Calc__c  ' + 
		       'WHERE ' + buildListToInStatement('ID', this.listOfIds);   		
	}
	
	private static String buildListToInStatement(String fieldName, List<String> listOfvalues)
	{
		if (listOfValues == null || listOfValues.size() == 0)
			return '';

		String filter = ' ' + fieldName + ' IN (';
		String comma = '';
		for(String value : listOfValues)
		{
			filter = filter + comma + '\'' + value + '\'';
			comma = ',';
		}

		filter = filter + ')';

		return filter;
	}	
	
	private Map<String, SObject> buildExternalIdMap(List<SObject> records)
	{
		Map<String, SObject> theMap = new Map<String, SObject>();
		for(SObject sobj : records)
		{
			String externalIdValue = (String) sobj.get(UNIQUE_FIELD_NAME);
			theMap.put(externalIdValue, sobj);
		}

		return theMap;
	}
	
	private void updateRecordWithValue(SObject record, Object answerFieldValue, 
											  String statusFieldValue, 
									          String errorFieldValue )
	{
		System.debug('Updating '+record.Id+' answer: '+answerFieldValue+' status: '+statusFieldValue+' error: '+errorFieldValue);
		record.put(ANSWER_FIELD_NAME, answerFieldValue);
		record.put(STATUS_FIELD_NAME, statusFieldValue);
		record.put(ERROR_FIELD_NAME, errorFieldValue);
	}
	
	private static List<CalcResult> parseResponseToCalcResults(String response)
	{
		Boolean startObject = false;
		String externalId = null;
		Double bonus = null;
		Integer objectLevel = 0;
		List<CalcResult> calcResults = new List<CalcResult>();

    	JSONParser parser = JSON.createParser(response);
    	while (parser.nextToken() != null)
    	{
            System.debug('CurrentName: ' + parser.getCurrentName());
            System.debug('CurrentToken: ' + parser.getCurrentToken()); 	
            
			if (parser.getCurrentToken() == JSONToken.START_OBJECT)
			{
				startObject = true;
				objectLevel++;
			}
			else if (parser.getCurrentToken() == JSONToken.END_OBJECT)
		    {		    	
				startObject = false;
				objectLevel--;
				if (objectLevel == 0)
				{
					System.debug('ID is '+externalId+' and the bonus is '+bonus);
					CalcResult cResult = new CalcResult();
					cResult.externalId = externalId;
					cResult.bonus = roundToDecimals(bonus, 2);

					calcResults.add(cResult);
				}
		    }

			if (parser.getCurrentName() == UNIQUE_FIELD_NAME && parser.getCurrentToken() == JSONToken.VALUE_STRING)
			{
				//System.debug('Unique Key ID value is '+ parser.getText());
				externalId = parser.getText();
				System.debug('The Unique Key ID is '+externalId);
			}

			if (parser.getCurrentName() == ANSWER_FIELD_NAME)
		    {
		    	if (parser.getCurrentToken() == JSONToken.VALUE_NUMBER_FLOAT) 
		    	{
		    		bonus = parser.getDoubleValue();	
		    	}
		    	else if (parser.getCurrentToken() == JSONToken.VALUE_NUMBER_INT)
		    	{
		    		bonus = parser.getIntegerValue();
		    	}
				//System.debug('Total Bonus value is ' + parser.getDoubleValue());	

				System.debug('The Bonus is '+bonus);
			}            			
    	}
    	
    	return calcResults;
	}	
	
	private static Double roundToDecimals(Double d, Integer places)
    {       
        Double ten = 10.0;
        Double exponent = places;
        Double factorExponent = 0 - (places+1);
        Double roundingFactor = 5 * Math.pow(ten, factorExponent);
        Long temp =((d+roundingFactor) * Math.pow(ten, exponent)).longValue();
        Double returnValue = ( Double.valueOf(temp) / Math.pow(ten, exponent));
        
        return returnValue;
    }  
	
	private Incentive_Plan__c retrieveIncentivePlan(Id planId)
	{
		return [SELECT i.Use_Data_From__c, i.Name, i.Incentive_Plan_Name__c, i.Id, 
		               i.Function__c, i.Function_Name__c, i.Employee_ID_Field_Name__c, 
		               i.Data_Field_Name__c, i.CreatedDate, i.CreatedById 
		          FROM Incentive_Plan__c i
		         WHERE i.Id = :planId];
	}

	public static String formatDate(Date inDate) {

		String outDate = '';

		if (inDate==null) return outDate;

		String mon;
		String da;
		String yr;

		mon = leftPad(inDate.month()+'', 2, '0');
		da = leftPad(inDate.day()+'', 2, '0');
		yr = inDate.year()+'';

		outDate = mon + '/' + da + '/' + yr;	

		return outDate;
	}
	
	public static String formatSQLDate(Date inDate) {

		String outDate = '';

		if (inDate==null) return outDate;

		String mon;
		String da;
		String yr;

		mon = leftPad(inDate.month()+'', 2, '0');
		da = leftPad(inDate.day()+'', 2, '0');
		yr = inDate.year()+'';

		outDate = yr + '-' + mon + '-' + da;	

		return outDate;
	}	

	public static String leftPad(String inString, integer outLength, String inChar) {

		String outString = '';

		if (inString=='' || inString==null) return outString;

		outString = inString;

		for (integer i = inString.length() ; i<outLength ; i++) {
			outString = inChar + outString;
		}

		return outString;
	}
		
	public class CalcResult
    {
    	String externalId;
    	Double bonus;
    }
}