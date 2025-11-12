import streamlit as st
import requests

# URL FastAPI backend (sửa nếu backend chạy ở server khác)
API_URL = "http://localhost:8000/get"

st.set_page_config(page_title="RAG Chatbot", page_icon="🤖", layout="centered")

st.title("💬 RAG Chatbot Interface")
st.write("Hỏi bất kỳ điều gì liên quan đến tài liệu trong Pinecone index của bạn!")

# Khu vực nhập tin nhắn
user_input = st.text_area("Nhập câu hỏi của bạn:", placeholder="Ví dụ: Tóm tắt nội dung báo cáo phân tích doanh thu tháng 10...")

# Khi nhấn nút Gửi
if st.button("Gửi câu hỏi"):
    if not user_input.strip():
        st.warning("⚠️ Vui lòng nhập câu hỏi trước khi gửi.")
    else:
        with st.spinner("Đang truy vấn mô hình..."):
            try:
                response = requests.post(API_URL, data={"msg": user_input})
                if response.status_code == 200:
                    st.success("✅ Kết quả trả lời:")
                    st.markdown(response.text)
                else:
                    st.error(f"Lỗi từ server: {response.status_code}")
            except Exception as e:
                st.error(f"Không thể kết nối đến API: {e}")

# Phần hiển thị lịch sử trò chuyện
if "history" not in st.session_state:
    st.session_state["history"] = []

if user_input and st.button("Lưu vào lịch sử", key="save"):
    st.session_state["history"].append({"question": user_input})

if st.session_state["history"]:
    st.subheader("🕓 Lịch sử câu hỏi")
    for i, item in enumerate(st.session_state["history"][::-1]):
        st.markdown(f"**{i+1}.** {item['question']}")
