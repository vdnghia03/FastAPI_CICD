

from langchain.document_loaders import PyPDFLoader, DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os
from typing import List
from langchain.schema import Document
from langchain_google_genai import GoogleGenerativeAIEmbeddings




# Extract text from PDF files
def load_pdf_files(data):

    loader = DirectoryLoader(
        data
        , glob="*.pdf"
        , loader_cls=PyPDFLoader
    )

    documents = loader.load()

    return documents




def filter_to_minial_docs(docs: list[Document]) -> List[Document]:
    minimal_docs : List[Document] = []

    for doc in docs:
        src = doc.metadata.get("source")
        minimal_docs.append(
            Document(
                page_content=doc.page_content
                , metadata = {"source": src}
            )
        )

    return minimal_docs


def text_split(minimal_docs):
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500
        , chunk_overlap = 20
    )
    texts = text_splitter.split_documents(minimal_docs)
    return texts




embedding = GoogleGenerativeAIEmbeddings(model="text-embedding-004")
