#!/usr/bin/env python3
import requests
import json

# Test Heyzine API directly with public PDF
def test_heyzine_direct():
    url = "https://heyzine.com/api1/rest"

    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 96c6bee934081689fde855019b374f01c5e5199e.2485b5387a1a6dd0'
    }

    # Use a public PDF URL for testing
    data = {
        'pdf': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'client_id': '2485b5387a1a6dd0',
        'title': 'Test Flipbook',
        'download': False,
        'full_screen': True,
        'share': True,
        'prev_next': True,
        'show_info': True
    }

    print("🧪 Testing Heyzine API directly...")
    print(f"📤 URL: {url}")
    print(f"📝 Data: {data}")

    try:
        response = requests.post(url, headers=headers, json=data, timeout=30)

        print(f"📊 Response Status: {response.status_code}")
        print(f"📄 Response: {response.text}")

        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Heyzine API works!")
                print(f"🔗 Flipbook URL: {result.get('url', 'N/A')}")
            else:
                print(f"❌ Heyzine API error: {result.get('msg', 'Unknown error')}")
        else:
            print("❌ HTTP error!")

    except Exception as e:
        print(f"❌ Request failed: {e}")

# Test upload PDF to backend
def test_upload():
    url = "http://localhost:5001/upload-pdf"
    
    # Test data
    data = {
        'title': 'Test Book - Hóa học',
        'author': 'Test Author',
        'subject': 'Hóa học'
    }
    
    # Create a simple test PDF file (dummy content)
    test_pdf_content = b"""%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
72 720 Td
(Test PDF Content) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000206 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
299
%%EOF"""

    # Save test PDF
    with open('test.pdf', 'wb') as f:
        f.write(test_pdf_content)
    
    # Upload file
    files = {'file': ('test.pdf', open('test.pdf', 'rb'), 'application/pdf')}
    
    print("🚀 Testing PDF upload...")
    print(f"📤 URL: {url}")
    print(f"📝 Data: {data}")
    
    try:
        response = requests.post(url, data=data, files=files, timeout=120)
        
        print(f"📊 Response Status: {response.status_code}")
        print(f"📄 Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200 or response.status_code == 201:
            result = response.json()
            print("✅ Upload successful!")
            print(f"📚 Book ID: {result.get('book_id', 'N/A')}")
            print(f"📖 Flipbook URL: {result.get('flipbook_url', 'N/A')}")
            print(f"🔗 PDF URL: {result.get('pdf_url', 'N/A')}")
            print(f"📄 Pages: {len(result.get('pages', []))}")
            
            # Check Firestore data
            firestore_data = result.get('firestore_data', {})
            print(f"🔥 Firestore heyzineUrl: {firestore_data.get('heyzineUrl', 'N/A')}")
            
        else:
            print("❌ Upload failed!")
            print(f"Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Request failed: {e}")
    
    finally:
        # Cleanup
        import os
        if os.path.exists('test.pdf'):
            os.remove('test.pdf')

if __name__ == "__main__":
    print("=== Testing Heyzine API directly ===")
    test_heyzine_direct()
    print("\n=== Testing full upload workflow ===")
    test_upload()
