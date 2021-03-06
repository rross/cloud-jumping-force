public with sharing class JavascriptGenerator 
{
	// due to an issue with Java 6 and Rhio
	// we need to chunk up the data definitions 
	// to avoid exceeding the 64KB Java Method size
	// (The error returned from the server is:
	//   sun.org.mozilla.javascript.EvaluatorException: Encountered code generation error while compiling script: generated bytecode for method exceeds 64K limit. (<Unknown source>#1) in <Unknown source> at line number 1
	// )
	private static Integer MAX_CHUNK_SIZE = 50;
	private static String  DATA_CHUNK_METHOD_NAME_PREFIX = 'xxxDataDefxxx';

	String sObjectName;
	private List<String> sortedFieldNames;
	private Map<String, FieldInfo> internalFieldMap;
	private String variableName;
	private Integer numRecords;
	private Map<String, String> variableMap;
	private String fieldForAnswer;
	private String functionParameters;
	private Integer numberOfDataChunks;
	private String jsonFieldName;

	//
	// Construct this class with a semi-colon delimited list of parameters
	// (Use the Incentive_Plan__c.Use_Data_From__c field)
	//
	// e.g. Interim_Weekly_Calc; <some other object api name>
	//
	// Also, pass in the fieldName that the calculation should wind up in
	// This is only used when an array of records is passed in. 
	// (e.g. For Interim_Weekly_Calc, you would use the 'Total_Bonus__c' 
	// as the value for the answerField parameter)
	//
	public JavascriptGenerator(String functionParms, String answerField, 
		String jsonFieldName)
	{		
		this.functionParameters = functionParms;
		this.variableMap = new Map<String, String>();
		this.fieldForAnswer = answerField;
		this.jsonFieldName = jsonFieldName;
	}

	public String buildData(String variableName, List<SObject> records)
	{
		if (records == null || records.size() == 0)
		{
			System.debug('ERROR: No data provided.');
			return null;
		}

		// we need to get the sObjectName 
		// and save the mapping for later use when we're ready 
		// to actually call the method with data in the correct
		// order...
		Schema.SObjectType sobjType = records[0].getSObjectType();
		Schema.DescribeSObjectResult sobjResult = sobjType.getDescribe();
		String sobjectName = sobjResult.getName();		
		System.debug('saving sobjectName: '+sobjectName+' as variable '+variableName);
		this.variableMap.put(sobjectName, variableName);

		this.numRecords = records.size();

		String typeDeclaration = defineSobjectWithParams(records[0]);

		String dataDeclaration = '';

		if (numRecords == 1)
		{
			dataDeclaration = 'var ' + variableName + ' = new ' + sObjectName + 
				buildDataDeclaration(records[0]);	
		}
		else
		{
			dataDeclaration = 'var ' + variableName + ' = [];\n';
			Integer index = 0;
			Integer chunkIndex = 0;
			String closeInterimMethod = '';
			for(Sobject rec : records)
			{
				if (Math.mod(index,MAX_CHUNK_SIZE) == 0)
				{
					dataDeclaration = dataDeclaration + closeInterimMethod + '\nfunction ' +  
						DATA_CHUNK_METHOD_NAME_PREFIX + chunkIndex + '()\n{\n';
					closeInterimMethod = '}\n';
					chunkIndex++;
				}
				dataDeclaration = dataDeclaration + '   ' + variableName + '['+ index + '] = new ' + 
					sObjectName + buildDataDeclaration(rec) + '\n';
				index++;
			}

			dataDeclaration = dataDeclaration + closeInterimMethod;

			numberOfDataChunks = chunkIndex;
		}

		return typeDeclaration + '\n' + dataDeclaration + '\n';		
	}

	public String buildCallTheJavascriptFunction(String functionName)
	{
		// if there is only one record, we call the function directly
		if (this.numRecords == 1)
			return functionName + buildFunctionCall(null) + ';';
		else
		{
			// 
			// otherwise we need to wrapper class that loops through the records
			// 
			String arrayHelperFunctionName = functionName + 'ArrayHelper';

			String dataChunking = '';
			for(Integer i=0;i< numberOfDataChunks;i++)
			{
				dataChunking = dataChunking + '   ' + DATA_CHUNK_METHOD_NAME_PREFIX + i + '();\n';
			}

			String javaScript = 
			       'function ' + arrayHelperFunctionName + '(recs)\n{\n' +
			       dataChunking + 
				   '   recs.forEach(function(x, idx)\n' +
				   '   {\n' +
				   '      x.' + fieldForAnswer + ' = ' + functionName + buildFunctionCall('x') + ';\n' +
				   '   });\n' +
				   '\n' +
				   '   return recs;\n' + 
				   '}\n' + 

				   '\n' +
				   'var XXfinalCalcResultXX = ' + arrayHelperFunctionName + buildFunctionCall(null) + ';\n' +
				   '\n' + 
				   'JSON.stringify(XXfinalCalcResultXX);\n';

			return javaScript;    
		}
	}

	// use this method to create a Javascript definition of a class 
	// that initializes the JavaScript fields to the field values within the sObject
	public static String createJavascriptClassFromSObject(SObject anObject)
	{
		Schema.SObjectType sobjType = anObject.getSObjectType();
		System.debug('Working with sObjecType of: '+sobjType);

		Schema.DescribeSObjectResult sobjResult = sobjType.getDescribe();

		String javascriptClass = buildClassDefinition(sobjResult.getName());	

		// get a map of fields
		Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
		List<String> fieldNames = new List<String>();
		fieldNames.addAll(fieldMap.keySet());
		fieldNames.sort();
		for(String name : fieldNames)
		{
			Schema.DescribeFieldResult fieldResult = fieldMap.get(name).getDescribe();
   			
   			javascriptClass = javascriptClass + buildFieldDefinitionWithValue(
   				fieldResult.getName(), fieldResult.getSOAPType() , anObject.get(name), 
   				false) + '\n';
   		   			
   			System.debug('FieldName: '+fieldResult.getName() + ' Type: ' + 
   				fieldResult.getType()  + ' Length: ' + fieldResult.getLength());
		}		

		javascriptClass = javascriptClass + buildClosingClassDefintion();

		System.debug('Final javascript class definition is \n'+javascriptClass);

		return javascriptClass;					
	}

	// Use this method to generate a JavaScript object from an SObject using only
	// the name of the sobject. Each of the fields will be set to null
	public static String createJavascriptClassFromSObjectByName(String sobjectName)
	{
		// get a map of all schema objects
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		Schema.SObjectType sobjType = globalDescribe.get(sobjectName.toLowerCase());
		System.debug('Working with sObjecType of: '+sobjType);

		Schema.DescribeSObjectResult sobjResult = sobjType.getDescribe();

		String javascriptClass = buildClassDefinition(sobjResult.getName());

		// get a map of fields
		Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
		List<String> fieldNames = new List<String>();
		fieldNames.addAll(fieldMap.keySet());
		fieldNames.sort();
		for(String name : fieldNames)
		{
   			Schema.DescribeFieldResult fieldResult = fieldMap.get(name).getDescribe();
   			
   			javascriptClass = javascriptClass + buildFieldDefinition(fieldResult.getName()) + '\n';
   
   			System.debug('FieldName: '+fieldResult.getName() + ' Type: ' + fieldResult.getType()  + 
   				' Length: ' + fieldResult.getLength());
		}

		javascriptClass = javascriptClass + buildClosingClassDefintion();

		System.debug('Final javascript class definition is \n'+javascriptClass);

		return javascriptClass;		
	}

	//
	// This method "cleans up" an sObject to a more friendly name
	//
	public static String nameFunctionParameterFromSObject(String sobjectName)
	{
		if (sobjectName == null || sobjectName == '')
			return null;

		// convert to lowercase
		String parmName = sobjectName.toLowerCase();
		// replace __c with nothing
		parmName = parmName.replace('__c', '');
		// replace _ with nothing
		parmName = parmName.replace('_', '');

		return parmName;
	}

	
	// 
	// By default, we'll use the variable name in the map
	// but when we are processing an array, we can override the
	// variable name to handle the interim variable used in the
	// forEach loop
	//
	private String buildFunctionCall(String variableOverride)
	{
		if (this.functionParameters == null || this.functionParameters == '')
			return '()';

		String[] parameters = this.functionParameters.split(';');
		String parms = '(';
		String comma = '';
		for(String p : parameters)
		{			
			String variableName = variableMap.get(p);
			System.debug('For parameter name ' + p + ' the variable name is '+variableName);
			if (variableOverride != null)
				variableName = variableOverride;

			parms = parms + comma + variableName;
			comma = ', ';		
		}

		parms = parms + ')';

		return parms;		
	}	
	private static String buildClassDefinition(String className)
	{
		return 'function ' + className + ' ()\n{';
	}

	private static String buildFieldDefinition(String fieldName)
	{
		return '   this.'+fieldName+' = null;';
	}

	private static String buildFieldDefinitionWithValue(String fieldName, Schema.SOAPType fieldType, 
		Object value, Boolean escapeStringValue)
	{
		return '   this.'+fieldName+' = ' + buildFieldValue(fieldType, value, escapeStringValue) + ';';
	}

	private static String buildFieldDefinititonWithParameter(String fieldName, String paramName, 
		String jsonFieldName)
	{
		if (fieldName == jsonFieldName)
		{
			return '   this.'+fieldName+' =  JSON.parse( ' + paramName + ' );';
		}
		return '   this.'+fieldName+' = ' + paramName + ';';
	}

	private static String buildFieldValue(Schema.SOAPType fieldType, Object value, Boolean escapeStringValue)
	{
		if (value == null)
		{
			return 'null';
		}

		System.debug(Logginglevel.INFO, '*** TRACE: FieldType: ' + fieldType + ' value: ' + 
			value + ' escape? ' + escapeStringValue); 

		if (fieldType == Schema.SOAPType.Boolean || 
			fieldType == Schema.SOAPType.Integer || 
			fieldType == Schema.SOAPType.Double)
		{
			return String.valueOf(value);
		}

		if (fieldType == Schema.SOAPType.String || fieldType == Schema.SOAPType.ID)
		{			
			String aString = String.valueOf(value);
			if (escapeStringValue)
				aString = aString.replace('"','\\"');

			return '"' + aString + '"';
		}

		if (fieldType == Schema.SOAPType.Date)
		{
			Date theDate = Date.valueOf(value);
			return 'new Date(' + theDate.year() + ', ' + theDate.month() + ', ' + 
				theDate.day() +  ', 0, 0, 0, 0 )';
		}

		if (fieldType == Schema.SOAPType.DateTime)
		{
			Datetime theDate = Datetime.valueOf(value);
			return 'new Date(' + theDate.year() + ', ' + theDate.month() + ', ' + theDate.day() +  ', ' + 
									theDate.hour() + ', ' + theDate.minute() +', ' + theDate.second() + ', ' + 
									theDate.millisecond() + ' )';
		}

		if (fieldType == Schema.SOAPType.Time)
		{
			return ' null // Time type not currently supported';
		}

		return 'null // unknown type not supported: ' + fieldType ;

	}

	private String defineSobjectWithParams(SObject anObject)
	{
		Schema.SObjectType sobjType = anObject.getSObjectType();
		System.debug('Working with sObjecType of: '+sobjType);

		Schema.DescribeSObjectResult sobjResult = sobjType.getDescribe();

		sObjectName = sobjResult.getName();

		String javascriptClass = buildOpeningClassDefinition(sobjResult.getName());	

		// get a map of fields
		Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
		sortedFieldNames = new List<String>();
		sortedFieldNames.addAll(fieldMap.keySet());
		sortedFieldNames.sort();

		Map<String, FieldInfo> tempFieldMap = buildInternalFieldMap(fieldMap);
		internalFieldMap = tempFieldMap.clone();

		String comma = '';
		for(String name : sortedFieldNames)
		{
			FieldInfo fieldInfo = internalFieldMap.get(name);			
			if (fieldInfo != null)
			{			
				javascriptClass = javascriptClass + comma + fieldInfo.paramName;
				comma = ', ';
			} 
		}

		javascriptClass = javascriptClass + buildClosingClassDefinition();

		for(String name : sortedFieldNames)
		{
			FieldInfo fieldInfo = internalFieldMap.get(name);
			if (fieldInfo != null)
			{				
				System.debug('FieldName: '+ fieldInfo.fieldName + ' Type: ' + 
					fieldInfo.fieldType + ' ParamName: '+fieldInfo.paramName);

	   			javascriptClass = javascriptClass + buildFieldDefinititonWithParameter(
	   				fieldInfo.fieldName, fieldInfo.paramName, this.jsonFieldName ) + '\n';   		   			   			
			}
		}		

		javascriptClass = javascriptClass + buildClosingClassDefintion();

		System.debug('Final javascript class definition is \n'+javascriptClass);

		return javascriptClass;							
	}

	private static String makeFieldNameParameter(String fieldName)
	{
		return nameFunctionParameterFromSObject(fieldName);
	}

	private static String buildOpeningClassDefinition(String className)
	{
		return 'function ' + className + ' (';
	}

	private static String buildClosingClassDefinition()
	{
		return ' )\n{\n';
	}

	private String buildDataDeclaration(SObject record)
	{
		String jsonFieldLowerCase = null;
		if (this.jsonFieldName != null)
			jsonFieldLowerCase = this.jsonFieldName.toLowerCase();

		String paramValues = '( ';
		String comma = '';
		for(String field : sortedFieldNames)
		{
			FieldInfo fi = internalFieldMap.get(field);
			if (fi != null && !fi.isCalculated) 
			{				
				Object value = record.get(field);
				String fieldLowerCase = field.toLowerCase();
				Boolean escapeStringValue = (fieldLowerCase == jsonFieldLowerCase);
				paramValues = paramValues + comma + buildFieldValue(fi.fieldType, value, escapeStringValue);
				comma = ', ';
			}
		}
		paramValues = paramValues + '); ';

		return paramValues;
	}

	private static String buildClosingClassDefintion()
	{
		return '}\n';
	}


	private static Map<String, FieldInfo> buildInternalFieldMap(Map<String, 
		Schema.SObjectField> fieldMap)
	{
		Map<String, FieldInfo> internalFieldMap = new Map<String, FieldInfo>();
		for(String field : fieldMap.keySet())
		{
			Schema.DescribeFieldResult fieldResult = fieldMap.get(field).getDescribe();
			// we are only concerned with custom fields
			if (fieldResult.isCustom())
			{
				FieldInfo fi = new FieldInfo();
				fi.fieldName = fieldResult.getName();
				fi.paramName = makeFieldNameParameter(field);
				fi.fieldType = fieldResult.getSOAPType();
				fi.isCalculated = fieldResult.isCalculated();				

				internalFieldMap.put(field, fi);
			}
		}

		return internalFieldMap;		
	}

	public class FieldInfo
	{
		public String fieldName;
		public String paramName;
		public Schema.SOAPType fieldType;
		public Boolean isCalculated;

	}
}