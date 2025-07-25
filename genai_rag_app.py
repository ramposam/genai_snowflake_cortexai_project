import streamlit as st



import streamlit as st
from pathlib import Path
from utils.vector_store import process_file, search

from utils.model import generate_answer
from utils.prompts import generate_prompts


if "file_uploaded" not in st.session_state:
    st.session_state["file_uploaded"] = False

if "vectors" not in st.session_state:
    st.session_state["vectors"] = None

# --- Step 1: File Upload ---
file = st.file_uploader("Upload File", type=["pdf",'txt','docx'])

# --- Step 2: Model Selection ---
model = st.selectbox("Select LLM Model", ["microsoft/Phi-3-mini-4k-instruct",
                                          "openai-community/gpt2-medium",
                                          "tiiuae/falcon-rw-1b",
                                          "meta-llama/Llama-3.2-1B-Instruct"])

# --- Step 3: Upload Button ---
upload_clicked = st.button("Upload and Process Document")


if upload_clicked  and file:


    file_name = Path(file.name).name
    temp_file_path = f"/tmp/{file_name}"


    # Save the file locally
    with open(temp_file_path, "wb") as f:
        f.write(file.read())

    st.session_state["vectors"] = process_file(temp_file_path)


col1, col2 = st.columns([9,3])

with col1:
    chat_msg = st.text_area("What's your query?")

with col2:
    top_vectors = st.number_input("No of vectors",min_value=3,max_value=15)

answer = st.button("Answer")

st.write(chat_msg)
if answer:
    with st.spinner("Processing your question. Please wait.."):
        context_list = search(chat_msg,st.session_state["vectors"],top_vectors)

        contexts = "\n".join(context_list)

        prompt = generate_prompts(chat_msg,contexts)

        output = generate_answer(model,prompt)

        st.markdown("Response is:")
        st.code(output)