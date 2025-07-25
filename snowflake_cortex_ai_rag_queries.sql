LIST @STG_DOCUMENTS;

CREATE STAGE IF NOT EXISTS  GENAI_DB.PRACTISE.STG_DOCUMENTS
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );



create or replace table genai_db.practise.t_documents as
with tab as (
SELECT '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf' as file_name,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
    @STG_DOCUMENTS,
    '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf',
    {'mode': 'LAYOUT'} )  AS document_data)
select 1 as document_id,file_name,document_data['content']::text file_content, document_data['metadata']['pageCount'] no_of_pages, current_timestamp() as updated_date, current_user() as updated_by from tab  ;

select file_content::text from genai_db.practise.t_documents;

create or replace table genai_db.practise.t_document_chunks as
SELECT
   document_id,index as chunk_id,value::text as chunk_data, current_timestamp() as updated_date, current_user() as updated_by
FROM
   genai_db.practise.t_documents,
   LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER (
      file_content::text,
      'markdown',
      500,
      50
   )) c;

create or replace table genai_db.practise.t_document_chunks as
   SELECT
   document_id,index as chunk_id,value['chunk']::text as chunk_data,value['headers']::text as chunk_headers, current_timestamp() as updated_date, current_user() as updated_by
FROM
   genai_db.practise.t_documents,
   LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER (
      file_content::text,
      OBJECT_CONSTRUCT('#', 'header_1', '##', 'header_2'),
      500,
      50
   )) c;

   select * from genai_db.practise.t_document_chunks;

   create or replace table genai_db.practise.t_document_embeddings as
  select document_id,chunk_id,SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'snowflake-arctic-embed-m-v1.5', chunk_data ) embeddings
  , current_timestamp() as updated_date, current_user() as updated_by
  from genai_db.practise.t_document_chunks;

with question as (select SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'snowflake-arctic-embed-m-v1.5', 'how many of them died in accident?' ) as q_embeddings),
vectors as (
    select chunk_data,
    VECTOR_COSINE_SIMILARITY(embeddings,question.q_embeddings) as similarity_range
    from genai_db.practise.t_document_embeddings e join t_document_chunks c on (e.document_id=c.document_id and e.chunk_id = c.chunk_id)
    join question on (1=1) order by similarity_range desc limit 10)
select listagg(chunk_data||chr(13)||chr(13),'\n') as context from vectors ;

with prompt_gen as (select 'You are a documentation specialist focused on providing precise answers based on provided documentation.

            Input Context:
            Context: '||'aircraft started to lose altitude before crossing the airport perimeter wall.

premises for Rescue and firefighting. They were joined by Fire and Rescue services of Local Administration.

RAT in extended position

The Aircraft was destroyed due to impact with the buildings on the ground and subsequent fire. A total of five buildings shown in the figure below were impacted and suffered major structural and fire damages.
Figure 1 Accident Site with respect to airport (left) and debris field

|||Nationality|Indian|
|||Registration|VT-ANB|
|2.|Owner and|Operator|Air India|
|3.|Pilot||ATPL Holder|
||Extent of|Injuries|Fatal|
|4.|Co Pilot||CPL Holder|
||Extent of|Injuries|Fatal|
|5.|No. of Persons|on board|230 passengers, 10 Cabin Crew and 02 Flight Crew|
|6.|Date & Time|of Accident|12 June 2025, 0809 UTC (13:39 IST)|
|7.|Place of|Accident|Ahmedabad|
|8.|Co-ordinates|of Accident Site|"23°03''17.8""N 72°36''43.6""E""|

Contents
|1. General Information ..||
| :---: | :---: |
|2. Background.||
|3. Injuries to persons||
|4. Aircraft Information .||
|5. Damages.|.6|
|6. Wreckage and Impact .||
|7. Personnel Information .|.11|
|8. Meteorological Information:|.11|
|9. Aerodrome|.11|
|10. Communications ..|.12|
|11. Flight Recorders .|.12|
|12. Accident Flight .|.13|
|13. Progress of Investigation..|15|
1. General Information
|1.|Aircraft|Type|Boeing 787-8|
| :---: | :---: | :---: | :---: |
|||Nationality|Indian|

to the right engine resting position, at heading of approx. 326 degrees. The wall was pushed into the column was damaged such that portions of the concrete

taken on board as Subject Matter Experts (SMEs) to assist the Investigation in the area of their domain expertise.

This document has been prepared based on the preliminary facts and evidence collected during the investigation. The information is preliminary and subject to changeIn accordance with Annex 13 to the Convention on International Civil Aviation Organization (ICAO) and Rule 3 of Aircraft (Investigation of Accidents and Incidents), Rules 2017, the sole objective of the investigation of an Accident/Incident shall be the prevention of accidents and incidents and not to apportion blame or liability. The

* >The statement of the witnesses and the surviving passenger have been obtained by the Investigators.
* Complete analysis of postmortem reports of the crew and the passengers is being undertaken to corroborate aeromedical findings with the engineering appreciation.
* Additional details are being gathered based on the initial leads
* At this stage of investigation, there are no recommended actions to B787-8 and/or GE GEnx-1B engine operators and manufacturers.
'||'Question: how many of them died in accident?

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

            Response:' as prompt)
select snowflake.cortex.complete(
  'openai-gpt-4.1',
    [
        {
            'role': 'user',
            'content': prompt
        }
    ],
    {
        'temperature': 0.7,
        'max_tokens': 100
    })['choices'][0]['messages']::text
    from prompt_gen;


