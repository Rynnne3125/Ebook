import speech_recognition as sr
import pygame
import google.generativeai as genai
import edge_tts
import asyncio
import re
from io import BytesIO
from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import threading
import queue

# === Gemini config ===
genai.configure(api_key="AIzaSyBGWplwpUQUIUZ9QAg3dPMj5poFeNr1qu8")
gemini_model = genai.GenerativeModel("gemini-2.0-flash")

app = Flask(__name__)
CORS(app)

pygame.mixer.init()
history = []

def clean_text(text):
    return re.sub(r"[*_`>#+-]", "", text).strip()

# === Edge TTS tạo audio base64 ===
async def generate_audio_base64(text, voice="vi-VN-HoaiMyNeural"):
    mp3_fp = BytesIO()
    communicate = edge_tts.Communicate(text, voice)
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            mp3_fp.write(chunk["data"])
    mp3_fp.seek(0)
    audio_base64 = base64.b64encode(mp3_fp.read()).decode('utf-8')
    return audio_base64

# === Xử lý hội thoại Gemini ===
def get_gemini_reply(user_text, page_content=""):
    try:
        context = f"Nội dung trang hiện tại: {page_content}\n" if page_content else ""
        response = gemini_model.generate_content(
            f"""
            Bạn là giáo viên Hóa học vui tính, dạy học sinh cấp 2. 
            Trả lời dễ hiểu, có ví dụ thực tế, ngắn gọn, xúc tích (tối đa 100 từ).
            **Chỉ trả lời với vai trò giáo viên, không được nhập vai học sinh.**
            
            {context}
            Câu hỏi của học sinh: "{user_text}"
            
            Nếu học sinh hỏi về nội dung trang, hãy giải thích dựa trên nội dung đó.
            Nếu hỏi "đọc trang" hoặc "giải thích trang", hãy tóm tắt nội dung trang.
            """,
            generation_config=genai.types.GenerationConfig(
                temperature=0.7,
                top_p=0.95,
                top_k=40
            )
        )
        return response.text.strip()
    except Exception as e:
        print(f"Gemini error: {e}")
        return "Thầy đang bận chút, em chờ tí nhé!"

# Thêm voice recognition
recognizer = sr.Recognizer()
microphone = sr.Microphone()
audio_queue = queue.Queue()

def listen_for_voice():
    """Background thread để lắng nghe voice input"""
    with microphone as source:
        recognizer.adjust_for_ambient_noise(source)
    
    while True:
        try:
            with microphone as source:
                print("🎤 Listening for voice input...")
                audio = recognizer.listen(source, timeout=1, phrase_time_limit=5)
            
            try:
                # Nhận dạng tiếng Việt
                text = recognizer.recognize_google(audio, language='vi-VN')
                print(f"🗣️ Voice input: {text}")
                audio_queue.put(text)
            except sr.UnknownValueError:
                pass  # Không nhận dạng được
            except sr.RequestError as e:
                print(f"Voice recognition error: {e}")
                
        except sr.WaitTimeoutError:
            pass  # Timeout, tiếp tục lắng nghe

# Khởi động voice listener thread
voice_thread = threading.Thread(target=listen_for_voice, daemon=True)
voice_thread.start()

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_message = data.get('message', '')
        page_content = data.get('pageContent', '')
        
        if not user_message:
            return jsonify({'error': 'No message provided'}), 400
        
        # Lưu lịch sử
        history.append(f"Học sinh: {user_message}")
        
        # Gemini trả lời
        reply = get_gemini_reply(user_message, page_content)
        history.append(f"Thầy: {reply}")
        
        # Tạo audio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        audio_base64 = loop.run_until_complete(generate_audio_base64(clean_text(reply)))
        loop.close()
        
        return jsonify({
            'reply': reply,
            'audio': audio_base64,
            'timestamp': str(asyncio.get_event_loop().time())
        })
        
    except Exception as e:
        print(f"Chat error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/read-page', methods=['POST'])
def read_page():
    try:
        data = request.json
        page_content = data.get('pageContent', '')
        
        if not page_content:
            reply = "Không có nội dung để đọc trên trang này."
        else:
            reply = f"Tôi sẽ đọc nội dung trang này cho bạn. {page_content}"
        
        # Tạo audio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        audio_base64 = loop.run_until_complete(generate_audio_base64(clean_text(reply)))
        loop.close()
        
        return jsonify({
            'reply': reply,
            'audio': audio_base64
        })
        
    except Exception as e:
        print(f"Read page error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/read-teaching-script', methods=['POST'])
def read_teaching_script():
    """Endpoint để đọc teaching script với voice assistant"""
    try:
        data = request.json
        script = data.get('script', '')
        page_number = data.get('pageNumber', 1)

        if not script:
            return jsonify({'error': 'No script provided'}), 400

        print(f"🎤 Reading teaching script for page {page_number}")
        print(f"📖 Script length: {len(script)} characters")

        # Tạo audio với Edge TTS
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        audio_base64 = loop.run_until_complete(generate_audio_base64(clean_text(script), voice="vi-VN-HoaiMyNeural"))
        loop.close()

        return jsonify({
            'success': True,
            'audio': audio_base64,
            'pageNumber': page_number,
            'scriptLength': len(script)
        })

    except Exception as e:
        print(f"❌ Error in read_teaching_script: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

@app.route('/voice-input', methods=['GET'])
def get_voice_input():
    """Endpoint để lấy voice input"""
    try:
        if not audio_queue.empty():
            voice_text = audio_queue.get_nowait()
            return jsonify({
                'text': voice_text,
                'hasInput': True
            })
        else:
            return jsonify({
                'text': '',
                'hasInput': False
            })
    except Exception as e:
        print(f"Voice input error: {e}")
        return jsonify({
            'text': '',
            'hasInput': False,
            'error': str(e)
        })

@app.route('/start-voice-listening', methods=['POST'])
def start_voice_listening():
    """Bắt đầu lắng nghe voice"""
    try:
        # Clear queue
        while not audio_queue.empty():
            audio_queue.get_nowait()
        
        return jsonify({'status': 'listening'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stop-voice-listening', methods=['POST'])
def stop_voice_listening():
    """Dừng lắng nghe voice"""
    try:
        # Clear queue
        while not audio_queue.empty():
            audio_queue.get_nowait()
            
        return jsonify({'status': 'stopped'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    print("=" * 50)
    print("🤖 AI Teaching Assistant Server Starting...")
    print("📚 Gemini AI: Ready")
    print("🔊 Edge TTS: Ready")
    print("🌐 Server: http://localhost:5000")
    print("🔗 Health Check: http://localhost:5000/health")
    print("=" * 50)

    try:
        app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        print("💡 Make sure port 5000 is not in use")
