import streamlit as st
import uuid
from pathlib import Path
import snowflake.connector
import os

st.title("Snowflake PDF Q&A with Cortex")

# --- Step 1: File Upload ---
file = st.file_uploader("Upload PDF File", type=["pdf"])

# --- Step 2: Model Selection ---
model = st.selectbox("Select LLM Model", ["mistral-7b", "snowflake-arctic", "llama2-70b"])

file_mode = st.selectbox("Choose Mode",["OCR","LAYOUT"])

# --- Step 3: Upload Button ---
upload_clicked = st.button("Upload and Process PDF")


db = os.getenv("SNOWFLAKE_DATABASE")
schema = os.getenv("SNOWFLAKE_SCHEMA")

# Temporary stage and table names
unique_id = uuid.uuid4().hex[:8]
stage_name = f"{db}.{schema}.STG_DOCUMENTS"
table_name = f"T_DOCUMENTS"
chunks_table = f"T_CHUNKS_{unique_id}"
embedding_table = f"{chunks_table}_EMBEDDINGS"


stg_create_sql = f"""CREATE STAGE  IF NOT EXISTS {stage_name}
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' ) ;"""

# Snowflake connection config
conn = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=db,
    schema=schema
)
cs = conn.cursor()

if upload_clicked and file:
    file_name = Path(file.name).name
    temp_file_path = f"/tmp/{file_name}"

    # Save the file locally
    with open(temp_file_path, "wb") as f:
        f.write(file.read())

    # Upload file to Snowflake stage using PUT command
    put_cmd = f"PUT file://{temp_file_path} @{stage_name} AUTO_COMPRESS=FALSE"
    st.code(put_cmd)
    cs.execute(put_cmd)

    # Parse Document
    parse_sql = f"""
    CREATE OR REPLACE TABLE {table_name} AS
    SELECT *
    FROM TABLE(SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
      '@{stage_name}',
      '{file_name}'
      [ { 'mode': {file_mode} } ]
    ))
    """
    st.code(parse_sql)
    cs.execute(parse_sql)
    st.code(f"Chunks tables")
    # Split into Chunks
    chunk_sql = f"""
    CREATE OR REPLACE TABLE {chunks_table} AS
    SELECT
      METADATA$FILENAME AS source,
      METADATA$PAGE_NUMBER AS page,
      SEQ4() AS chunk_id,
      TRIM(value) AS chunk_text
    FROM {table_name},
      LATERAL FLATTEN(input => SPLIT(DOCUMENT_CONTENT, '\n\n'))
    """
    st.code(chunk_sql)
    cs.execute(chunk_sql)

    # Embed Chunks
    embed_sql = f"""
    CREATE OR REPLACE TABLE {embedding_table} AS
    SELECT *,
      SNOWFLAKE.CORTEX.EMBED_TEXT('snowflake-arctic-embed', chunk_text) AS embedding
    FROM {chunks_table}
    """
    st.code(embed_sql)
    cs.execute(embed_sql)

    st.success("PDF uploaded, parsed, chunked, and embedded successfully.")

# --- Step 4: User Question Search ---
if upload_clicked:
    user_question = st.text_input("Ask a question about the PDF")
    search_clicked = st.button("Search")

    if search_clicked and user_question:
        # Embed Question
        cs.execute(f"SELECT SNOWFLAKE.CORTEX.EMBED_TEXT('snowflake-arctic-embed', %s)", (user_question,))
        question_embedding = cs.fetchone()[0]

        # Retrieve top matching chunk
        search_sql = f"""
        WITH question AS (
          SELECT PARSE_JSON('{question_embedding}') AS qvec
        ),
        scored_chunks AS (
          SELECT 
            c.chunk_id,
            c.chunk_text,
            VECTOR_COSINE_SIMILARITY(c.embedding, q.qvec) AS similarity
          FROM {embedding_table} c, question q
        )
        SELECT chunk_text
        FROM scored_chunks
        ORDER BY similarity DESC
        LIMIT 5
        """
        st.code(search_sql)
        cs.execute(search_sql)
        top_chunk = cs.fetchone()[0]

        # Prepare prompt
        final_prompt = f"Using the following context:\n\n{top_chunk}\n\nAnswer this: {user_question}"
        st.code(final_prompt)
        # Get response
        cs.execute("SELECT SNOWFLAKE.CORTEX.COMPLETE(%s, INPUT => %s)", (model, final_prompt))
        response = cs.fetchone()[0]

        st.subheader("Answer")
        st.write(response)

cs.close()
conn.close()