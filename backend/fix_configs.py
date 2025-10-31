#!/usr/bin/env python3
import os
import re

config_dir = "YemenBooking.Infrastructure/Data/Configurations"

# Get all .cs files
cs_files = [f for f in os.listdir(config_dir) if f.endswith('.cs')]

for filename in cs_files:
    filepath = os.path.join(config_dir, filename)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Fix GETUTCDATE() to NOW()
    content = content.replace('GETUTCDATE()', 'NOW()')
    
    # Fix datetime to timestamp with time zone
    content = content.replace('HasColumnType("datetime")', 'HasColumnType("timestamp with time zone")')
    
    # Fix NVARCHAR(MAX) to text
    content = content.replace('HasColumnType("NVARCHAR(MAX)")', 'HasColumnType("text")')
    content = content.replace('HasColumnType("nvarchar(max)")', 'HasColumnType("text")')
    
    # Only write if changes were made
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filename}")

print("\nDone! All basic PostgreSQL fixes applied.")
