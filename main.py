
from fastapi import FastAPI, Form
import uvicorn
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_pinecone import PineconeVectorStore
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from backend.utils.prompt import *

import os
from dotenv import load_dotenv



load_dotenv()

PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
    

os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["GOOGLE_API_KEY"] = GOOGLE_API_KEY


embedding = GoogleGenerativeAIEmbeddings(model="text-embedding-004")

index_name = "analytic-stack"
docsearch = PineconeVectorStore.from_existing_index(
    embedding=embedding
    , index_name=index_name
)

retriever = docsearch.as_retriever(search_type="similarity", search_kwargs={"k":8})


chatModel = ChatGoogleGenerativeAI(model="gemini-2.5-flash", api_key=GOOGLE_API_KEY)

prompt = ChatPromptTemplate.from_messages(
    [
        ("system", system_prompt),
        ("human", "{input}"),
    ]
)


question_answer_chain = create_stuff_documents_chain(chatModel, prompt)
rag_chain = create_retrieval_chain(retriever, question_answer_chain)


app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}

    # Định nghĩa route xử lý chat (gửi và nhận tin nhắn)
@app.post("/get")
async def chat(msg: str = Form(...)):
    input = msg
    print(input)
    response = rag_chain.invoke({"input": msg})
    print("Response : ", response["answer"])
    return response["answer"]

if __name__ == '__main__':
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)



