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
 
 CREATE  TABLE IF NOT EXISTS CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS_EMBEDDINGS (
                DOCUMENT_ID NUMBER(1,0),
                CHUNK_ID NUMBER(38,0),
                EMBEDDINGS VECTOR(FLOAT, 768),
                UPDATED_DATE TIMESTAMP_LTZ(9),
                UPDATED_BY VARCHAR(16777216)
            );
            
 
 DELETE FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS WHERE document_id = 2 ;
 
 DELETE FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS_EMBEDDINGS WHERE document_id = 2 ;
 
  INSERT INTO  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS 
                SELECT
                   2 document_id,index as chunk_id,
                   value::text as chunk_data, 
                   current_timestamp() as updated_date, current_user() as updated_by 
                 FROM (SELECT *  FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS WHERE document_id=2 ) ,
                   LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER (
                      file_content::text,
                      'markdown',
                      200,
                      20,
                      ['##']
                   )) c;
            
 
  INSERT INTO   CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS_EMBEDDINGS
        SELECT DOCUMENT_ID,CHUNK_ID,
          SNOWFLAKE.CORTEX.EMBED_TEXT_768('snowflake-arctic-embed-m-v1.5', CHUNK_DATA) AS embedding,
          current_timestamp() as updated_date, current_user() as updated_by
        FROM CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS
         WHERE  document_id = 2 ; 

 with question as
            (select SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'snowflake-arctic-embed-m-v1.5', 'how many of fatalities reported in accident?' ) as q_embeddings),
            doc_details as (select document_id from CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS
                where file_name = '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf'
                and file_mode = 'LAYOUT' order by document_id desc limit 1),
        vectors as (
            select chunk_data,
                VECTOR_COSINE_SIMILARITY(embeddings,question.q_embeddings) as similarity_range
            from doc_details d
            join CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS_EMBEDDINGS e on (d.document_id = e.document_id)
            join CORTEX_AI_DB.CORTEX_AI.T_DOCUMENT_CHUNKS c on (e.document_id=c.document_id and e.chunk_id = c.chunk_id)
            join question on (1=1)
            order by similarity_range desc limit 5)
        select listagg(chunk_data||chr(13)||chr(13),'
') as context from vectors ;

 with prompt_gen as (
            select '
    You are a documentation specialist focused on providing precise answers based on provided documentation.

            Input Context:
            Context:  ## 12. Accident Flight

Figure 1 Accident Site with respect to airport (left) and debris field

Government of India Ministry of Civil Aviation Aircraft Accident Investigation Bureau

Contents
|1. General Information ..||
| :---: | :---: |
|2. Background.||
|3. Injuries to persons||
|4. Aircraft Information .||
|5. Damages.|.6|
|6. Wreckage and Impact .||

3. Injuries to persons
|Injuries|Crew|Passengers|Others|
| :---: | :---: | :---: | :---: |
|Fatal|12|229|19|
|Serious|NIL|1|67|
|Minor/None|NIL|NIL||

4. Aircraft Information

            Question: how many of fatalities reported in accident?

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

            Response:
                    ' as prompt)
            select prompt,snowflake.cortex.complete(
                  'deepseek-r1',
                    [
                        {
                            'role': 'user',
                            'content': prompt
                        }
                    ],
                    {
                    'temperature': 0.7,
                    'max_tokens': 500
            })['choices'][0]['messages']::text as response
            from prompt_gen;