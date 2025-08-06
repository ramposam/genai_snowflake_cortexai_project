# LangChain PDF RAG System
# Requirements: pip install langchain langchain-community pypdf faiss-cpu sentence-transformers langchain-huggingface transformers torch

import os
import warnings
from typing import List, Dict, Any
from pathlib import Path

# LangChain imports
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import FAISS
from langchain.schema import Document
from langchain.prompts import PromptTemplate
from langchain.llms import HuggingFacePipeline
from langchain.chains import RetrievalQA

# Transformers imports
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import torch

# Suppress warnings
warnings.filterwarnings("ignore")


class LangChainPDFRAG:
    def __init__(self,
                 embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2",
                 llm_model: str = "microsoft/DialoGPT-medium",
                 vector_store_path: str = "./vector_store"):
        """
        Initialize LangChain PDF RAG system

        Args:
            embedding_model: Hugging Face embedding model
            llm_model: Hugging Face language model
            vector_store_path: Local path to store vector database
        """
        self.vector_store_path = Path(vector_store_path)
        self.vector_store_path.mkdir(exist_ok=True)

        print("🔄 Initializing embeddings...")
        self.embeddings = HuggingFaceEmbeddings(
            model_name=embedding_model,
            model_kwargs={'device': 'cuda' if torch.cuda.is_available() else 'cpu'}
        )

        print("🔄 Loading language model...")
        self.llm = self._setup_llm(llm_model)

        self.vectorstore = None
        self.qa_chain = None

    def _setup_llm(self, model_name: str):
        """Setup Hugging Face LLM pipeline"""
        try:
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModelForCausalLM.from_pretrained(
                model_name,
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                device_map="auto" if torch.cuda.is_available() else None
            )

            # Create pipeline
            pipe = pipeline(
                "text-generation",
                model=model,
                tokenizer=tokenizer,
                max_new_tokens=200,
                temperature=0.3,
                do_sample=True,
                device=0 if torch.cuda.is_available() else -1
            )

            return HuggingFacePipeline(pipeline=pipe)

        except Exception as e:
            print(f"⚠️ Error loading {model_name}: {e}")
            print("🔄 Falling back to a simpler model...")
            # Fallback to a smaller model
            return self._setup_simple_llm()

    def _setup_simple_llm(self):
        """Setup a simple text generation model as fallback"""
        try:
            pipe = pipeline(
                "text-generation",
                model="gpt2",
                max_new_tokens=150,
                temperature=0.7,
                do_sample=True,
                pad_token_id=50256
            )
            return HuggingFacePipeline(pipeline=pipe)
        except Exception as e:
            print(f"❌ Error setting up fallback model: {e}")
            raise

    def load_pdf(self, pdf_path: str) -> List[Document]:
        """
        Load PDF using LangChain PyPDFLoader

        Args:
            pdf_path: Path to PDF file

        Returns:
            List of Document objects
        """
        print(f"📖 Loading PDF: {pdf_path}")

        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")

        loader = PyPDFLoader(pdf_path)
        documents = loader.load()

        print(f"✅ Loaded {len(documents)} pages from PDF")
        return documents

    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        Split documents using Markdown and Recursive Character Text Splitters

        Args:
            documents: List of Document objects

        Returns:
            List of split Document chunks
        """
        print("✂️ Splitting documents into chunks...")

        # Define markdown headers to split on
        headers_to_split_on = [
            ("#", "Header 1"),
            ("##", "Header 2"),
            ("###", "Header 3"),
            ("####", "Header 4"),
        ]

        separators = [" \n \n \n ", " \n \n ", " \n "]

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
                        chunk_doc = Document(
                            page_content=chunk.page_content,
                            metadata={**doc.metadata, **chunk.metadata}
                        )
                        all_chunks.append(chunk_doc)
                else:
                    # Fallback to recursive character splitting
                    chunks = text_splitter.split_documents([doc])
                    all_chunks.extend(chunks)

            except Exception as e:
                print(f"⚠️ Markdown splitting failed for a document: {e}")
                # Fallback to recursive character splitting
                chunks = text_splitter.split_documents([doc])
                all_chunks.extend(chunks)

        print(f"✅ Created {len(all_chunks)} chunks")
        return all_chunks

    def create_vector_store(self, chunks: List[Document], save_local: bool = True):
        """
        Create FAISS vector store from document chunks

        Args:
            chunks: List of Document chunks
            save_local: Whether to save vector store locally
        """
        print("🔮 Creating vector embeddings...")

        # Create FAISS vector store
        self.vectorstore = FAISS.from_documents(
            documents=chunks,
            embedding=self.embeddings
        )

        if save_local:
            # Save vector store locally
            save_path = str(self.vector_store_path / "faiss_index")
            self.vectorstore.save_local(save_path)
            print(f"💾 Vector store saved to: {save_path}")

        print("✅ Vector store created successfully")

    def load_vector_store(self):
        """Load existing vector store from local storage"""
        save_path = str(self.vector_store_path / "faiss_index")

        if os.path.exists(save_path):
            print("📂 Loading existing vector store...")
            self.vectorstore = FAISS.load_local(
                save_path,
                self.embeddings,
                allow_dangerous_deserialization=True
            )
            print("✅ Vector store loaded successfully")
            return True
        else:
            print(f"❌ No existing vector store found at {save_path}")
            return False

    def setup_qa_chain(self):
        """Setup RetrievalQA chain"""
        if not self.vectorstore:
            raise ValueError("Vector store not created. Please create or load vector store first.")

        print("🔗 Setting up QA chain...")

        # Create custom prompt template
        prompt_template = """Use the following pieces of context to answer the question at the end. 
        If you don't know the answer, just say that you don't know, don't try to make up an answer.

        Context: {context}

        Question: {question}

        Answer: """

        PROMPT = PromptTemplate(
            template=prompt_template,
            input_variables=["context", "question"]
        )

        # Create retrieval QA chain
        self.qa_chain = RetrievalQA.from_chain_type(
            llm=self.llm,
            chain_type="stuff",
            retriever=self.vectorstore.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 3}
            ),
            chain_type_kwargs={"prompt": PROMPT},
            return_source_documents=True
        )
        print(f"Prompt: {PROMPT}")
        print("✅ QA chain setup complete")

    def query(self, question: str) -> Dict[str, Any]:
        """
        Query the RAG system

        Args:
            question: User question

        Returns:
            Dictionary with answer and source documents
        """
        if not self.qa_chain:
            raise ValueError("QA chain not setup. Please run setup_qa_chain() first.")

        print(f"🤔 Processing question: {question}")

        try:
            result = self.qa_chain({"query": question})
            print(result)
            return {
                "question": question,
                "answer": result["result"],
                "source_documents": result["source_documents"]
            }
        except Exception as e:
            return {
                "question": question,
                "answer": f"Error processing question: {str(e)}",
                "source_documents": []
            }

    def process_pdf_pipeline(self, pdf_path: str, force_recreate: bool = False):
        """
        Complete pipeline to process PDF and setup RAG system

        Args:
            pdf_path: Path to PDF file
            force_recreate: Force recreation of vector store
        """
        print("🚀 Starting PDF processing pipeline...")

        # Try to load existing vector store
        if not force_recreate and self.load_vector_store():
            print("📋 Using existing vector store")
        else:
            # Load and process PDF
            documents = self.load_pdf(pdf_path)
            chunks = self.split_documents(documents)
            self.create_vector_store(chunks)

        # Setup QA chain
        self.setup_qa_chain()

        print("🎉 Pipeline complete! Ready for queries.")

    def interactive_chat(self):
        """Interactive chat interface"""
        print("\n" + "=" * 50)
        print("🤖 LangChain PDF RAG Chat Interface")
        print("=" * 50)
        print("Type 'quit', 'exit', or 'q' to end the conversation")
        print("Type 'sources' after a question to see source documents")
        print("-" * 50)

        while True:
            question = input("\n💬 Your question: ").strip()

            if question.lower() in ['quit', 'exit', 'q']:
                print("👋 Goodbye!")
                break

            if not question:
                continue

            result = self.query(question)

            print(f"\n🤖 Answer: {result['answer']}")

            if input("\n📚 Show sources? (y/n): ").lower().startswith('y'):
                print("\n📖 Source Documents:")
                for i, doc in enumerate(result['source_documents'], 1):
                    print(f"\n{i}. Page {doc.metadata.get('page', 'Unknown')}:")
                    print(f"   {doc.page_content[:200]}...")


# Example usage and main function
def main():
    """Main function demonstrating the RAG system"""
    print("🔧 Initializing LangChain PDF RAG System...")

    # Initialize RAG system
    rag_system = LangChainPDFRAG(
        embedding_model="sentence-transformers/all-MiniLM-L6-v2",
        llm_model="microsoft/DialoGPT-medium",  # You can change this to other models
        vector_store_path="./my_vector_store"
    )

    # PDF file path (change this to your PDF)
    pdf_path = input("📁 Enter PDF file path: ").strip()

    if not pdf_path or not os.path.exists(pdf_path):
        print("❌ Invalid PDF path. Using example...")
        pdf_path = os.path.join(os.getcwd(),"Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf")  # "sample_document.pdf"  # Fallback example

    try:
        # Process PDF and setup RAG
        rag_system.process_pdf_pipeline(pdf_path, force_recreate=False)

        # Start interactive chat
        rag_system.interactive_chat()

    except FileNotFoundError:
        print(f"❌ PDF file not found: {pdf_path}")
        print("Please provide a valid PDF file path.")
    except Exception as e:
        print(f"❌ Error: {e}")


# Standalone query function
def quick_query(pdf_path: str, question: str):
    """Quick query function for single questions"""
    rag_system = LangChainPDFRAG()
    rag_system.process_pdf_pipeline(pdf_path)
    result = rag_system.query(question)

    print(f"Question: {result['question']}")
    print(f"Answer: {result['answer']}")
    return result


if __name__ == "__main__":
    main()