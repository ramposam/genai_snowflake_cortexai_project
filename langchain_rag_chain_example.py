from langchain.document_loaders import PyPDFLoader

from langchain.text_splitter import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import ChatOpenAI
import os
import psycopg2
import logging
from langchain_core.prompts import ChatPromptTemplate
from operator import itemgetter
from langchain_core.output_parsers import StrOutputParser

from utils.process_vector import VectorEmbeddingsProcessor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
CONNECTION_STRING = "postgresql+psycopg2://vector:vector@localhost:5432/vector_db"

def load_file(file_name, current_dir=True):
    if current_dir:
        dir_path = os.path.dirname(os.getcwd())
        file_path = os.path.join(dir_path, file_name)
    else:
        file_path = file_name

    loader = PyPDFLoader(file_path)
    documents = loader.load()
    return documents


def get_chunks(documents):
    # Define markdown headers to split on
    headers_to_split_on = [
        ("#", "Header 1"),
        ("##", "Header 2"),
        ("###", "Header 3"),
        ("####", "Header 4"),
    ]

    separators = [" \n \n \n ", " \n \n ", " \n ", ".  \n", ". \n", ". "]

    # Initialize markdown splitter
    markdown_splitter = MarkdownHeaderTextSplitter(
        headers_to_split_on=headers_to_split_on,
        strip_headers=False
    )

    # Initialize recursive character splitter as backup
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        length_function=len,
        separators=separators
    )

    all_chunks = []

    for doc in documents:
        try:
            # Try markdown splitting first
            md_chunks = markdown_splitter.split_text(doc.page_content)
            if md_chunks:
                # Convert to Document objects
                for chunk in md_chunks:
                    chunk.metadata = doc.metadata
                    chunks = text_splitter.split_documents([chunk])
                    all_chunks.extend(chunks)
            else:
                # Fallback to recursive character splitting
                chunks = text_splitter.split_documents([doc])
                all_chunks.extend(chunks)

        except Exception as e:
            print(f"⚠️ Markdown splitting failed for a document: {e}")
            # Fallback to recursive character splitting
            chunks = text_splitter.split_documents([doc])
            all_chunks.extend(chunks)
    return all_chunks


# Usage example
def process_vector_embeddings(connection_string, table_name, chunks):
    # Initialize the processor
    processor = VectorEmbeddingsProcessor(connection_string, table_name)

    try:
        processor.process_documents(chunks)
        print("Embeddings processing completed successfully!")

    except Exception as e:
        logger.error(f"Failed to process embeddings: {e}")
        raise


def retrieve_context(table_name, file_name, connection_string, question, top_k):
    # Correct DSN
    # OpenAI Embeddings
    embedding_function = OpenAIEmbeddings(model="text-embedding-3-small")
    embedding = embedding_function.embed_query(question)

    query = f"""SELECT chunk, embedding <-> '{embedding}' AS distance --<#> for inner product, and <-> for cosine distance
    FROM {table_name}
    where file_name = '{file_name}'
    ORDER BY distance
    LIMIT {top_k};"""

    conn = psycopg2.connect(connection_string)
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchall()
    context = "\n".join([row[0] for row in result])
    return context


question = "when was the stampede happen?"

CONNECTION_STRING = "host=localhost port=5432 dbname=vector_db user=vector password=vector"
table_name = "public.t_document_embeddings"
file_name = "Report-on-Maha-Kumbh-Mela-Final-1.pdf"

prompt = ChatPromptTemplate.from_messages([("system", """You are a helpful assistant that answers questions based on the context provided. 
    Use only the given context to answer. If the context does not contain the answer, 
    say "I don't know" and do not make up an answer.

Instructions:
- Provide a comprehensive answer based on the context
- If relevant, mention which website(s) the information comes from
- Be specific and cite details from the context
- If the context doesn't contain enough information, clearly state what's missing

"""),
                                           ("human", 'Context: {context}'),
                                           ("human", "Question: {question}")])


llm = ChatOpenAI(model="gpt-4o-mini",max_tokens=100)

context = retrieve_context(table_name, file_name, CONNECTION_STRING, question, 3)

rag_chain = ({"context": itemgetter("context"),
              "question": itemgetter("question")} | prompt | llm | StrOutputParser())

llm_response = rag_chain.invoke({"question": question, "context": context})
