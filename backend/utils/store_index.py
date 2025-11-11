from dotenv import load_dotenv
import os
from utils.helper import load_pdf_files, filter_to_minial_docs, text_split, embedding
from pinecone import Pinecone
from pinecone import ServerlessSpec 
from langchain_pinecone import PineconeVectorStore

load_dotenv()

PINECONE_API_KEY=os.environ.get('PINECONE_API_KEY')
GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')

os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["GOOGLE_API_KEY"] = GOOGLE_API_KEY

extracted_data = load_pdf_files("data/")
filter_data = filter_to_minial_docs(extracted_data)
text_chunks = text_split(filter_data)

embeddings = embedding

pinecone_api_key = PINECONE_API_KEY

pc = Pinecone(api_key=pinecone_api_key)

index_name = "analytic-stack"

if not pc.has_index(index_name):
    pc.create_index(
        name=index_name
        , dimension=embeddings.embedding_dimension
        , serverless_spec=ServerlessSpec(min_nodes=1, max_nodes=4)
    )

docsearch = PineconeVectorStore.from_documents(
    documents=text_chunks
    , embedding=embeddings
    , pinecone_instance=pc
    , index_name="pdf-chatbot-index"
)

