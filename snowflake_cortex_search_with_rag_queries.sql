create TABLE if not exists  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS (
	DOCUMENT_ID NUMBER(1,0),
	FILE_NAME VARCHAR(16777216),
	FILE_CONTENT TEXT,
	NO_OF_PAGES TEXT,
	FILE_MODE TEXT,
	UPDATED_DATE TIMESTAMP_LTZ(9),
	UPDATED_BY VARCHAR(16777216)
    );
    
 
 CREATE STAGE  IF NOT EXISTS CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' ) ;
 
 
 PUT 'file:///tmp/69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf' @CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS AUTO_COMPRESS=FALSE ;

  INSERT INTO  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS
        with tab as (
        SELECT '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf' as file_name,
            SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
            @CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS,
            '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf',
            {'mode': 'LAYOUT'} )  AS document_data)
            select 8  as document_id,
            file_name,document_data['content']::TEXT file_content,
            document_data['metadata']['pageCount']::TEXT no_of_pages,
            'LAYOUT' as file_mode,
            current_timestamp() as updated_date, current_user() as updated_by
            from tab  ;

 
 CREATE  TABLE IF NOT EXISTS CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS (
               DOCUMENT_ID NUMBER(1,0),
               CHUNK_ID NUMBER(38,0),
               CHUNK_DATA VARCHAR(16777216),
               UPDATED_DATE TIMESTAMP_LTZ(9),
               UPDATED_BY VARCHAR(16777216)
               );

 
 DELETE FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS WHERE document_id = 2 ;
 

  INSERT INTO  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS 
                SELECT
                   2 document_id,index as chunk_id,
                   value::text as chunk_data, 
                   current_timestamp() as updated_date, current_user() as updated_by 
                 FROM (SELECT *  FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS WHERE document_id=2 ) ,
                   LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER (
                      file_content::text,
                      'markdown',
                      500,
                      50,
                      ['##']
                   )) c;
            


CREATE OR REPLACE CORTEX SEARCH SERVICE DOCUMENT_SEARCH_SERVICE
  ON CHUNK_DATA
  ATTRIBUTES file_name
  WAREHOUSE = 'SNOWFLAKE_LEARNING_WH'
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  AS (
    SELECT
        CHUNK_DATA,
        file_name
    FROM T_DOCUMENT_CHUNKS dc
    join T_DOCUMENTs d on (dc.document_id=d.document_id)
);




with chunks_data as (SELECT
  parse_json(SNOWFLAKE.CORTEX.SEARCH_PREVIEW (
      'CORTEX_AI_DB.CORTEX_AI.DOCUMENT_SEARCH_SERVICE',
      '{
          "query": "list out parties which are contested in 2024 and no of seats that each party won?",
          "columns": ["CHUNK_DATA"],
          "limit": 5
      }'
  ))['results'] as chunks),
  chunks_text as (select index,value['CHUNK_DATA']::TEXT AS data_chunks from chunks_data,
  lateral flatten (input => chunks)),
  generated_prompt as (select ' You are a documentation specialist focused on providing precise answers based on provided documentation.

            Input Context:
            Context:  '||listagg(data_chunks,'\n') ||'

            Question: list out parties which are contested in 2024 and no of seats that each party won?

            Instructions:
            1. Analyze the provided context carefully
            2. Frame responses to build upon any relevant chat history
            3. Structure answers as follows:
               - Direct answer to the question
               - Required prerequisites or dependencies
               - Step-by-step implementation (if applicable)
               - Important limitations or warnings

            If information is not found in context:
            1. Explicitly state what information is missing
            2. Avoid assumptions or external references
            3. Specify what additional context would help answer the question

            Remember: Only reference information from the provided context.

            Response:            ' as prompt from chunks_text)
  select snowflake.cortex.complete('claude-4-sonnet',prompt) from generated_prompt;
