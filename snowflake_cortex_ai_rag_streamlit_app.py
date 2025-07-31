import streamlit as st
import uuid
from pathlib import Path
import snowflake.connector
import os

from utils.db_connection import SnowflakeSingleton

if "form_data" not in st.session_state:
    st.session_state.form_data = {}



st.title("Snowflake PDF Q&A with Cortex")

# --- Step 1: File Upload ---
st.session_state.form_data["file"] = st.file_uploader("Upload PDF File", type=["pdf"])

# --- Step 2: Model Selection ---
st.session_state.form_data["model"] = st.selectbox("Select LLM Model", ["claude-3-5-sonnet",
                                          "llama3-8b",
                                          "deepseek-r1",
                                          "mistral-7b",
                                          "openai-o4-mini"])

st.session_state.form_data["file_mode"] = st.selectbox("Choose Mode",["OCR","LAYOUT"])

st.session_state.form_data["split_type"] = st.selectbox("Split chunks by Type",["Text","Markdown"])

st.session_state.form_data["chunk_size"] = st.number_input("Size of each chunk",max_value=1500,min_value=200,step=100)
st.session_state.form_data["overlap"] = st.number_input("Overlap",max_value=150,min_value=20,step=10)

st.session_state.form_data["reprocess_file"] = st.checkbox("Would you like to re-process file?",value=False)
st.session_state.form_data["embedding_model"] = st.selectbox("Vector Search Function",["e5-base-v2" , "snowflake-arctic-embed-m" , "snowflake-arctic-embed-m-v1.5"])

st.session_state.form_data["vector_search_type"] = st.selectbox("Vector Search Function",["VECTOR_INNER_PRODUCT" , "VECTOR_L1_DISTANCE" , "VECTOR_L2_DISTANCE" , "VECTOR_COSINE_SIMILARITY"])
st.session_state.form_data["no_of_chunks"] = st.number_input("No of chunks Use for Context",max_value=10,min_value=3)


# --- Step 3: Upload Button ---
st.session_state.form_data["upload_clicked"] = st.button("Upload and Process PDF")

st.markdown("***")


db = os.getenv("SNOWFLAKE_DATABASE")
schema = os.getenv("SNOWFLAKE_SCHEMA")

# Temporary stage and table names
stage_name = f"{db}.{schema}.STG_DOCUMENTS"
document_table = f"T_DOCUMENTS"
chunks_table = f"T_DOCUMENT_CHUNKS"
embedding_table = f"{chunks_table}_EMBEDDINGS"

table_ddl = f"""create TABLE if not exists  {db}.{schema}.{document_table} (
	DOCUMENT_ID NUMBER(1,0),
	FILE_NAME VARCHAR(16777216),
	FILE_CONTENT TEXT,
	NO_OF_PAGES TEXT,
	FILE_MODE TEXT,
	UPDATED_DATE TIMESTAMP_LTZ(9),
	UPDATED_BY VARCHAR(16777216)
    );
    """

# Enable server side encryption, this is mandatory if we want to read document files from stage using parse_documents
stg_create_sql = f"""CREATE STAGE  IF NOT EXISTS {stage_name}
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' ) ;"""

db_conn_obj = SnowflakeSingleton()
conn = db_conn_obj.connect(
                account=os.getenv("SNOWFLAKE_ACCOUNT"),
                user=os.getenv("SNOWFLAKE_USER"),
                password=os.getenv("SNOWFLAKE_PASSWORD"),
                warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
                role=os.getenv("SNOWFLAKE_ROLE"),
                database=db,
                schema=schema
            )

cs = conn.cursor()

form_data = st.session_state.form_data
if form_data["upload_clicked"] and form_data["file"] :
    file_name = Path(form_data["file"].name).name

    st.code(table_ddl)
    cs.execute(table_ddl)

    st.code(stg_create_sql)
    cs.execute(stg_create_sql)

    file_doc_id =  cs.execute(f"""SELECT max(DOCUMENT_ID) FROM {db}.{schema}.{document_table} 
            where file_name = '{file_name}'
            and file_mode = '{form_data["file_mode"]}' """).fetchall()[0][0]

    # Check if  the file not already been processed
    # Check if it needs to re-process file

    if  not file_doc_id:
        temp_file_path = f'/tmp/{file_name}'


        # Save the file locally
        with open(temp_file_path, "wb") as f:
            f.write(form_data["file"].read())


        # Upload file to Snowflake stage using PUT command
        put_cmd = f"""PUT 'file://{temp_file_path}' @{stage_name} AUTO_COMPRESS=FALSE ;"""
        st.code(put_cmd)
        cs.execute(put_cmd)


        document_id = cs.execute(f"SELECT coalesce(MAX(DOCUMENT_ID),0)+1 FROM {db}.{schema}.{document_table}").fetchone()[0]

        # Parse Document
        parse_sql = f""" INSERT INTO  {db}.{schema}.{document_table}
        with tab as (  
        SELECT '{file_name}' as file_name,
            SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
            @{stage_name},
            '{file_name}',
            {{'mode': '{form_data["file_mode"]}'}} )  AS document_data)
            select {document_id}  as document_id,
            file_name,document_data['content']::TEXT file_content, 
            document_data['metadata']['pageCount']::TEXT no_of_pages, 
            '{form_data["file_mode"]}' as file_mode,
            current_timestamp() as updated_date, current_user() as updated_by 
            from tab  ;
            """
        st.code(parse_sql)
        cs.execute(parse_sql)

    else:
        document_id = file_doc_id
        put_cmd = ""
        parse_sql = ""


    if form_data["reprocess_file"] or  int(document_id)>0:

        chunks_table_ddl = f"""CREATE  TABLE IF NOT EXISTS {db}.{schema}.{chunks_table} (
               DOCUMENT_ID NUMBER(1,0),
               CHUNK_ID NUMBER(38,0),
               CHUNK_DATA VARCHAR(16777216),
               UPDATED_DATE TIMESTAMP_LTZ(9),
               UPDATED_BY VARCHAR(16777216)
               );"""

        st.code(chunks_table_ddl)
        cs.execute(chunks_table_ddl)

        embedding_table_ddl = f"""CREATE  TABLE IF NOT EXISTS {db}.{schema}.{embedding_table} (
                DOCUMENT_ID NUMBER(1,0),
                CHUNK_ID NUMBER(38,0),
                EMBEDDINGS VECTOR(FLOAT, 768),
                UPDATED_DATE TIMESTAMP_LTZ(9),
                UPDATED_BY VARCHAR(16777216)
            );
            """
        st.code(embedding_table_ddl)
        cs.execute(embedding_table_ddl)

        delete_sqls = [f"DELETE FROM {db}.{schema}.{chunks_table} WHERE document_id = {document_id} ;",
                       f"DELETE FROM {db}.{schema}.{embedding_table} WHERE document_id = {document_id} ;"]

        for query in delete_sqls:
            st.code(query)
            cs.execute(query)


        if form_data["split_type"] == "Text":
            # Split into Chunks
            chunk_sql = f""" INSERT INTO  {db}.{schema}.{chunks_table} 
                SELECT
                   {document_id} document_id,index as chunk_id,
                   value::text as chunk_data, 
                   current_timestamp() as updated_date, current_user() as updated_by 
                 FROM (SELECT *  FROM {db}.{schema}.{document_table} WHERE document_id={document_id} ) ,
                   LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER (
                      file_content::text,
                      'markdown',
                      {form_data["chunk_size"]},
                      {form_data["overlap"]},
                      ['##']
                   )) c;
            """
        else:
            chunk_sql = f""" INSERT INTO  {db}.{schema}.{chunks_table}
            SELECT
                {document_id} document_id,index as chunk_id,
                   value::text as chunk_data, 
                   current_timestamp() as updated_date, current_user() as updated_by  
            FROM (SELECT *  FROM {db}.{schema}.{document_table} WHERE document_id={document_id} ) ,
               LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER (
                  file_content::text,
                  OBJECT_CONSTRUCT('#', 'header_1', '##', 'header_2','###', 'header_3'),
                  {form_data["chunk_size"]},
                  {form_data["overlap"]},
               )) c;
            """
        st.code(chunk_sql)
        cs.execute(chunk_sql)


        # Embed Chunks
        embed_sql = f""" INSERT INTO   {db}.{schema}.{embedding_table}
        SELECT DOCUMENT_ID,CHUNK_ID,
          SNOWFLAKE.CORTEX.EMBED_TEXT_768('{form_data["embedding_model"]}', CHUNK_DATA) AS embedding,
          current_timestamp() as updated_date, current_user() as updated_by
        FROM {db}.{schema}.{chunks_table}
         WHERE  document_id = {document_id} ; 
        """
        st.code(embed_sql)
        cs.execute(embed_sql)
        st.subheader("All Generated SQLs")
        st.code("\n \n ".join([table_ddl,stg_create_sql,put_cmd, parse_sql, chunks_table_ddl, embedding_table_ddl, delete_sqls[0],delete_sqls[1],chunk_sql,embed_sql]))
        st.success("PDF uploaded, parsed, chunked, and embedded successfully.")
    else:
        st.error(f"File already been processed with document id:{file_doc_id}")


# --- Step 4: User Question Search ---
if  form_data["file"]:

    file_name = Path(form_data["file"].name).name

    user_question = st.text_input("Ask a question about the PDF")

    search_clicked = st.button("Search")

    if search_clicked and user_question:
        with st.spinner("Please wait .. Fetching Matched Context and Generating Answer for you."):
            context_select = "listagg(PARSE_JSON (chunk_data)['chunk']||chr(13)||chr(13),'\n')" if form_data["split_type"] == "Markdown" else "listagg(chunk_data||chr(13)||chr(13),'\n')"
            # Embed Question
            rag_query = f""" with question as 
                (select SNOWFLAKE.CORTEX.EMBED_TEXT_768( '{form_data["embedding_model"]}', '{user_question}' ) as q_embeddings),
                doc_details as (select document_id from {db}.{schema}.{document_table} 
                    where file_name = '{file_name}' 
                    and file_mode = '{form_data["file_mode"]}' order by document_id desc limit 1),
            vectors as (
                select chunk_data,
                    {st.session_state.form_data["vector_search_type"]}(embeddings,question.q_embeddings) as similarity_range  
                from doc_details d
                join {db}.{schema}.{embedding_table} e on (d.document_id = e.document_id)
                join {db}.{schema}.{chunks_table} c on (e.document_id=c.document_id and e.chunk_id = c.chunk_id)
                join question on (1=1) 
                order by similarity_range desc limit {form_data["no_of_chunks"]})
            select {context_select} as context from vectors ;  
            """
            st.subheader("Actual Prompt")
            st.code(rag_query)
            cs.execute(rag_query)
            rag_context = cs.fetchone()[0]
            # Prepare prompt
            final_prompt = f""" with prompt_gen as (
                select '
        You are a documentation specialist focused on providing precise answers based on provided documentation. 
        
                Input Context:
                Context:  {rag_context}
                Question: {user_question}
        
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
                      '{form_data["model"]}',
                        [
                            {{
                                'role': 'user',
                                'content': prompt
                            }}
                        ],
                        {{
                        'temperature': 0.7,
                        'max_tokens': 500
                }})['choices'][0]['messages']::text as response
                from prompt_gen; 
    """
            st.subheader("Prompt Query")
            st.code(final_prompt)
            # Get response
            cs.execute(final_prompt)
            result = cs.fetchall()
            prompt = result[0][0]
            response = result[0][1]

            st.subheader("Actual Prompt")
            st.code(prompt)

            st.subheader("Response/Answer")
            st.code(response)
