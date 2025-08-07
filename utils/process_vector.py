from langchain.embeddings import OpenAIEmbeddings
import psycopg2
import os
import re
import logging
from typing import List, Dict, Any
import json
from langchain.schema.document import Document
from contextlib import contextmanager

BATCH_SIZE = 100  # Process embeddings in batches
MAX_RETRIES = 3

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class VectorEmbeddingsProcessor:
    def __init__(self, connection_string: str, table_name, embedding_model: str = "text-embedding-3-small"):
        self.connection_string = connection_string
        self.embeddings = OpenAIEmbeddings(model=embedding_model)
        self.table_name = table_name

    @contextmanager
    def get_db_connection(self):
        """Context manager for database connections with proper cleanup"""
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            yield conn
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Database connection error: {e}")
            raise
        finally:
            if conn:
                conn.close()

    def sanitize_filename(self, filename: str) -> str:
        """Sanitize filename for database storage"""
        base_name = os.path.basename(filename)
        return re.sub(r'[^a-zA-Z0-9_.-]', '_', base_name)

    def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for a batch of texts with retry logic"""
        for attempt in range(MAX_RETRIES):
            try:
                # Use embed_documents for batch processing (more efficient)
                return self.embeddings.embed_documents(texts)
            except Exception as e:
                logger.warning(f"Embedding generation attempt {attempt + 1} failed: {e}")
                if attempt == MAX_RETRIES - 1:
                    raise

    def prepare_batch_data(self, chunks: List[Document]) -> List[tuple]:
        """Prepare data for batch insertion"""
        batch_data = []

        for chunk in chunks:
            file_name = self.sanitize_filename(chunk.metadata.get("source", "unknown"))
            content = chunk.page_content
            metadata_json = json.dumps(chunk.metadata)

            batch_data.append((file_name, content, metadata_json))

        return batch_data

    def create_table_if_not_exists(self, cursor):
        """Create the embeddings table if it doesn't exist"""
        create_table_query = f"""
        CREATE TABLE IF NOT EXISTS {self.table_name} (
            id SERIAL PRIMARY KEY,
            file_name VARCHAR(255) NOT NULL,
            chunk TEXT NOT NULL,
            embedding vector(1536),  -- Adjust dimension based on your model
            metadata JSONB,
            UNIQUE(file_name, chunk)  -- Prevent duplicates
        );

        -- Create indexes for better query performance
        CREATE INDEX IF NOT EXISTS idx_document_embeddings_file_name 
            ON public.t_document_embeddings(file_name);
        CREATE INDEX IF NOT EXISTS idx_document_embeddings_embedding 
            ON public.t_document_embeddings USING ivfflat (embedding vector_cosine_ops);
        """
        cursor.execute(create_table_query)

    def insert_embeddings_batch(self, cursor, batch_data: List[tuple], embeddings: List[List[float]]):
        """Insert embeddings in batch with upsert logic"""
        insert_query = f"""
        INSERT INTO {self.table_name} (file_name, chunk, embedding, metadata)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (file_name, chunk) 
        DO UPDATE SET 
            embedding = EXCLUDED.embedding,
            metadata = EXCLUDED.metadata
        """

        # Combine batch data with embeddings
        full_batch_data = [
            (file_name, chunk, embedding, metadata)
            for (file_name, chunk, metadata), embedding in zip(batch_data, embeddings)
        ]

        # Use executemany instead of execute_batch for better compatibility
        cursor.executemany(insert_query, full_batch_data)

    def process_documents(self, all_chunks: List[Document]) -> None:
        """Main method to process documents and store embeddings"""
        if not all_chunks:
            logger.warning("No chunks provided for processing")
            return

        logger.info(f"Processing {len(all_chunks)} document chunks")

        with self.get_db_connection() as conn:
            cursor = conn.cursor()

            # Create table and indexes if they don't exist
            self.create_table_if_not_exists(cursor)
            conn.commit()

            # Process in batches
            for i in range(0, len(all_chunks), BATCH_SIZE):
                batch_chunks = all_chunks[i:i + BATCH_SIZE]
                logger.info(
                    f"Processing batch {i // BATCH_SIZE + 1}/{(len(all_chunks) + BATCH_SIZE - 1) // BATCH_SIZE}")

                try:
                    # Extract text content for embedding generation
                    texts = [chunk.page_content for chunk in batch_chunks]

                    # Generate embeddings for the batch
                    batch_embeddings = self.generate_embeddings_batch(texts)

                    # Prepare data for insertion
                    batch_data = self.prepare_batch_data(batch_chunks)

                    # Insert batch into database
                    self.insert_embeddings_batch(cursor, batch_data, batch_embeddings)
                    conn.commit()

                    logger.info(f"Successfully processed batch {i // BATCH_SIZE + 1}")

                except Exception as e:
                    logger.error(f"Error processing batch {i // BATCH_SIZE + 1}: {e}")
                    conn.rollback()
                    raise

        logger.info("All document chunks processed successfully")