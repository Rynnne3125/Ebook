#!/usr/bin/env python3
"""
Test script to upload PDF and verify voice assistant integration
"""

import requests
import json
import os
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

def create_test_pdf():
    """Create a simple test PDF with multiple pages"""
    filename = "voice_test.pdf"
    
    # Create PDF with multiple pages
    c = canvas.Canvas(filename, pagesize=letter)
    
    # Page 1
    c.drawString(100, 750, "Voice Assistant Test - Page 1")
    c.drawString(100, 700, "This is the first page of our test document.")
    c.drawString(100, 650, "The AI should read this content aloud.")
    c.drawString(100, 600, "Key concepts: Introduction, Voice Technology, AI Assistant")
    c.showPage()
    
    # Page 2
    c.drawString(100, 750, "Voice Assistant Test - Page 2")
    c.drawString(100, 700, "This is the second page with different content.")
    c.drawString(100, 650, "The flipbook should automatically advance after reading.")
    c.drawString(100, 600, "Key concepts: Automation, Page Navigation, TTS")
    c.showPage()
    
    # Page 3
    c.drawString(100, 750, "Voice Assistant Test - Page 3")
    c.drawString(100, 700, "Final page of our test document.")
    c.drawString(100, 650, "Voice controls should work: play, pause, next, previous.")
    c.drawString(100, 600, "Key concepts: User Controls, Voice Interface, Testing")
    c.showPage()
    
    c.save()
    return filename

def test_upload_and_voice():
    """Test PDF upload and voice assistant integration"""
    
    # Create test PDF
    print("📄 Creating test PDF...")
    pdf_file = create_test_pdf()
    
    try:
        # Upload to backend
        print("📤 Uploading PDF to backend...")
        
        url = 'http://localhost:5001/upload-pdf'
        
        with open(pdf_file, 'rb') as f:
            files = {'file': (pdf_file, f, 'application/pdf')}
            data = {
                'title': 'Voice Assistant Test Book',
                'author': 'Test Author',
                'subject': 'Technology'
            }
            
            response = requests.post(url, files=files, data=data)
        
        print(f"📊 Response Status: {response.status_code}")
        
        if response.status_code == 201:
            result = response.json()
            print("✅ Upload successful!")
            print(f"📚 Book ID: {result.get('book_id')}")
            print(f"📖 Flipbook URL: {result.get('flipbook_url')}")
            print(f"📄 Pages: {result.get('total_pages', 0)}")
            
            # Check if teaching scripts were generated
            pages = result.get('pages', [])
            if pages:
                print(f"🎤 Teaching scripts generated for {len(pages)} pages:")
                for i, page in enumerate(pages, 1):
                    script = page.get('teaching_script', {})
                    if script:
                        print(f"   Page {i}: {script.get('script', 'No script')[:100]}...")
                    else:
                        print(f"   Page {i}: No teaching script")
            else:
                print("❌ No pages with teaching scripts found")
                
            return result
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None
    finally:
        # Clean up
        if os.path.exists(pdf_file):
            try:
                os.remove(pdf_file)
                print(f"🧹 Cleaned up {pdf_file}")
            except:
                print(f"⚠️ Could not remove {pdf_file}")

if __name__ == "__main__":
    print("🎤 Testing Voice Assistant Integration")
    print("=" * 50)
    
    # Check backend health
    try:
        health_response = requests.get('http://localhost:5001/health', timeout=5)
        if health_response.status_code == 200:
            print("✅ Backend is healthy")
        else:
            print("❌ Backend health check failed")
            exit(1)
    except:
        print("❌ Backend is not running")
        exit(1)
    
    # Test upload
    result = test_upload_and_voice()
    
    if result:
        print("\n🎉 Test completed successfully!")
        print("📱 Now test in Flutter app:")
        print("   1. Go to http://localhost:3000")
        print("   2. Find the uploaded book")
        print("   3. Open flipbook reader")
        print("   4. Voice assistant should auto-start reading")
        print("   5. Test play/pause/next/previous controls")
    else:
        print("\n❌ Test failed!")
