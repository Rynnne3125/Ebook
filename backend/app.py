from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import requests
import cloudinary
import cloudinary.uploader
import cloudinary.api
from werkzeug.utils import secure_filename
import PyPDF2
import io
import base64
import google.generativeai as genai
import json
from datetime import datetime
from dotenv import load_dotenv
# import firebase_admin
# from firebase_admin import credentials, firestore

# Load environment variables
load_dotenv()
import uuid

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'pdf'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# Cloudinary configuration
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "ddjrbkhpx"),
    api_key=os.getenv("CLOUDINARY_API_KEY", "534297453884984"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET", "23OLY_AqI11rISnQ5EHl66OHahU")
)

# Heyzine API configuration
HEYZINE_CLIENT_ID = os.getenv("HEYZINE_CLIENT_ID", "2485b5387a1a6dd0")
HEYZINE_API_KEY = os.getenv("HEYZINE_API_KEY", "96c6bee934081689fde855019b374f01c5e5199e.2485b5387a1a6dd0")
HEYZINE_API_URL = "https://heyzine.com/api1"

# Gemini AI configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBGWplwpUQUIUZ9QAg3dPMj5poFeNr1qu8")
genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel("gemini-2.0-flash")

# Ensure upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def extract_text_from_pdf(pdf_file):
    """Extract text from PDF file"""
    try:
        pdf_reader = PyPDF2.PdfReader(pdf_file)
        pages_text = []
        
        for page_num, page in enumerate(pdf_reader.pages):
            text = page.extract_text()
            pages_text.append({
                'page_number': page_num + 1,
                'content': text.strip()
            })
        
        return pages_text
    except Exception as e:
        print(f"Error extracting text from PDF: {e}")
        return []

def upload_to_cloudinary(file_path, public_id=None):
    """Upload file to Cloudinary"""
    try:
        result = cloudinary.uploader.upload(
            file_path,
            public_id=public_id,
            resource_type="raw",  # Use raw for PDF files
            folder="ebooks",
            type="upload",  # Ensure it's upload type
            access_mode="public"  # Make sure it's publicly accessible
        )
        print(f"🔍 Cloudinary upload result: {result}")

        # Generate public URL for raw files
        if result and result.get('public_id'):
            from cloudinary.utils import cloudinary_url
            public_url, _ = cloudinary_url(
                result['public_id'],
                resource_type="raw",
                secure=True,
                type="upload"
            )
            result['public_url'] = public_url
            print(f"🔍 Cloudinary public URL: {public_url}")

        return result
    except Exception as e:
        print(f"Error uploading to Cloudinary: {e}")
        return None

def create_heyzine_flipbook(pdf_url, title="Untitled Book"):
    """Create flipbook using Heyzine API"""
    try:
        # Test if PDF URL is accessible first (skip validation for now)
        try:
            test_response = requests.head(pdf_url, timeout=10)
            print(f"🔍 PDF URL test: {test_response.status_code}")
            if test_response.status_code != 200:
                print(f"⚠️ PDF URL not accessible: {test_response.status_code}, but continuing...")
                # Don't return None, let Heyzine try anyway
        except Exception as e:
            print(f"⚠️ PDF URL test failed: {e}, but continuing...")

        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {HEYZINE_API_KEY}'
        }

        # Use the correct Heyzine API format
        data = {
            'pdf': pdf_url,
            'client_id': HEYZINE_CLIENT_ID,  # Use correct client_id
            'title': title,
            'download': False,
            'full_screen': True,
            'share': True,
            'prev_next': True,
            'show_info': True
        }

        print(f"🔍 Heyzine API Request: {data}")

        # Use correct Heyzine API endpoint
        url = "https://heyzine.com/api1/rest"
        print(f"🔍 Heyzine API URL: {url}")

        response = requests.post(
            url,
            headers=headers,
            json=data,
            timeout=60
        )

        print(f"🔍 Heyzine API Response Status: {response.status_code}")
        print(f"🔍 Heyzine API Response: {response.text}")

        if response.status_code == 200:
            result = response.json()
            print(f"🔍 Heyzine API Parsed Result: {result}")

            # Check if Heyzine API returned error (has 'success': false)
            if result.get('success') == False:
                print(f"❌ Heyzine API returned error: {result.get('msg', 'Unknown error')}")
                return None

            # Check if we have a valid flipbook URL (success case)
            if result.get('url'):
                flipbook_result = {
                    'flipbook_url': result.get('url', ''),
                    'embed_url': result.get('url', ''),
                    'thumbnail_url': result.get('thumbnail', ''),
                    'flipbook_id': result.get('id', ''),
                    'pdf_url': result.get('pdf', pdf_url)
                }
                print(f"🔍 Final Heyzine Result: {flipbook_result}")
                return flipbook_result
            else:
                print(f"❌ Heyzine API returned no URL: {result}")
                return None
        else:
            print(f"❌ Heyzine API error: {response.status_code} - {response.text}")
            return None

    except Exception as e:
        print(f"Error creating Heyzine flipbook: {e}")
        return None

def generate_teaching_script(page_content, page_number, book_title):
    """Generate teaching script for a page using Gemini AI"""
    try:
        prompt = f"""
        Bạn là giáo viên Hóa học chuyên nghiệp. Hãy tạo kịch bản giảng dạy cho trang {page_number} của sách "{book_title}".
        
        Nội dung trang:
        {page_content}
        
        Yêu cầu:
        1. Tạo kịch bản giảng dạy ngắn gọn (2-3 phút)
        2. Giải thích khái niệm một cách dễ hiểu
        3. Đưa ra ví dụ thực tế
        4. Tạo câu hỏi kiểm tra hiểu biết
        5. Sử dụng ngôn ngữ phù hợp với học sinh cấp 2
        
        Trả về JSON format:
        {{
            "script": "Kịch bản giảng dạy...",
            "key_concepts": ["khái niệm 1", "khái niệm 2"],
            "examples": ["ví dụ 1", "ví dụ 2"],
            "questions": ["câu hỏi 1", "câu hỏi 2"],
            "duration_minutes": 3
        }}
        """
        
        response = gemini_model.generate_content(prompt)

        # Extract JSON from response text
        response_text = response.text.strip()

        # Try to find JSON in the response
        try:
            # Look for JSON block between ```json and ```
            if "```json" in response_text:
                start = response_text.find("```json") + 7
                end = response_text.find("```", start)
                json_text = response_text[start:end].strip()
            elif "{" in response_text and "}" in response_text:
                # Extract JSON from first { to last }
                start = response_text.find("{")
                end = response_text.rfind("}") + 1
                json_text = response_text[start:end]
            else:
                json_text = response_text

            script_data = json.loads(json_text)
            return script_data
        except json.JSONDecodeError:
            # If JSON parsing fails, create structured response from text
            return {
                "script": response_text[:500] + "..." if len(response_text) > 500 else response_text,
                "key_concepts": [],
                "examples": [],
                "questions": [],
                "duration_minutes": 3
            }
        
    except Exception as e:
        error_msg = str(e)
        print(f"Error generating teaching script: {error_msg}")

        # Handle quota exceeded error
        if "429" in error_msg or "quota" in error_msg.lower() or "exceeded" in error_msg.lower():
            print("⚠️ Gemini API quota exceeded, using fallback script")
            return {
                "script": f"Kịch bản giảng dạy tự động cho trang {page_number}. Nội dung chính: {page_content[:300]}. Đây là nội dung quan trọng cần học sinh nắm vững.",
                "key_concepts": ["Khái niệm chính", "Kiến thức cơ bản"],
                "examples": ["Ví dụ minh họa", "Ứng dụng thực tế"],
                "questions": ["Câu hỏi kiểm tra hiểu biết", "Bài tập vận dụng"],
                "duration_minutes": 3
            }

        # General fallback
        return {
            "script": f"Nội dung trang {page_number}: {page_content[:200]}...",
            "key_concepts": [],
            "examples": [],
            "questions": [],
            "duration_minutes": 2
        }

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/upload-pdf', methods=['POST'])
def upload_pdf():
    """Upload PDF and process it"""
    try:
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type. Only PDF allowed'}), 400
        
        # Get additional data
        title = request.form.get('title', 'Untitled Book')
        author = request.form.get('author', 'Unknown Author')
        subject = request.form.get('subject', 'Chemistry')
        
        # Generate unique ID
        book_id = str(uuid.uuid4())
        
        # Save file temporarily
        filename = secure_filename(file.filename)
        temp_path = os.path.join(UPLOAD_FOLDER, f"{book_id}_{filename}")
        file.save(temp_path)
        
        # Upload to Cloudinary
        print("📤 Uploading to Cloudinary...")
        cloudinary_result = upload_to_cloudinary(temp_path, f"ebook_{book_id}")
        if not cloudinary_result:
            return jsonify({'error': 'Failed to upload to Cloudinary'}), 500
        
        # Use public URL if available, otherwise secure_url
        pdf_url = cloudinary_result.get('public_url', cloudinary_result['secure_url'])

        # Try to make Cloudinary URL public accessible
        # For now, let's try the actual Cloudinary URL
        print(f"🔍 Using Cloudinary PDF URL for Heyzine: {pdf_url}")
        
        # Wait a moment for Cloudinary URL to be available
        import time
        time.sleep(2)

        # Verify PDF URL is accessible
        try:
            import requests
            response = requests.head(pdf_url, timeout=10)
            print(f"🔍 PDF URL accessibility check: {response.status_code}")
        except Exception as e:
            print(f"⚠️ PDF URL accessibility error: {e}")

        # Create Heyzine flipbook (optional - skip if fails)
        print("📖 Creating Heyzine flipbook...")
        print(f"🔍 PDF URL for Heyzine: {pdf_url}")
        # Use actual PDF URL
        heyzine_result = create_heyzine_flipbook(pdf_url, title)
        if heyzine_result and heyzine_result.get('flipbook_url'):
            flipbook_url = heyzine_result.get('flipbook_url', '')
            print("✅ Heyzine flipbook created successfully")
            print(f"🔍 Flipbook URL: {flipbook_url}")
        else:
            flipbook_url = ""  # Empty if Heyzine fails - don't use PDF URL
            heyzine_result = None
            print("⚠️ Heyzine flipbook creation failed")
            print(f"🔍 Heyzine result: {heyzine_result}")
        
        # Extract text from PDF
        print("📝 Extracting text from PDF...")
        with open(temp_path, 'rb') as pdf_file:
            pages_text = extract_text_from_pdf(pdf_file)
        
        # Generate teaching scripts for each page
        print("🤖 Generating AI teaching scripts...")
        pages_with_scripts = []
        
        for page_data in pages_text:
            if page_data['content'].strip():  # Only process pages with content
                script = generate_teaching_script(
                    page_data['content'], 
                    page_data['page_number'], 
                    title
                )
                
                pages_with_scripts.append({
                    'page_number': page_data['page_number'],
                    'content': page_data['content'],
                    'teaching_script': script
                })
        
        # Clean up temporary file
        os.remove(temp_path)

        # Save to Firestore (simulate - will be handled by Flutter)
        firestore_data = {
            'book_id': book_id,
            'title': title,
            'author': author,
            'description': f'Sách {subject} - {title}. Được tạo tự động từ PDF với AI teaching scripts.',
            'subject': subject,
            'grade': '8',  # Default grade
            'chapter': 1,  # Default chapter
            'heyzineUrl': flipbook_url,  # This should be https://heyzine.com/flip-book/xxx.html or empty
            'coverImageUrl': heyzine_result.get('thumbnail_url', '') if heyzine_result else '',
            'tags': [subject, 'AI Generated', 'Interactive'],
            'rating': 0.0,
            'viewCount': 0,
            'bookmarkCount': 0,
            'isPublished': True,
            'pages': pages_with_scripts,
            'total_pages': len(pages_with_scripts),
            'pdf_url': pdf_url,  # Keep original PDF URL separate
            'created_at': datetime.now().isoformat()
        }

        # Prepare response
        result = {
            'book_id': book_id,
            'title': title,
            'author': author,
            'subject': subject,
            'pdf_url': pdf_url,
            'flipbook_url': flipbook_url,
            'heyzine_data': heyzine_result,
            'pages': pages_with_scripts,
            'total_pages': len(pages_with_scripts),
            'firestore_data': firestore_data,
            'created_at': datetime.now().isoformat()
        }

        print(f"✅ Successfully processed book: {title}")
        return jsonify(result), 201
        
    except Exception as e:
        print(f"❌ Error processing PDF: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/books', methods=['GET'])
def get_books():
    """Get list of all books"""
    # This would typically fetch from database
    # For now, return empty list
    return jsonify({'books': []})

@app.route('/books/<book_id>', methods=['GET'])
def get_book(book_id):
    """Get specific book details"""
    # This would typically fetch from database
    return jsonify({'error': 'Book not found'}), 404

if __name__ == '__main__':
    print("🚀 Starting EBook Backend API Server...")
    print("📚 Cloudinary: Configured")
    print("📖 Heyzine API: Configured") 
    print("🤖 Gemini AI: Configured")
    print("🌐 Server: http://localhost:5001")
    app.run(host='0.0.0.0', port=5001, debug=True)
