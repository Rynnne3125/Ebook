#!/usr/bin/env python3
"""
Check Firestore for the uploaded book
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

def check_firestore_books():
    """Check all books in Firestore"""
    
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate('firebase-service-account.json')
            firebase_admin.initialize_app(cred)
        
        # Get Firestore client
        db = firestore.client()
        
        print("🔍 Checking all books in Firestore...")
        print("=" * 60)
        
        # Get all books
        books_ref = db.collection('books')
        books = books_ref.stream()
        
        book_count = 0
        target_book_id = 'f60f20ba-e6fd-45af-b804-fa294d58fc55'
        
        for book in books:
            book_count += 1
            book_data = book.to_dict()
            
            print(f"\n📚 Book {book_count}: {book.id}")
            print(f"   Title: {book_data.get('title', 'No title')}")
            print(f"   Author: {book_data.get('author', 'No author')}")
            print(f"   Published: {book_data.get('isPublished', False)}")
            print(f"   Pages: {len(book_data.get('pages', []))}")
            
            # Check if this is our target book
            if book.id == target_book_id:
                print(f"   🎯 THIS IS OUR TARGET BOOK!")
                pages = book_data.get('pages', [])
                if pages:
                    print(f"   📄 Page details:")
                    for i, page in enumerate(pages, 1):
                        script = page.get('teaching_script', {})
                        if script:
                            print(f"      Page {i}: Has teaching script ({len(script.get('script', ''))} chars)")
                        else:
                            print(f"      Page {i}: No teaching script")
                else:
                    print(f"   ❌ No pages found!")
            
            # Check if has teaching scripts
            pages = book_data.get('pages', [])
            scripts_count = sum(1 for page in pages if page.get('teaching_script'))
            if scripts_count > 0:
                print(f"   🎤 Teaching scripts: {scripts_count}/{len(pages)} pages")
            else:
                print(f"   ⚠️ No teaching scripts")
        
        print(f"\n📊 Total books found: {book_count}")
        
        # Check specifically for our target book
        print(f"\n🎯 Checking specifically for book: {target_book_id}")
        try:
            target_doc = books_ref.document(target_book_id).get()
            if target_doc.exists:
                print("✅ Target book found!")
                data = target_doc.to_dict()
                print(f"   Title: {data.get('title')}")
                print(f"   Published: {data.get('isPublished')}")
                print(f"   Pages: {len(data.get('pages', []))}")
            else:
                print("❌ Target book NOT found!")
        except Exception as e:
            print(f"❌ Error checking target book: {e}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_firestore_books()
