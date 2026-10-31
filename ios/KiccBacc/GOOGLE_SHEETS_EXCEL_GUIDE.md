# 📊 Google Sheets & Excel Support Guide

Your email invitation system now supports **3 ways** to import emails!

---

## ✨ Import Methods

1. **Google Sheets** (✅ Recommended - Easiest!)
2. **Excel Files** (.xlsx)
3. **CSV Files** (.csv)

---

## 🎯 Method 1: Google Sheets (BEST!)

### Why Google Sheets?
✅ No file upload needed  
✅ Real-time updates  
✅ Collaborate with team  
✅ Easy to share  
✅ Works from any device  

### How to Use:

#### Step 1: Create or Open Google Sheet
```
1. Go to: https://sheets.google.com/
2. Create new sheet or open existing
3. Put emails in first column (Column A)
```

#### Step 2: Share the Sheet
```
1. Click "Share" button (top right)
2. Change to "Anyone with the link can view"
3. Click "Copy link"
```

#### Step 3: Import in App
```
1. Open KiccBacc app
2. Go to Event Properties → Import List
3. Select "Google Sheets" tab
4. Paste the link
5. Tap "Import from Google Sheets"
6. Done! ✅
```

### Example Google Sheet Format:
```
| email                    |
|--------------------------|
| john@example.com         |
| jane@example.com         |
| mike@example.com         |
```

### Supported URL Formats:
```
✅ https://docs.google.com/spreadsheets/d/ABC123.../edit
✅ https://docs.google.com/spreadsheets/d/ABC123...
✅ Any Google Sheets share link
```

---

## 📁 Method 2: Excel Files

### Supported Formats:
- ✅ .xlsx (Excel 2007+)
- ✅ .xls (Excel 97-2003)  
- ✅ Best: Export as CSV from Excel

### How to Use Excel:

#### Option A: Direct Upload (Simple)
```
1. Create Excel file with emails in Column A
2. Save the file
3. In KiccBacc app:
   - Event Properties → Import List
   - Select "Upload File" tab
   - Choose your Excel file
4. App will extract emails automatically
```

#### Option B: Export to CSV (Most Reliable)
```
1. Open Excel file
2. File → Save As
3. Choose "CSV UTF-8 (Comma delimited)" format
4. Save
5. Upload CSV file in app
```

### Excel File Format:
```
Column A should contain emails:

| email                    |
|--------------------------|
| john@example.com         |
| jane@example.com         |
```

---

## 📄 Method 3: CSV Files

### How to Create CSV:

#### From Excel:
```
1. File → Save As
2. Format: CSV UTF-8 (Comma delimited)
3. Save
```

#### From Google Sheets:
```
1. File → Download → CSV
2. Save file
```

#### From Text Editor:
```
Create a file with one email per line:

email
john@example.com
jane@example.com
mike@example.com
```

---

## 🎨 Example Formats

### Google Sheets (Recommended):
```
Share link: https://docs.google.com/spreadsheets/d/ABC123.../edit

Sheet contents:
A1: email
A2: john@example.com
A3: jane@example.com
A4: mike@example.com
```

### Excel File:
```
File: event_invites.xlsx

Column A:
- email (header)
- john@example.com
- jane@example.com
- mike@example.com
```

### CSV File:
```
File: emails.csv

Content:
email
john@example.com
jane@example.com
mike@example.com
```

---

## 💡 Pro Tips

### For Google Sheets:
1. ✅ **Use templates** - Create a master sheet and copy for each event
2. ✅ **Collaborate** - Multiple people can add emails simultaneously
3. ✅ **Validate** - Use Google Sheets formulas to validate emails
4. ✅ **Filter** - Use filters to manage large lists
5. ✅ **Update anytime** - Sheet updates automatically (no re-upload!)

### For Excel:
1. ✅ **Save as CSV** for best compatibility
2. ✅ **First column only** - Put emails in Column A
3. ✅ **Remove formatting** - Plain text works best
4. ✅ **Check encoding** - Use UTF-8 encoding

### For CSV:
1. ✅ **One email per line** - Keep it simple
2. ✅ **Skip header** - App auto-detects headers
3. ✅ **UTF-8 encoding** - Prevents special character issues
4. ✅ **No quotes** - Unless email contains commas

---

## 🔍 Troubleshooting

### Google Sheets Issues

**"Invalid Google Sheets URL"**
- ✅ Make sure link is from Google Sheets (contains `docs.google.com/spreadsheets`)
- ✅ Link must be shareable ("Anyone with link can view")
- ✅ Copy the full URL including `/d/...`

**"No emails found"**
- ✅ Emails must be in Column A (first column)
- ✅ Remove empty rows
- ✅ Check for hidden sheets (use Sheet1)

**"Permission denied"**
- ✅ Share settings must be "Anyone with link"
- ✅ Not "Restricted" or "Only people with access"

### Excel Issues

**"Could not extract emails"**
- ✅ Try saving as CSV instead
- ✅ Ensure emails are in Column A
- ✅ Remove all formatting
- ✅ Check file isn't password protected

**"Unsupported format"**
- ✅ Save as CSV UTF-8
- ✅ Don't use old .xls format (use .xlsx or CSV)

### CSV Issues

**"No valid emails found"**
- ✅ Check email format (must contain @)
- ✅ Remove header row if problematic
- ✅ One email per line
- ✅ Check file encoding (use UTF-8)

---

## 📊 Comparison

| Feature | Google Sheets | Excel | CSV |
|---------|---------------|-------|-----|
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **No Upload** | ✅ | ❌ | ❌ |
| **Real-time** | ✅ | ❌ | ❌ |
| **Collaborate** | ✅ | ✅ | ❌ |
| **Offline** | ❌ | ✅ | ✅ |
| **File Size** | Unlimited | 10MB | 10MB |
| **Best For** | Teams | Existing data | Simple lists |

---

## 🎯 Recommended Workflow

### For Regular Use:
```
1. Create a master Google Sheet
2. Share with your team
3. Everyone adds contacts
4. Use same sheet for all events
5. Just paste the link in app!
```

### For One-Time Use:
```
1. Create CSV file
2. Add emails
3. Upload to app
4. Done!
```

### For Existing Data:
```
1. Open Excel file
2. Save as CSV
3. Upload to app
OR
4. Copy to Google Sheets
5. Share link and use that
```

---

## ✅ Quick Start Examples

### Example 1: Quick Test
```csv
email
your-email@gmail.com
friend@example.com
```
Save as `test.csv` and upload!

### Example 2: Google Sheets
```
1. Go to: https://sheets.google.com/
2. Create new sheet
3. Add emails in Column A
4. Share → Anyone with link
5. Copy link
6. Paste in app
```

### Example 3: From Excel
```
1. Open Excel with contacts
2. File → Save As → CSV UTF-8
3. Upload in app
```

---

## 📧 Email Format Requirements

All methods require:
- ✅ Valid email format: `name@domain.com`
- ✅ First column (Column A)
- ✅ No special formatting
- ✅ Max 500 emails per batch

The app automatically:
- ✅ Validates emails
- ✅ Removes duplicates
- ✅ Skips headers
- ✅ Handles whitespace

---

## 🎉 Ready to Go!

You now have 3 flexible ways to import emails:

1. **Quick & Easy**: Google Sheets (Recommended!)
2. **Existing Data**: Excel files
3. **Simple Lists**: CSV files

Choose what works best for you! 🚀

---

## 📞 Need Help?

Check the app for:
- ✅ Built-in instructions
- ✅ Example formats
- ✅ Error messages with solutions
- ✅ Real-time validation

**Pro Tip**: Start with Google Sheets for the best experience! 📊


